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
  List<Map<String, dynamic>> users = [];
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;
  String? currentUserId;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _listenForNewMessages();
  }

  Future<void> _loadUsers() async {
    try {
      final usersFromMessages = await _firestoreService.getDataWithLikeMatch("messengers", {"to": "Admin"});
      final uniqueUsers = {
        for (var msg in usersFromMessages) msg['from'].toString(): msg,
      }.values.toList();

      for (var user in uniqueUsers) {
        final userDetails = await _firestoreService.getDataById("users", user['from']);
        user['fullName'] = userDetails?['fullName'] ?? 'Unknown';
      }

      setState(() {
        users = uniqueUsers;
      });
    } catch (e) {
      print("Error loading users: $e");
    }
  }

  Future<void> _loadMessages(String userId) async {
    try {
      final fromMessages = await _firestoreService.getDataWithExactMatch("messengers", {"from": userId, "to": "Admin"});
      final toMessages = await _firestoreService.getDataWithExactMatch("messengers", {"from": "Admin", "to": userId});

      final allMessages = [...fromMessages, ...toMessages];

      final uniqueMessages = {
        for (var msg in allMessages) msg['timestamp'].toString(): msg,
      }.values.toList();

      uniqueMessages.sort((a, b) {
        final timestampA = a['timestamp'] ?? '';
        final timestampB = b['timestamp'] ?? '';
        return timestampB.compareTo(timestampA);
      });

      setState(() {
        messages = uniqueMessages.take(50).toList().reversed.toList();
        currentUserId = userId;
      });

      _scrollToBottom();
    } catch (e) {
      print("Error loading messages: $e");
    }
  }

  void _listenForNewMessages() {
    try {
      FirebaseFirestore.instance.collection('messengers').where('to', isEqualTo: adminId).snapshots().listen((snapshot) {
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
      "imageUrl": imageUrl ?? '',  // Ensure imageUrl is not null
      "timestamp": DateTime.now().toIso8601String(),
      "isRead": false,
    };

    setState(() {
      messages.add(message);
    });

    _controller.clear();
    FocusScope.of(context).requestFocus(_focusNode);

    try {
      await _firestoreService.addWithAutoId("messengers", message);
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
      final storageRef = FirebaseStorage.instance.ref().child('chat_images/${DateTime.now().toIso8601String()}.jpg');
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
            if (message['imageUrl'] != null && message['imageUrl'] != '')
              Image.network(
                message['imageUrl'],
                width: 150,
                height: 150,
                fit: BoxFit.cover,
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
          // User list with improved design, increased width, and background color matching the overall theme
          Container(
            width: 150, // Increased width to make the user list more spacious
            color: Colors.grey[100], // Set a background color for the user list
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                bool isSelected = currentUserId == user['from'];

                return GestureDetector(
                  onTap: () {
                    _loadMessages(user['from']);
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: isSelected ? Colors.blue : Colors.black),
                        SizedBox(width: 10),
                        Text(
                          user['fullName'] ?? 'Unknown',
                          style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Chat interface with the selected user
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(messages[index]);
                    },
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
                            hintText: 'Enter message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
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
