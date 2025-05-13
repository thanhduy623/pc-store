import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:my_store/utils/controllPicture.dart';
import 'package:my_store/controllers/addProductToCart.dart';
import 'package:my_store/utils/moneyFormat.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailScreen({super.key, required this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attributes =
        widget.productData['attributes'] as Map<String, dynamic>? ?? {};
    final productId = widget.productData['id'];
    final name = _safeToString(
      widget.productData['name'],
      fallback: 'Không có tên',
    );
    List<dynamic> images = [];
    if (widget.productData['image'] is List) {
      images = widget.productData['image'] as List<dynamic>;
    } else if (widget.productData['image'] != null) {
      images = [widget.productData['image']];
    }

    String? brand;
    if (widget.productData.containsKey('brand') &&
        widget.productData['brand'] != null) {
      brand = _safeToString(widget.productData['brand']);
    }

    final price = _safeToString(widget.productData['price'], fallback: '0');
    final description = _safeToString(
      widget.productData['description'],
      fallback: 'Chưa có mô tả cho sản phẩm này.',
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDesktop)
              _buildImageCarousel(images, height: 300, maxWidth: screenWidth),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      children: [
                        _buildImageCarousel(images, height: 300, maxWidth: 500),
                        if (images.length > 1) _buildImageIndicator(images),
                      ],
                    ),
                  ),
                if (isDesktop) const SizedBox(width: 16), // Giảm khoảng cách
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      //Mô tả
                      Text(
                        description,
                        style: TextStyle(height: 1.5, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 12),

                      //Giá
                      Text(
                        "Giá: ${moneyFormat(double.tryParse(price) ?? 0.0)}",
                        style: TextStyle(fontSize: 16, color: Colors.red[700]),
                      ),
                      const SizedBox(height: 16),

                      //Nút thêm vào giỏ hàng
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () => _addToCart(context),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text("Thêm vào giỏ hàng"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nhãn hàng
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          brand ?? 'No brand',
                          style: TextStyle(
                            height: 1.5,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
            if (isDesktop) ...[
              const SizedBox(height: 16),
              Text(
                "Thông số kỹ thuật",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(120),
                  1: FlexColumnWidth(),
                },
                border: TableBorder.all(color: Colors.grey[200]!),
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Thương hiệu',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          widget.productData['brand'] ?? 'Chưa có thông tin',
                        ),
                      ),
                    ],
                  ),
                  if (attributes.isNotEmpty)
                    ...attributes.entries.map((entry) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(_safeToString(entry.value)),
                          ),
                        ],
                      );
                    }),
                ],
              ),
              const Divider(height: 32),
              Text(
                "Đánh giá sản phẩm",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Row(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Các đánh giá hiện có:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...reviews.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['comment'] ?? ''),
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
                                if (data['userEmail'] != null)
                                  Text(
                                    'Bởi: ${data['userEmail']}',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
            if (!isDesktop) ...[
              const Divider(height: 32),
              Text(
                "Thông số kỹ thuật",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(120),
                  1: FlexColumnWidth(),
                },
                border: TableBorder.all(color: Colors.grey[200]!),
                children: [
                  // ... (phần thông số kỹ thuật cho mobile)
                ],
              ),
              const Divider(height: 32),
              // ... (phần đánh giá cho mobile)
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(
    List<dynamic> images, {
    required double height,
    required double maxWidth,
  }) {
    if (images.isEmpty) {
      return SizedBox(height: height, width: maxWidth);
    }
    return SizedBox(
      height: height,
      width: maxWidth,
      child: CarouselSlider(
        carouselController: _carouselController,
        options: CarouselOptions(
          height: height,
          viewportFraction: 1.0,
          autoPlay: images.length > 1,
          enlargeCenterPage: true,
          onPageChanged: (index, reason) {
            setState(() {
              _currentImageIndex = index;
            });
          },
        ),
        items:
            images.map((base64Image) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: maxWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: const BoxDecoration(color: Colors.grey),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.memory(
                        Base64ImageTool.base64ToImage(
                          _safeToString(base64Image),
                        ),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text('Không thể hiển thị ảnh'),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }

  Widget _buildImageIndicator(List<dynamic> images) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          images.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _carouselController.animateToPage(entry.key),
              child: Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentImageIndex == entry.key
                          ? Colors.blueAccent
                          : Colors.grey,
                ),
              ),
            );
          }).toList(),
    );
  }

  String _safeToString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is List) return value.map((e) => e.toString()).join(', ');
    return value.toString();
  }

  Future<void> _addToCart(BuildContext context) async {
    final String productId = widget.productData['id'].toString();
    final String name = widget.productData['name'];
    final double price = double.parse(widget.productData['price'].toString());
    final String image =
        (widget.productData['image'] is List)
            ? widget.productData['image'][0] ?? ''
            : widget.productData['image'] ?? '';

    await addProductToCart(context, productId, name, price, image);
  }

  Future<void> _submitComment(String productId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null ||
        _rating == 0 ||
        _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập và nhập đầy đủ thông tin'),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .add({
          'rating': _rating,
          'comment': _commentController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'userEmail': currentUser.email,
        });

    setState(() {
      _rating = 0;
      _commentController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá')));
  }
}
