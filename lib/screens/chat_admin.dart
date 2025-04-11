import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final List<Map<String, dynamic>> messages = [];
  final List<Map<String, dynamic>> usersList = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String idAdmin = "Admin";
  String? selectedUserId;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('messengers')
          .where('to', isEqualTo: idAdmin)
          .orderBy('timestamp', descending: true)
          .get();

      final usersSet = <String>{};
      for (var doc in snapshot.docs) {
        final fromUser = doc['from'];
        if (fromUser != idAdmin) usersSet.add(fromUser);
      }

      final users = await Future.wait(usersSet.map((userId) async {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final data = doc.data();
        return data != null ? {...data, 'id': userId} : null;
      })).then((list) => list.whereType<Map<String, dynamic>>().toList());

      setState(() {
        usersList.clear();
        usersList.addAll(users);
      });
    } catch (e) {
      print("Error loading users: $e");
    }
  }

  Future<void> _loadMessages(String userId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));
    final snapshot = await FirebaseFirestore.instance
        .collection('messengers')
        .where('timestamp', isGreaterThan: thirtyDaysAgo.toIso8601String())
        .where('from', whereIn: [userId, idAdmin])
        .where('to', whereIn: [userId, idAdmin])
        .orderBy('timestamp')
        .get();

    final loadedMessages = snapshot.docs.map((doc) {
      final data = doc.data();
      if (data['image'] != null) {
        data['type'] = 'image';
        data['data'] = base64Decode(data['image']);
      } else {
        data['type'] = 'text';
        data['data'] = data['text'] ?? '';
      }
      return data;
    }).toList();

    setState(() {
      messages.clear();
      messages.addAll(loadedMessages);
    });

    _scrollToBottom();
  }

  void _listenForNewMessages(String userId) {
    _messageSubscription?.cancel();

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));

    _messageSubscription = FirebaseFirestore.instance
        .collection('messengers')
        .where('timestamp', isGreaterThan: thirtyDaysAgo.toIso8601String())
        .where('from', whereIn: [userId, idAdmin])
        .where('to', whereIn: [userId, idAdmin])
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['image'] != null) {
          data['type'] = 'image';
          data['data'] = base64Decode(data['image']);
        } else {
          data['type'] = 'text';
          data['data'] = data['text'] ?? '';
        }
        return data;
      }).toList();

      setState(() {
        messages.clear();
        messages.addAll(newMessages);
      });

      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || selectedUserId == null) return;

    // Tạo message mới
    final message = {
      "from": idAdmin,
      "to": selectedUserId,
      "text": text,
      "timestamp": DateTime.now().toIso8601String()
    };

    // Gửi message vào Firestore mà không thay đổi danh sách tin nhắn trong setState
    await FirebaseFirestore.instance.collection('messengers').add(message);

    // Cập nhật trạng thái 'isReply' cho user
    await FirebaseFirestore.instance
        .collection('users')
        .doc(selectedUserId)
        .update({"isReply": true});

    _controller.clear();
    _scrollToBottom();

    // Không gọi lại _loadMessages() ở đây nữa vì tin nhắn đã được gửi, _listenForNewMessages đã lắng nghe.
    _loadUsers(); // Cập nhật trạng thái người dùng đã trả lời
  }

  void _onUserTap(String userId) {
    if (selectedUserId == userId) return;

    setState(() {
      selectedUserId = userId;
      messages.clear();
    });

    _loadMessages(userId);
    _listenForNewMessages(userId);
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
    final isMe = message['from'] == idAdmin;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? Colors.blue[100] : Colors.grey[300];
    final margin = isMe
        ? const EdgeInsets.only(left: 50, right: 8, top: 4, bottom: 4)
        : const EdgeInsets.only(right: 50, left: 8, top: 4, bottom: 4);

    final content = message['type'] == 'image'
        ? Image.memory(message['data'], width: 200, fit: BoxFit.cover)
        : Text(message['data']);

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
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Tin nhắn")),

      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey)),
            ),
            child: ListView.builder(
              itemCount: usersList.length,
              itemBuilder: (context, index) {
                final user = usersList[index];
                final userId = user['id'];
                final isUnread = user['isReply'] == false;

                return ListTile(
                  selected: userId == selectedUserId,
                  onTap: () => _onUserTap(userId),
                  leading: isUnread
                      ? const Icon(Icons.brightness_1, color: Colors.red, size: 12)
                      : const SizedBox(width: 12),
                  title: Text(user['name'] ?? 'Unknown'),
                );
              },
            ),
          ),

          // Chat panel
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
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
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
