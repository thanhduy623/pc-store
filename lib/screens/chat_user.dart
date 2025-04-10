import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_store/services/firebase/firestore_service.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({Key? key}) : super(key: key); // Thêm const cho constructor của StatefulWidget

  @override
  _UserChatScreenState createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final String id = FirebaseAuth.instance.currentUser!.uid;  // Lấy UID người dùng đã đăng nhập
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // Lắng nghe sự thay đổi trong Firestore để cập nhật tin nhắn mới
    FirebaseFirestore.instance
        .collection('messengers')
        .where('from', isEqualTo: id)
        .snapshots()
        .listen((snapshot) {
      _onNewMessage(snapshot);
    });

    FirebaseFirestore.instance
        .collection('messengers')
        .where('to', isEqualTo: id)
        .snapshots()
        .listen((snapshot) {
      _onNewMessage(snapshot);
    });

    _scrollController.addListener(() {
      // Kiểm tra nếu người dùng cuộn lên hay không
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        setState(() {
          _isAtBottom = true; // Nếu cuộn đến cuối thì đặt _isAtBottom = true
        });
      } else {
        setState(() {
          _isAtBottom = false; // Nếu không ở cuối, đặt _isAtBottom = false
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    final fromMessages = await _firestoreService.getDataWithLikeMatch("messengers", {"from": id});
    final toMessages = await _firestoreService.getDataWithLikeMatch("messengers", {"to": id});

    final all = [...fromMessages, ...toMessages];
    final unique = {
      for (var msg in all) msg['timestamp'].toString(): msg
    }.values.toList();

    unique.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

    setState(() {
      messages = unique.take(50).toList().reversed.toList(); // Đảo ngược để hiển thị từ cũ -> mới
    });

    // Cuộn xuống cuối khi tải xong tin nhắn
    _scrollToBottom();
  }

  // Hàm xử lý khi có tin nhắn mới
  void _onNewMessage(QuerySnapshot snapshot) {
    final newMessages = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    final allMessages = [...messages, ...newMessages];

    // Loại bỏ tin nhắn trùng lặp dựa trên timestamp
    final uniqueMessages = {
      for (var msg in allMessages) msg['timestamp'].toString(): msg
    }.values.toList();

    uniqueMessages.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

    setState(() {
      messages = uniqueMessages.take(50).toList().reversed.toList(); // Cập nhật lại tin nhắn và đảo ngược danh sách
    });

    // Cuộn xuống cuối khi có tin nhắn mới, nếu người dùng đang ở dưới cùng
    if (_isAtBottom) {
      _scrollToBottom();
    }
  }

  // Cuộn xuống cuối khi có tin nhắn mới
  void _scrollToBottom() {
    // Đảm bảo rằng cuộn chỉ xảy ra khi ListView có ít nhất một item
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent, // Cuộn đến cuối
        duration: Duration(milliseconds: 300), // Thời gian cuộn
        curve: Curves.easeOut, // Hiệu ứng cuộn
      );
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final message = {
      "from": id,
      "to": "Admin",  // Tin nhắn gửi tới Admin
      "text": _controller.text.trim(),
      "timestamp": DateTime.now().toIso8601String(),
    };

    setState(() {
      messages.add(message);
    });

    _controller.clear();
    FocusScope.of(context).requestFocus(_focusNode);

    _firestoreService.addWithAutoId("messengers", message);

    // Cuộn xuống cuối khi tin nhắn mới được gửi, nếu người dùng đang ở dưới cùng
    if (_isAtBottom) {
      _scrollToBottom();
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isMe = message['from'] == id;

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
        child: Text(
          message['text'] ?? '',
          style: TextStyle(color: Colors.black, fontSize: 16),
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
              controller: _scrollController, // Gán controller cho ListView
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessage(messages[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
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
