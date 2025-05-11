import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_store/utils/controllPicture.dart';

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

  String? _selectedCategoryId;
  List<String> base64Images = [];

  @override
  void initState() {
    super.initState();
    if (widget.productData != null) {
      _nameController.text = widget.productData!['name'] ?? '';
      _priceController.text = widget.productData!['price']?.toString() ?? '';
      _selectedCategoryId = widget.productData!['categoryId'];
      if (widget.productData!['iimage'] != null) {
        base64Images = List<String>.from(widget.productData!['iimage']);
      }
    }
  }

  Future<void> _pickAndAddImage() async {
    final imageBase64 = await Base64ImageTool.pickImageAndConvertToBase64();
    if (imageBase64 != null) {
      setState(() {
        base64Images.add(imageBase64);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      base64Images.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final productData = {
      'name': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'iimage': base64Images,
      'categoryId': _selectedCategoryId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (widget.productId == null) {
      productData['createdAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('products').add(productData);
    } else {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 600;

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
                  isWide
                      ? Row(
                        children: [
                          Expanded(child: _buildNameField()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildPriceField()),
                        ],
                      )
                      : Column(
                        children: [
                          _buildNameField(),
                          const SizedBox(height: 10),
                          _buildPriceField(),
                        ],
                      ),
                  const SizedBox(height: 10),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 10),
                  _buildImageSection(),
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
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
      validator:
          (value) =>
              value == null || value.isEmpty ? 'Nhập tên sản phẩm' : null,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Giá'),
      validator: (value) => value == null || value.isEmpty ? 'Nhập giá' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
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
          validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickAndAddImage,
          icon: const Icon(Icons.add_a_photo),
          label: const Text("Chọn ảnh"),
        ),
        const SizedBox(height: 10),
        if (base64Images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(base64Images.length, (index) {
              final imageBytes = Base64ImageTool.base64ToImage(
                base64Images[index],
              );
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imageBytes,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeImage(index),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }
}
