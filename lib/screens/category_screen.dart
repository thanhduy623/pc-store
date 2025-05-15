import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _attributeController = TextEditingController();
  final FocusNode _attributeFocusNode = FocusNode();
  final List<String> _attributes = [];

  void _addAttribute() {
    final attr = _attributeController.text.trim();
    if (attr.isNotEmpty && !_attributes.contains(attr)) {
      setState(() {
        _attributes.add(attr);
      });
      _attributeController.clear();
      _attributeFocusNode.requestFocus();
    }
  }

  void _removeAttribute(String attr) {
    setState(() {
      _attributes.remove(attr);
    });
  }

  void _addCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty || _attributes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tên danh mục và thuộc tính không thể rỗng"),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('categories').add({
      'name': name,
      'attributes': _attributes,
    });

    _categoryController.clear();
    _attributeController.clear();
    setState(() {
      _attributes.clear();
    });
  }

  void _deleteCategory(String id) async {
    await FirebaseFirestore.instance.collection('categories').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý danh mục")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 600;

          if (isWideScreen) {
            // Màn hình rộng: 2 cột ngang
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildCategoryForm(),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildCategoryList(),
                  ),
                ),
              ],
            );
          } else {
            // Màn hình nhỏ: 1 cột, danh sách xuống dưới form
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildCategoryForm(),
                  const SizedBox(height: 24),
                  _buildCategoryList(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCategoryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Thêm danh mục mới",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: "Tên danh mục",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _attributeController,
          onSubmitted: (_) => _addAttribute(),
          focusNode: _attributeFocusNode,
          decoration: const InputDecoration(
            labelText: "RAM, ROM, CPU,...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _addAttribute,
          child: const Text("Thêm thuộc tính"),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _attributes
                  .map(
                    (attr) => Chip(
                      label: Text(attr),
                      onDeleted: () => _removeAttribute(attr),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(Icons.save),
            label: const Text("Lưu danh mục"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Chưa có danh mục nào."));
        }

        final categories = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final doc = categories[index];
            final name = doc['name'];
            final attributes = List<String>.from(doc['attributes'] ?? []);

            return ListTile(
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle:
                  attributes.isNotEmpty
                      ? Wrap(
                        spacing: 8,
                        children:
                            attributes
                                .map((attr) => Chip(label: Text(attr)))
                                .toList(),
                      )
                      : const Text("Không có thuộc tính"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCategory(doc.id),
              ),
            );
          },
        );
      },
    );
  }
}
