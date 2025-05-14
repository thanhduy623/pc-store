import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class ProductReviews extends StatefulWidget {
  final String productId;
  final bool isDesktop;

  const ProductReviews({
    Key? key,
    required this.productId,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  WebSocketChannel? _channel;
  bool _isLoading = false;
  List<Map<String, dynamic>> _liveReviews = [];

  @override
  void initState() {
    super.initState();
    _setupWebSocket();
  }

  void _setupWebSocket() {
    // Giả định URL websocket - cần thay đổi thành URL thực tế của bạn
    try {
      _channel = IOWebSocketChannel.connect(
        'ws://your-websocket-server.com/reviews/${widget.productId}',
      );
      _channel!.stream.listen(
        (message) {
          final newReview = _parseReviewFromWebSocket(message);
          if (newReview != null) {
            setState(() {
              _liveReviews.add(newReview);
            });
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
        },
      );
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
    }
  }

  Map<String, dynamic>? _parseReviewFromWebSocket(dynamic message) {
    try {
      if (message is Map<String, dynamic>) {
        return message;
      } else if (message is String) {
        // Giả định message là JSON string
        return {'comment': message};
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          isUserLoggedIn ? "Đánh giá sản phẩm" : "Bình luận sản phẩm",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        if (isUserLoggedIn) _buildRatingInput(),
        if (isUserLoggedIn) const SizedBox(height: 8),
        _buildCommentInput(isUserLoggedIn),
        const SizedBox(height: 8),
        _buildSubmitButton(isUserLoggedIn),
        const SizedBox(height: 16),
        _buildReviewsList(),
      ],
    );
  }

  Widget _buildRatingInput() {
    return Row(
      children: [
        const Text("Đánh giá: ", style: TextStyle(fontWeight: FontWeight.w500)),
        ...List.generate(5, (index) {
          return IconButton(
            icon: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: widget.isDesktop ? 24 : 20,
            ),
            onPressed: () => setState(() => _rating = index + 1),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          );
        }),
      ],
    );
  }

  Widget _buildCommentInput(bool isUserLoggedIn) {
    return TextField(
      controller: _commentController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText:
            isUserLoggedIn
                ? "Nhập bình luận và đánh giá của bạn..."
                : "Nhập bình luận của bạn (bạn cần đăng nhập để đánh giá sao)...",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildSubmitButton(bool isUserLoggedIn) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _submitReview(isUserLoggedIn),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text(isUserLoggedIn ? "Gửi đánh giá" : "Gửi bình luận"),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productId)
              .collection('reviews')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Widget> reviewWidgets = [];

        // Hiển thị các đánh giá realtime từ WebSocket (nếu có)
        for (var liveReview in _liveReviews) {
          reviewWidgets.add(_buildReviewCard(liveReview, isLive: true));
        }

        // Hiển thị các đánh giá từ Firestore
        if (snapshot.hasData && snapshot.data != null) {
          final reviews = snapshot.data!.docs;
          if (reviews.isNotEmpty) {
            for (var doc in reviews) {
              final data = doc.data() as Map<String, dynamic>;
              reviewWidgets.add(_buildReviewCard(data));
            }
          }
        }

        if (reviewWidgets.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Chưa có đánh giá nào cho sản phẩm này.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Các đánh giá (${reviewWidgets.length}):",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...reviewWidgets,
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data, {bool isLive = false}) {
    final bool hasRating =
        data['isRated'] == true ||
        (data['rating'] != null && data['rating'] > 0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isLive ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side:
            isLive
                ? BorderSide(color: Colors.blue.shade300, width: 1)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['userEmail'] ?? 'Khách',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Mới",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasRating) ...[
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < (data['rating'] ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              data['comment'] ?? '',
              style: TextStyle(height: 1.3, color: Colors.grey[800]),
            ),
            const SizedBox(height: 4),
            if (data['timestamp'] != null)
              Text(
                _formatTimestamp(data['timestamp']),
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      if (timestamp is Timestamp) {
        final DateTime dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> _submitReview(bool isUserLoggedIn) async {
    final comment = _commentController.text.trim();

    // Kiểm tra xem có nhập bình luận hay không
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập bình luận của bạn'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Nếu đã đăng nhập nhưng chưa chọn sao, yêu cầu chọn sao
    if (isUserLoggedIn && _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao để đánh giá'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Xác định người dùng hiện tại hoặc tạo thông tin ẩn danh
      User? currentUser = FirebaseAuth.instance.currentUser;
      String userEmail = 'Khách';
      String userId = 'anonymous';

      if (currentUser != null) {
        userEmail = currentUser.email ?? 'Người dùng đã đăng nhập';
        userId = currentUser.uid;
      }

      // Tạo dữ liệu đánh giá/bình luận
      final reviewData = {
        'rating':
            isUserLoggedIn ? _rating : 0, // Chỉ lưu rating nếu đã đăng nhập
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': userEmail,
        'userId': userId,
        'isRated':
            isUserLoggedIn &&
            _rating > 0, // Đánh dấu xem có đánh giá sao hay không
      };

      // Lưu đánh giá vào Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .add(reviewData);

      // Gửi đánh giá qua WebSocket nếu có kết nối
      if (_channel != null) {
        try {
          _channel!.sink.add({
            'productId': widget.productId,
            'rating': isUserLoggedIn ? _rating : 0,
            'comment': comment,
            'userEmail': userEmail,
            'timestamp': DateTime.now().toIso8601String(),
            'isRated': isUserLoggedIn && _rating > 0,
          });
        } catch (e) {
          debugPrint('Error sending to WebSocket: $e');
        }
      }

      // Cập nhật rating trung bình cho sản phẩm (chỉ nếu có đánh giá sao)
      if (isUserLoggedIn && _rating > 0) {
        await _updateProductAverageRating(widget.productId);
      }

      // Reset form
      setState(() {
        if (isUserLoggedIn) _rating = 0;
        _commentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUserLoggedIn
                ? 'Cảm ơn bạn đã đánh giá sản phẩm!'
                : 'Cảm ơn bạn đã bình luận!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProductAverageRating(String productId) async {
    try {
      // Lấy tất cả đánh giá có sao cho sản phẩm
      final reviews =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .collection('reviews')
              .where('isRated', isEqualTo: true)
              .get();

      if (reviews.docs.isEmpty) return;

      // Tính rating trung bình (chỉ cho các đánh giá có sao)
      double totalRating = 0;
      for (var doc in reviews.docs) {
        final data = doc.data();
        totalRating += (data['rating'] ?? 0).toDouble();
      }

      final averageRating = totalRating / reviews.docs.length;

      // Cập nhật rating trung bình vào document sản phẩm
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
            'averageRating': averageRating,
            'totalReviews': reviews.docs.length,
          });
    } catch (e) {
      debugPrint('Error updating average rating: $e');
    }
  }
}
