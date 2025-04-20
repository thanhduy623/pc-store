import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? productData;

  const ProductFormScreen({super.key, this.productId, this.productData});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.productData != null) {
      _nameController.text = widget.productData!['name'] ?? '';
      _priceController.text = widget.productData!['price']?.toString() ?? '';
      _imageUrlController.text = widget.productData!['imageUrl'] ?? '';
      _selectedCategoryId = widget.productData!['categoryId'];
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final productData = {
      'name': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'imageUrl': _imageUrlController.text.trim(),
      'categoryId': _selectedCategoryId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (widget.productId == null) {
      // Thêm mới
      productData['createdAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('products').add(productData);
    } else {
      // Cập nhật
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update(productData);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productId == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Nhập tên sản phẩm'
                            : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Nhập giá' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL hình ảnh (tuỳ chọn)',
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('categories')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();

                  final categories = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items:
                        categories.map((doc) {
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(doc['name']),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    validator:
                        (value) =>
                            value == null ? 'Vui lòng chọn danh mục' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: const Text('Lưu sản phẩm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
