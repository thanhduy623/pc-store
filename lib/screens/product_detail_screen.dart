import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailScreen({super.key, required this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final specs = widget.productData['specs'] ?? {};
    final productId = widget.productData['id'];
    final name = _safeToString(
      widget.productData['name'],
      fallback: 'Không có tên',
    );
    final image = _safeToString(widget.productData['image']);
    final description = _safeToString(widget.productData['description']);
    final price = _safeToString(widget.productData['price'], fallback: '0');
    final condition = _safeToString(
      widget.productData['condition'],
      fallback: 'unknown',
    );
    final stock = _safeToString(widget.productData['stock'], fallback: '0');

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image.isNotEmpty)
              Center(
                child: Image.network(image, height: 240, fit: BoxFit.contain),
              ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Giá: $price đ",
              style: TextStyle(fontSize: 18, color: Colors.red[700]),
            ),
            const SizedBox(height: 4),
            Text("Tình trạng: ${condition == 'new' ? 'Mới' : 'Cũ'}"),
            Text("Tồn kho: $stock"),
            const Divider(height: 32),
            Text(
              "Mô tả sản phẩm",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(description),
            const Divider(height: 32),
            Text(
              "Thông số kỹ thuật",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...specs.entries.map((entry) {
              final key = entry.key.toString();
              final displayValue = _safeToString(entry.value);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "• $key: ",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(child: Text(displayValue)),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _addToCart(context),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Thêm vào giỏ hàng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const Divider(height: 40),
            Text(
              "Đánh giá sản phẩm",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed:
                      FirebaseAuth.instance.currentUser != null
                          ? () => setState(() => _rating = index + 1)
                          : null,
                );
              }),
            ),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Nhập bình luận của bạn...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _submitComment(productId),
                child: const Text("Gửi"),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('products')
                      .doc(productId)
                      .collection('reviews')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = snapshot.data!.docs;
                return Column(
                  children:
                      reviews.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['comment'] ?? ''),
                          subtitle: Row(
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
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _safeToString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is List) return value.map((e) => e.toString()).join(', ');
    return value.toString();
  }

  Future<void> _addToCart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedItems = prefs.getStringList('localCart') ?? [];

    Map<String, dynamic> newItem = {
      'name': widget.productData['name'],
      'image': '',
      'price': widget.productData['price'] ?? 0,
      'quantity': 1,
      'selected': true,
    };

    bool itemExists = false;
    for (int i = 0; i < savedItems.length; i++) {
      Map<String, dynamic> item = jsonDecode(savedItems[i]);
      if (item['name'] == newItem['name']) {
        item['quantity'] += 1;
        savedItems[i] = jsonEncode(item);
        itemExists = true;
        break;
      }
    }

    if (!itemExists) {
      savedItems.add(jsonEncode(newItem));
    }

    await prefs.setStringList('localCart', savedItems);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng')));
  }

  Future<void> _submitComment(String productId) async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    if (productId == null || productId is! String || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: ID sản phẩm không hợp lệ')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    final Map<String, dynamic> data = {
      'comment': comment,
      'timestamp': Timestamp.now(),
      'rating': user != null ? _rating : 0,
    };

    if (user != null) {
      final uid = user.uid;
      final email = user.email;

      if (uid is String && uid.isNotEmpty) {
        data['userId'] = uid;
      }

      if (email is String && email.isNotEmpty) {
        data['userEmail'] = email;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .add(data);

      setState(() {
        _commentController.clear();
        _rating = 0;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bình luận đã được gửi')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi gửi bình luận: $e')));
    }
  }
}
