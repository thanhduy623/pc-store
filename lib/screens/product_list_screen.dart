import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_store/widgets/price_range_filter.dart';
import 'package:my_store/widgets/product_card.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool isAdmin = false;
  String? selectedCategory;
  String? selectedBrand;
  String sortBy = 'newest';
  bool isSaleOnly = false;
  double? minPrice;
  double? maxPrice;
  String searchQuery = '';
  bool isFilterApplied = false;

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

    // Apply filters when user clicks "Apply Filters"
    if (isFilterApplied) {
      if (selectedCategory != null) {
        query = query.where('categoryId', isEqualTo: selectedCategory);
      }
      if (selectedBrand != null) {
        query = query.where('brand', isEqualTo: selectedBrand);
      }
      if (isSaleOnly) {
        query = query.where('isSale', isEqualTo: true);
      }
      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }
      if (searchQuery.isNotEmpty) {
        query = query.where(
          'keywords',
          arrayContains: searchQuery.toLowerCase(),
        );
      }
      if (sortBy == 'newest') {
        query = query.orderBy('createdAt', descending: true);
      } else if (sortBy == 'priceLowToHigh') {
        query = query.orderBy('price', descending: false);
      } else if (sortBy == 'priceHighToLow') {
        query = query.orderBy('price', descending: true);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách sản phẩm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      isFilterApplied = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filters row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryDropdown(),
                      const SizedBox(width: 8),
                      _buildBrandDropdown(),
                      const SizedBox(width: 8),
                      PriceRangeFilter(
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        onMinPriceChanged: (value) {
                          setState(() {
                            minPrice = value;
                            isFilterApplied = true;
                          });
                        },
                        onMaxPriceChanged: (value) {
                          setState(() {
                            maxPrice = value;
                            isFilterApplied = true;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: sortBy,
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text('Mới nhất'),
                          ),
                          DropdownMenuItem(
                            value: 'nameAZ',
                            child: Text('Tên A-Z'),
                          ),
                          DropdownMenuItem(
                            value: 'nameZA',
                            child: Text('Tên Z-A'),
                          ),
                          DropdownMenuItem(
                            value: 'priceLowToHigh',
                            child: Text('Giá tăng dần'),
                          ),
                          DropdownMenuItem(
                            value: 'priceHighToLow',
                            child: Text('Giá giảm dần'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            sortBy = value!;
                            isFilterApplied = true;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: isSaleOnly,
                            onChanged: (value) {
                              setState(() {
                                isSaleOnly = value ?? false;
                                isFilterApplied = true;
                              });
                            },
                          ),
                          const Text("Khuyến mãi"),
                        ],
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedCategory = null;
                            selectedBrand = null;
                            sortBy = 'newest';
                            minPrice = null;
                            maxPrice = null;
                            searchQuery = '';
                            isSaleOnly = false;
                            isFilterApplied = true;
                          });
                        },
                        child: const Text('Đặt lại'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Product list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data!.docs;
                if (products.isEmpty) {
                  return const Center(child: Text('Chưa có sản phẩm nào.'));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Tính toán số cột dựa trên chiều rộng màn hình
                    final width = constraints.maxWidth;
                    int crossAxisCount;
                    if (width > 1200) {
                      crossAxisCount = 5; // Màn hình lớn
                    } else if (width > 900) {
                      crossAxisCount = 4; // Màn hình trung bình
                    } else if (width > 600) {
                      crossAxisCount = 3; // Màn hình nhỏ
                    } else {
                      crossAxisCount = 2; // Màn hình rất nhỏ
                    }

                    // Tính toán chiều cao tối ưu cho mỗi item
                    final itemWidth =
                        (width - (crossAxisCount + 1) * 8) / crossAxisCount;
                    final itemHeight =
                        itemWidth * 1.5; // Tỷ lệ 3:2 cho mỗi card

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        mainAxisExtent: itemHeight,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final doc = products[index];
                        final data = doc.data() as Map<String, dynamic>;

                        if (isAdmin) {
                          return Stack(
                            children: [
                              ProductCard(id: doc.id, data: data),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.8,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, size: 16),
                                        padding: EdgeInsets.zero,
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
                                    ),
                                    const SizedBox(width: 4),
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.8,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 16,
                                        ),
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _deleteProduct(doc.id),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return ProductCard(id: doc.id, data: data);
                      },
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
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Tất cả')),
            ...categories.map((doc) {
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(doc['name']),
              );
            }).toList(),
          ],
          onChanged: (String? value) {
            setState(() {
              if (value != selectedCategory) {
                selectedBrand = null;
              }
              selectedCategory = value;
              isFilterApplied = true;
            });
          },
        );
      },
    );
  }

  Widget _buildBrandDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('brands').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        // Get all brands
        final allBrands = snapshot.data!.docs;

        // Filter brands based on selected category
        final filteredBrands =
            selectedCategory != null
                ? allBrands
                    .where((doc) => doc['categoryId'] == selectedCategory)
                    .toList()
                : allBrands;

        // Check if current brand selection is still valid
        if (selectedBrand != null) {
          final isValidBrand = filteredBrands.any(
            (doc) => doc['name'] == selectedBrand,
          );
          if (!isValidBrand) {
            // Use Future.microtask to avoid setState during build
            Future.microtask(() {
              setState(() {
                selectedBrand = null;
                isFilterApplied = true;
              });
            });
          }
        }

        return DropdownButton<String>(
          hint: const Text("Chọn thương hiệu"),
          value: selectedBrand,
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Tất cả')),
            ...filteredBrands.map((doc) {
              final brandName = doc['name'] as String;
              return DropdownMenuItem<String>(
                value: brandName,
                child: Text(brandName),
              );
            }).toList(),
          ],
          onChanged: (String? value) {
            setState(() {
              selectedBrand = value;
              isFilterApplied = true;
            });
          },
        );
      },
    );
  }
}
