import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:my_store/utils/controllPicture.dart';
import 'package:my_store/screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const ProductCard({Key? key, required this.id, required this.data})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? imageList = data['image'];
    Uint8List? imageBytes;

    if (imageList != null && imageList.isNotEmpty && imageList[0] is String) {
      try {
        imageBytes = Base64ImageTool.base64ToImage(imageList[0]);
      } catch (e) {
        print("❌ Lỗi giải mã ảnh: $e");
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ProductDetailScreen(productData: {'id': id, ...data}),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container with aspect ratio
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child:
                    imageBytes != null
                        ? Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.image)),
                        )
                        : const Center(child: Icon(Icons.image, size: 36)),
              ),
            ),
            // Product info container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand name
                    if (data['brand'] != null)
                      Text(
                        data['brand'].toString(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // Product name
                    Text(
                      data['name'] ?? 'Không có tên',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price and sale badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${data['price']?.toString() ?? '0'} đ",
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (data['isSale'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SALE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
