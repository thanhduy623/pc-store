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
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedBrand;
  List<String> base64Images = [];
  List<String> categoryAttributes = [];

  @override
  void initState() {
    super.initState();
    if (widget.productData != null) {
      _nameController.text = widget.productData!['name'] ?? '';
      _priceController.text = widget.productData!['price']?.toString() ?? '';
      _descriptionController.text = widget.productData!['description'] ?? '';
      _selectedCategoryId = widget.productData!['categoryId'];
      _selectedBrand = widget.productData!['brand'];
      if (widget.productData!['image'] != null) {
        base64Images = List<String>.from(widget.productData!['image']);
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
      'description': _descriptionController.text.trim(),
      'brand': _selectedBrand,
      'image': base64Images,
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

  Future<void> _fetchCategoryAttributes() async {
    if (_selectedCategoryId != null) {
      final categoryDoc =
          await FirebaseFirestore.instance
              .collection('categories')
              .doc(_selectedCategoryId)
              .get();
      setState(() {
        categoryAttributes = List<String>.from(categoryDoc['attributes'] ?? []);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
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
                  _buildBrandDropdown(),
                  const SizedBox(height: 10),
                  _buildDescriptionField(),
                  const SizedBox(height: 10),
                  if (_selectedCategoryId != null) ...[
                    _buildCategoryAttributes(),
                    const SizedBox(height: 10),
                  ],
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
              _fetchCategoryAttributes();
            });
          },
          validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
        );
      },
    );
  }

  Widget _buildBrandDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('brands')
              .where('categoryId', isEqualTo: _selectedCategoryId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final brands = snapshot.data!.docs;

        // Nếu brand hiện tại không còn trong danh sách, reset selection
        if (_selectedBrand != null &&
            !brands.any((doc) => doc['name'] == _selectedBrand)) {
          _selectedBrand = null;
        }

        return DropdownButtonFormField<String>(
          value: _selectedBrand,
          decoration: const InputDecoration(labelText: 'Thương hiệu'),
          items:
              brands.map((doc) {
                final brandName = doc['name'] as String;
                return DropdownMenuItem<String>(
                  value: brandName,
                  child: Text(brandName),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBrand = value;
            });
          },
          validator:
              (value) => value == null ? 'Vui lòng chọn thương hiệu' : null,
        );
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: const InputDecoration(
        labelText: 'Mô tả sản phẩm',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
      validator:
          (value) =>
              value == null || value.isEmpty
                  ? 'Vui lòng nhập mô tả sản phẩm'
                  : null,
    );
  }

  Widget _buildCategoryAttributes() {
    if (categoryAttributes.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Thuộc tính của danh mục:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...categoryAttributes.map((attr) {
          return TextFormField(decoration: InputDecoration(labelText: attr));
        }).toList(),
      ],
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
