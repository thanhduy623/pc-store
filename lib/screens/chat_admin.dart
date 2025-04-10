import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_store/services/firebase/firestore_service.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({Key? key}) : super(key: key);

  @override
  _AdminChatScreenState createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final String adminId = FirebaseAuth.instance.currentUser!.uid;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> users = []; // Danh sách người dùng
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;
  String? currentUserId;

  // Để lưu trữ ảnh đã chọn
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _listenForNewMessages();
  }

  Future<void> _loadUsers() async {
    try {
      final usersFromMessages = await _firestoreService.getDataWithLikeMatch("messengers", {"to": adminId});

      final uniqueUsers = {
        for (var msg in usersFromMessages) msg['from'].toString(): msg,
      }.values.toList();

      setState(() {
        users = uniqueUsers;
      });
    } catch (e) {
      print("Error loading users: $e");
    }
  }

  Future<void> _loadMessages(String userId) async {
    try {
      final fromMessages = await _firestoreService.getDataWithLikeMatch("messengers", {"from": userId, "to": adminId});
      final toMessages = await _firestoreService.getDataWithLikeMatch("messengers", {"from": adminId, "to": userId});

      final all = [...fromMessages, ...toMessages];
      final unique = {
        for (var msg in all) msg['timestamp'].toString(): msg,
      }.values.toList();

      unique.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

      setState(() {
        messages = unique.take(50).toList().reversed.toList();
        currentUserId = userId;
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
          .where('to', isEqualTo: adminId)
          .snapshots()
          .listen((snapshot) {
        _onNewMessage(snapshot);
      });
    } catch (e) {
      print("Error listening for new messages: $e");
    }
  }

  void _onNewMessage(QuerySnapshot snapshot) {
    final newMessages = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    final allMessages = [...messages, ...newMessages];

    final uniqueMessages = {
      for (var msg in allMessages) msg['timestamp'].toString(): msg,
    }.values.toList();

    uniqueMessages.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

    setState(() {
      messages = uniqueMessages.take(50).toList().reversed.toList();
    });

    if (_isAtBottom) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty && _image == null) return;

    String? imageUrl;

    if (_image != null) {
      imageUrl = await _uploadImageToFirebase(_image!);
    }

    final message = {
      "from": adminId,
      "to": currentUserId,
      "text": _controller.text.trim(),
      "imageUrl": imageUrl,
      "timestamp": DateTime.now().toIso8601String(),
      "isRead": false, // Đánh dấu tin nhắn chưa đọc
    };

    setState(() {
      messages.add(message);
    });

    _controller.clear();
    FocusScope.of(context).requestFocus(_focusNode);

    try {
      _firestoreService.addWithAutoId("messengers", message);
      print("Message sent: $message");
    } catch (e) {
      print("Error sending message: $e");
    }

    if (_isAtBottom) {
      _scrollToBottom();
    }
  }

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images/${DateTime.now().toIso8601String()}.jpg');

      final uploadTask = storageRef.putFile(image);

      final taskSnapshot = await uploadTask;
      final imageUrl = await taskSnapshot.ref.getDownloadURL();

      print("Image URL: $imageUrl");
      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      } else {
        print("No image selected");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isMe = message['from'] == adminId;
    final isRead = message['isRead'] ?? false;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[200] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message['text'] != null)
              Text(
                message['text'] ?? '',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            if (message['imageUrl'] != null)
              Image.network(
                message['imageUrl'],
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            if (!isMe && !isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.circle,
                  size: 10,
                  color: Colors.red,
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
      appBar: AppBar(title: Text("Admin Chat")),
      body: Row(
        children: [
          // Danh sách người dùng đã nhắn tin
          Container(
            width: 100,
            color: Colors.grey[200],
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['from']),
                  onTap: () {
                    _loadMessages(user['from']);
                  },
                );
              },
            ),
          ),
          // Chat với người dùng
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) => _buildMessage(messages[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: _pickImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: "Enter message",
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
          ),
        ],
      ),
    );
  }
}
