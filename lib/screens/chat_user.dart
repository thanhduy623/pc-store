import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_store/services/firebase/firestore_service.dart';
import 'package:permission_handler/permission_handler.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({Key? key}) : super(key: key);

  @override
  _UserChatScreenState createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final String id = FirebaseAuth.instance.currentUser!.uid;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;

  File? _image;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenForNewMessages();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.photos.request();
    if (status.isGranted) {
      print("Permission granted");
    } else {
      print("Permission denied");
    }
  }

  Future<void> _loadMessages() async {
    try {
      final fromMessages = await _firestoreService.getDataWithLikeMatch("messengers", {"from": id});
      final toMessages = await _firestoreService.getDataWithLikeMatch("messengers", {"to": id});
      final all = [...fromMessages, ...toMessages];
      final unique = {
        for (var msg in all) msg['timestamp'].toString(): msg
      }.values.toList();
      unique.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));
      setState(() {
        messages = unique.take(50).toList().reversed.toList();
      });
      _scrollToBottom();
    } catch (e) {
      print("Error loading messages: $e");
    }
  }

  void _listenForNewMessages() {
    try {
      FirebaseFirestore.instance
          .collection('messengers')
          .where('from', isEqualTo: id)
          .snapshots()
          .listen(_onNewMessage);
      FirebaseFirestore.instance
          .collection('messengers')
          .where('to', isEqualTo: id)
          .snapshots()
          .listen(_onNewMessage);
    } catch (e) {
      print("Error listening for new messages: $e");
    }
  }

  void _onNewMessage(QuerySnapshot snapshot) {
    final newMessages = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    final allMessages = [...messages, ...newMessages];
    final uniqueMessages = {
      for (var msg in allMessages) msg['timestamp'].toString(): msg
    }.values.toList();
    uniqueMessages.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));
    setState(() {
      messages = uniqueMessages.take(50).toList().reversed.toList();
    });
    if (_isAtBottom) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        _webImage = await pickedFile.readAsBytes();
        // TODO: xử lý riêng nếu muốn hỗ trợ upload trên web
      } else {
        _image = File(pickedFile.path);
        await _sendMessage(); // <-- Gửi luôn ảnh sau khi chọn
      }
    } else {
      print('No image selected.');
    }
  }


  Future<String> _uploadImageToStorage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return '';
    }
  }

  Future<String> _uploadWebImageToStorage(Uint8List imageBytes) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}.png');
      final uploadTask = storageRef.putData(imageBytes);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading web image: $e");
      return '';
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _image == null) return;

    String? imageUrl;

    if (_image != null) {
      imageUrl = await _uploadImageToStorage(_image!);
    }

    final message = {
      "from": id,
      "to": "Admin",
      "text": text,
      "imageUrl": imageUrl,
      "timestamp": DateTime.now().toIso8601String(),
    };

    _firestoreService.updateData("users", id, {"isReply": false});

    try {
      await _firestoreService.addWithAutoId("messengers", message);
      setState(() {
        messages.add(message);
      });
    } catch (e) {
      print("Error sending message: $e");
    }

    _controller.clear();
    _image = null; // <-- reset image sau khi gửi

    if (_isAtBottom) {
      _scrollToBottom();
    }
  }


  Widget _buildMessage(Map<String, dynamic> message) {
    final isMe = message['from'] == id;
    final hasText = message['text'] != null && message['text'].isNotEmpty;
    final hasImage = message['imageUrl'] != null && message['imageUrl'].isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (hasText)
              Text(
                message['text'],
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            if (hasImage)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: Image.network(
                    message['imageUrl'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CHAT VỚI ADMIN")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessage(messages[index]),
            ),
          ),
          if (_image != null || _webImage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 250, maxHeight: 250),
                child: kIsWeb
                    ? Image.memory(_webImage!, fit: BoxFit.cover)
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: _getImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn vào đây",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
