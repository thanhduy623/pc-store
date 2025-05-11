import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool isAdmin = false;
  String? selectedCategory;
  String sortBy = 'newest';
  bool isSaleOnly = false;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final role = snapshot.data()?['role'];
      setState(() {
        isAdmin = role == "Admin";
      });
    }
  }

  Future<void> _deleteProduct(String id) async {
    await FirebaseFirestore.instance.collection('products').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'products',
    );

    if (selectedCategory != null) {
      query = query.where('categoryId', isEqualTo: selectedCategory);
    }

    if (isSaleOnly) {
      query = query.where('isSale', isEqualTo: true);
    }

    if (sortBy == 'newest') {
      query = query.orderBy('createdAt', descending: true);
    } else if (sortBy == 'priceLowToHigh') {
      query = query.orderBy('price', descending: false);
    } else if (sortBy == 'priceHighToLow') {
      query = query.orderBy('price', descending: true);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách sản phẩm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: _buildCategoryDropdown()),
                const SizedBox(width: 8),
                _buildSortDropdown(),
                const SizedBox(width: 8),
                Checkbox(
                  value: isSaleOnly,
                  onChanged: (value) {
                    setState(() {
                      isSaleOnly = value ?? false;
                    });
                  },
                ),
                const Text("Khuyến mãi"),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final products = snapshot.data!.docs;

                if (products.isEmpty) {
                  return const Center(child: Text('Chưa có sản phẩm nào.'));
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data['name'] ?? ''),
                      subtitle: Text("Giá: ${data['price'] ?? 0} đ"),
                      trailing:
                          isAdmin
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
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
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteProduct(doc.id),
                                  ),
                                ],
                              )
                              : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          isAdmin
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductFormScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final categories = snapshot.data!.docs;
        return DropdownButton<String>(
          hint: const Text("Chọn danh mục"),
          value: selectedCategory,
          items:
              categories.map((doc) {
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(doc['name']),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCategory = value;
            });
          },
        );
      },
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      value: sortBy,
      items: const [
        DropdownMenuItem(value: 'newest', child: Text('Mới nhất')),
        DropdownMenuItem(value: 'priceLowToHigh', child: Text('Giá tăng')),
        DropdownMenuItem(value: 'priceHighToLow', child: Text('Giá giảm')),
      ],
      onChanged: (value) {
        setState(() {
          sortBy = value!;
        });
      },
    );
  }
}
