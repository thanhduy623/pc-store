import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String idUser = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    Uint8List bytes = await pickedFile.readAsBytes();
    String base64String = base64Encode(bytes);

    final message = {
      "from": idUser,
      "to": "Admin",
      "timestamp": DateTime.now().toIso8601String(),
      "image": base64String,
    };

    await FirebaseFirestore.instance.collection('messengers').add(message);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = {
      "from": idUser,
      "to": "Admin",
      "text": text,
      "timestamp": DateTime.now().toIso8601String()
    };

    await FirebaseFirestore.instance.collection('messengers').add(message);
    _controller.clear();

    FirebaseFirestore.instance
        .collection('users')
        .doc(idUser)
        .update({"isReply": false});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isMe = message['from'] == idUser;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? Colors.blue[100] : Colors.grey[300];
    final margin = isMe
        ? const EdgeInsets.only(left: 50, right: 8, top: 4, bottom: 4)
        : const EdgeInsets.only(right: 50, left: 8, top: 4, bottom: 4);

    Widget content;
    if (message['type'] == 'image') {
      content = Image.memory(
        message['data'],
        width: 200,
        fit: BoxFit.cover,
      );
    } else {
      content = Text(message['data']);
    }

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: margin,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: content,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TƯ VẤN SẢN PHẨM")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messengers')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final List<Map<String, dynamic>> liveMessages = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (!((data['from'] == idUser && data['to'] == 'Admin') ||
                      (data['from'] == 'Admin' && data['to'] == idUser))) {
                    return null;
                  }

                  if (data.containsKey('image')) {
                    return {
                      'from': data['from'],
                      'type': 'image',
                      'data': base64Decode(data['image']),
                      'timestamp': data['timestamp']
                    };
                  } else {
                    return {
                      'from': data['from'],
                      'type': 'text',
                      'data': data['text'] ?? '',
                      'timestamp': data['timestamp']
                    };
                  }
                }).whereType<Map<String, dynamic>>().toList();

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: liveMessages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(liveMessages[index]);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _getImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
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
