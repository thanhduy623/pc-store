import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_form_screen.dart';
import 'package:my_store/utils/moneyFormat.dart';
import 'package:my_store/utils/controllPicture.dart';
import 'dart:typed_data';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý sản phẩm"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm sản phẩm',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final query = FirebaseFirestore.instance.collection('products');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery);
            }).toList();

        if (products.isEmpty) {
          return const Center(child: Text('Không tìm thấy sản phẩm.'));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final doc = products[index];
            final data = doc.data() as Map<String, dynamic>;

            final List<dynamic>? imageList =
                data['image']; // Lưu ý: field 'image' (not 'images')
            Uint8List? imageBytes;

            if (imageList != null &&
                imageList.isNotEmpty &&
                imageList[0] is String) {
              try {
                imageBytes = Base64ImageTool.base64ToImage(imageList[0]);
              } catch (e) {
                print("❌ Lỗi giải mã ảnh: $e");
              }
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading:
                    imageBytes != null
                        ? Image.memory(
                          imageBytes,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                        : const Icon(Icons.image, size: 100),
                title: Text(data['name'] ?? 'Không tên'),
                subtitle: Text(
                  "Giá: ${moneyFormat(data['price']?.toDouble() ?? 0)}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ProductFormScreen(
                                  productId: doc.id,
                                  productData: data,
                                ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text("Xác nhận xoá"),
                                content: const Text(
                                  "Bạn có chắc muốn xoá sản phẩm này?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text("Huỷ"),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text("Xoá"),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('products')
                              .doc(doc.id)
                              .delete();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
