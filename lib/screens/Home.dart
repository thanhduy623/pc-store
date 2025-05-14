import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_store/screens/profile_screen.dart';
import 'package:my_store/screens/chat_user.dart';
import 'package:my_store/screens/CartPage.dart';
import 'package:my_store/screens/OrderListPage_User.dart';
import 'package:my_store/widgets/price_range_filter.dart';
import 'package:my_store/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  User? _user = FirebaseAuth.instance.currentUser;
  final int _limit = 5;

  // Sorting and filtering state
  String _sortBy =
      'newest'; // newest, nameAZ, nameZA, priceLowHigh, priceHighLow
  String? _selectedBrand;
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;

  // Newest Products
  List<DocumentSnapshot> _newestProducts = [];
  DocumentSnapshot? _newestLastDoc;
  bool _isLoadingNewest = false;
  bool _hasMoreNewest = true;

  // Sale Products (tạm thời rỗng)
  List<DocumentSnapshot> _saleProducts = [];
  bool _isLoadingSale = false;
  bool _hasMoreSale = false; // Tạm thời không có logic load thêm

  List<DocumentSnapshot> _categories = [];
  Map<String, List<DocumentSnapshot>> _categoryProducts = {};
  Map<String, DocumentSnapshot?> _categoryLastDocs = {};
  Map<String, bool> _isLoadingCategory = {};
  Map<String, bool> _hasMoreCategory = {};
  List<DocumentSnapshot> _productDocs = []; // Tạm thời

  String _searchQuery = '';

  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadNewestProducts();
    await _loadCategoriesAndProducts();
    await _loadSaleProducts();
    // Tạm thời gán _newestProducts cho _productDocs để hiển thị
    _productDocs = _newestProducts;
    setState(() {});
  }

  Future<void> _loadNewestProducts({bool loadMore = false}) async {
    if (_isLoadingNewest) return;
    setState(() => _isLoadingNewest = true);
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(_limit);
    if (loadMore && _newestLastDoc != null) {
      query = query.startAfterDocument(_newestLastDoc!);
    }
    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        if (loadMore) {
          _newestProducts.addAll(snapshot.docs);
        } else {
          _newestProducts = snapshot.docs;
        }
        _newestLastDoc = snapshot.docs.last;
        _hasMoreNewest = snapshot.docs.length == _limit;
        // Cập nhật _productDocs khi tải sản phẩm mới
        if (_selectedIndex == 0) {
          _productDocs = _newestProducts;
        }
      });
    } else {
      _hasMoreNewest = false;
    }
    setState(() => _isLoadingNewest = false);
  }

  Future<void> _loadCategoriesAndProducts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    _categories = snapshot.docs;
    for (final category in _categories) {
      final categoryId = category.id;
      _categoryProducts[categoryId] = [];
      _categoryLastDocs[categoryId] = null;
      _isLoadingCategory[categoryId] = false;
      _hasMoreCategory[categoryId] = true;
      _loadProductsByCategory(categoryId);
    }
    setState(() {}); // Rebuild sau khi lấy danh mục
  }

  Future<void> _loadProductsByCategory(
    String categoryId, {
    bool loadMore = false,
  }) async {
    if (_isLoadingCategory[categoryId] == true) return;
    setState(() => _isLoadingCategory[categoryId] = true);
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .limit(_limit);
    if (loadMore && _categoryLastDocs[categoryId] != null) {
      query = query.startAfterDocument(_categoryLastDocs[categoryId]!);
    }
    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        if (loadMore) {
          _categoryProducts[categoryId]!.addAll(snapshot.docs);
        } else {
          _categoryProducts[categoryId] = snapshot.docs;
        }
        _categoryLastDocs[categoryId] = snapshot.docs.last;
        _hasMoreCategory[categoryId] = snapshot.docs.length == _limit;
      });
    } else {
      _hasMoreCategory[categoryId] = false;
    }
    setState(() => _isLoadingCategory[categoryId] = false);
  }

  Future<void> _loadSaleProducts({bool loadMore = false}) async {
    if (_isLoadingSale) return;
    setState(() => _isLoadingSale = true);

    try {
      // 1. Lấy các mã giảm giá loại "Mặt hàng"
      final now = Timestamp.now();
      final discountSnapshot =
          await FirebaseFirestore.instance
              .collection('discounts')
              .where('type', isEqualTo: 'Mặt hàng')
              .get();

      // 2. Lọc các mã giảm giá và lấy product IDs
      final Set<String> discountedProductIds = {};
      for (var doc in discountSnapshot.docs) {
        final data = doc.data();

        if (!data.containsKey('startDate') || !data.containsKey('endDate')) {
          continue;
        }

        final startDate = data['startDate'] as Timestamp;
        final endDate = data['endDate'] as Timestamp;

        // Kiểm tra xem mã giảm giá còn hiệu lực không
        if (startDate.compareTo(now) <= 0 && endDate.compareTo(now) >= 0) {
          if (data.containsKey('productId')) {
            final productId = data['productId'] as String;
            discountedProductIds.add(productId);
          }
        }
      }

      if (discountedProductIds.isEmpty) {
        setState(() {
          _saleProducts = [];
          _hasMoreSale = false;
          _isLoadingSale = false;
        });
        return;
      }

      // 3. Lấy thông tin các sản phẩm được giảm giá
      final List<String> productIdsList = discountedProductIds.toList();
      final List<DocumentSnapshot> allProducts = [];

      for (var i = 0; i < productIdsList.length; i += 10) {
        final end =
            (i + 10 < productIdsList.length) ? i + 10 : productIdsList.length;
        final batch = productIdsList.sublist(i, end);

        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('products')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        allProducts.addAll(querySnapshot.docs);
      }

      setState(() {
        if (loadMore) {
          _saleProducts.addAll(allProducts);
        } else {
          _saleProducts = allProducts;
        }
        _hasMoreSale = false;
      });
    } catch (e) {
      print('❌ Lỗi khi tải sản phẩm giảm giá: $e');
    } finally {
      setState(() => _isLoadingSale = false);
    }
  }

  Widget _buildProductGrid(List<DocumentSnapshot> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tính toán số cột dựa trên chiều rộng màn hình
        final width = constraints.maxWidth;
        int crossAxisCount;
        double padding;
        double spacing;

        if (width > 1200) {
          crossAxisCount = 5; // Màn hình lớn
          padding = 16.0;
          spacing = 16.0;
        } else if (width > 900) {
          crossAxisCount = 4; // Màn hình trung bình
          padding = 12.0;
          spacing = 12.0;
        } else if (width > 600) {
          crossAxisCount = 3; // Màn hình nhỏ
          padding = 8.0;
          spacing = 8.0;
        } else {
          crossAxisCount = 2; // Màn hình rất nhỏ
          padding = 4.0;
          spacing = 4.0;
        }

        // Tính toán chiều cao tối ưu cho mỗi item
        final availableWidth =
            width - (padding * 2) - (spacing * (crossAxisCount - 1));
        final itemWidth = availableWidth / crossAxisCount;
        final itemHeight = itemWidth * 1.5; // Tỷ lệ 3:2 cho mỗi card

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: itemHeight,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final doc = products[index];
            return ProductCard(
              id: doc.id,
              data: doc.data() as Map<String, dynamic>,
            );
          },
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    List<DocumentSnapshot> products,
    bool isLoading,
    bool hasMore,
    VoidCallback onLoadMore,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(), // In hoa tiêu đề
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey[800], // Màu sắc tùy chỉnh
                ),
              ),
            ],
          ),
        ),
        _buildProductGrid(products),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasMore && products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: onLoadMore,
                child: const Text('Xem thêm'),
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProductListView(List<DocumentSnapshot> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final horizontalPadding =
            screenWidth > 1200
                ? screenWidth * 0.1
                : screenWidth > 600
                ? screenWidth * 0.05
                : 8.0;

        // Kiểm tra xem có bất kỳ bộ lọc nào được áp dụng không
        bool hasActiveFilters =
            _searchQuery.isNotEmpty ||
            _minPrice != null ||
            _maxPrice != null ||
            _sortBy != 'newest';

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters section
                Padding(
                  padding: EdgeInsets.all(screenWidth > 600 ? 16.0 : 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categories row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('categories')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const CircularProgressIndicator();

                            return Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: screenWidth > 600 ? 8.0 : 4.0,
                                  ),
                                  child: FilterChip(
                                    label: const Text('Tất cả'),
                                    selected: _selectedCategory == null,
                                    onSelected: (bool selected) {
                                      setState(() {
                                        _selectedCategory = null;
                                        _selectedBrand = null;
                                        _applySortingAndFiltering();
                                      });
                                    },
                                  ),
                                ),
                                ...snapshot.data!.docs.map((doc) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: screenWidth > 600 ? 8.0 : 4.0,
                                    ),
                                    child: FilterChip(
                                      label: Text(doc['name'] as String),
                                      selected: _selectedCategory == doc.id,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          _selectedCategory =
                                              selected ? doc.id : null;
                                          _selectedBrand = null;
                                          _applySortingAndFiltering();
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: screenWidth > 600 ? 16.0 : 8.0),

                      // Brands row
                      if (_selectedCategory != null)
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('products')
                                  .where(
                                    'categoryId',
                                    isEqualTo: _selectedCategory,
                                  )
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const CircularProgressIndicator();

                            // Get unique brands
                            final brands =
                                snapshot.data!.docs
                                    .map(
                                      (doc) =>
                                          (doc.data()
                                                  as Map<
                                                    String,
                                                    dynamic
                                                  >)['brand']
                                              as String,
                                    )
                                    .where(
                                      (brand) =>
                                          brand != null && brand.isNotEmpty,
                                    )
                                    .toSet()
                                    .toList()
                                  ..sort();

                            if (brands.isEmpty) return const SizedBox.shrink();

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: screenWidth > 600 ? 8.0 : 4.0,
                                    ),
                                    child: FilterChip(
                                      label: const Text('Tất cả thương hiệu'),
                                      selected: _selectedBrand == null,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          _selectedBrand = null;
                                          _applySortingAndFiltering();
                                        });
                                      },
                                    ),
                                  ),
                                  ...brands.map((brand) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: screenWidth > 600 ? 8.0 : 4.0,
                                      ),
                                      child: FilterChip(
                                        label: Text(brand),
                                        selected: _selectedBrand == brand,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            _selectedBrand =
                                                selected ? brand : null;
                                            _applySortingAndFiltering();
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                      SizedBox(height: screenWidth > 600 ? 16.0 : 8.0),

                      // Search and sort row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm sản phẩm...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                  _applySortingAndFiltering();
                                });
                              },
                            ),
                          ),
                          SizedBox(width: screenWidth > 600 ? 16.0 : 8.0),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _sortBy,
                                isDense: true,
                                borderRadius: BorderRadius.circular(8),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                ),
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
                                    value: 'priceLowHigh',
                                    child: Text('Giá tăng dần'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'priceHighLow',
                                    child: Text('Giá giảm dần'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _sortBy = value!;
                                    _applySortingAndFiltering();
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth > 600 ? 16.0 : 8.0),
                          PriceRangeFilter(
                            minPrice: _minPrice,
                            maxPrice: _maxPrice,
                            onMinPriceChanged: (value) {
                              setState(() {
                                _minPrice = value;
                                _applySortingAndFiltering();
                              });
                            },
                            onMaxPriceChanged: (value) {
                              setState(() {
                                _maxPrice = value;
                                _applySortingAndFiltering();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Products display
                if (_selectedCategory != null)
                  // Hiển thị sản phẩm của danh mục đã chọn
                  _buildSection(
                    'Kết quả tìm kiếm',
                    _productDocs,
                    false,
                    false,
                    () {},
                  )
                else if (hasActiveFilters)
                  // Hiển thị tất cả sản phẩm đã lọc khi ở chế độ "Tất cả"
                  _buildSection(
                    'Kết quả tìm kiếm',
                    _productDocs,
                    false,
                    false,
                    () {},
                  )
                else
                  // Hiển thị theo sections khi không có bộ lọc nào được áp dụng
                  Column(
                    children: [
                      _buildSection(
                        'Sản phẩm mới',
                        _newestProducts,
                        _isLoadingNewest,
                        _hasMoreNewest,
                        () => _loadNewestProducts(loadMore: true),
                      ),
                      _buildSection(
                        'Sản phẩm giảm giá',
                        _saleProducts,
                        _isLoadingSale,
                        _hasMoreSale,
                        () => _loadSaleProducts(loadMore: true),
                      ),
                      ..._categories.map((category) {
                        final categoryId = category.id;
                        return _buildSection(
                          category['name'] as String,
                          _categoryProducts[categoryId] ?? [],
                          _isLoadingCategory[categoryId] ?? false,
                          _hasMoreCategory[categoryId] ?? false,
                          () => _loadProductsByCategory(
                            categoryId,
                            loadMore: true,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  final List<Widget> _screens = [
    const SizedBox(),
    const ProfileScreen(),
    UserChatScreen(),
  ];

  void _applySortingAndFiltering() {
    // Lấy tất cả sản phẩm từ mọi nguồn
    List<DocumentSnapshot> allProducts = [];

    // Luôn gộp tất cả sản phẩm từ mọi nguồn
    allProducts.addAll(_newestProducts);
    _categoryProducts.forEach((_, products) {
      allProducts.addAll(products);
    });
    allProducts.addAll(_saleProducts);

    // Loại bỏ các sản phẩm trùng lặp dựa trên ID
    final uniqueProducts = <String, DocumentSnapshot>{};
    for (var doc in allProducts) {
      uniqueProducts[doc.id] = doc;
    }
    List<DocumentSnapshot> filteredProducts = uniqueProducts.values.toList();

    // Áp dụng bộ lọc danh mục nếu được chọn
    if (_selectedCategory != null) {
      filteredProducts =
          filteredProducts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['categoryId'] == _selectedCategory;
          }).toList();
    }

    // Áp dụng bộ lọc thương hiệu nếu được chọn
    if (_selectedBrand != null) {
      filteredProducts =
          filteredProducts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['brand'] == _selectedBrand;
          }).toList();
    }

    // Áp dụng bộ lọc khoảng giá
    if (_minPrice != null || _maxPrice != null) {
      filteredProducts =
          filteredProducts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final price = data['price'] as num;
            bool meetsMinPrice = _minPrice == null || price >= _minPrice!;
            bool meetsMaxPrice = _maxPrice == null || price <= _maxPrice!;
            return meetsMinPrice && meetsMaxPrice;
          }).toList();
    }

    // Áp dụng tìm kiếm
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredProducts =
          filteredProducts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] as String).toLowerCase();
            final brand = (data['brand'] as String?)?.toLowerCase() ?? '';
            final description =
                (data['description'] as String?)?.toLowerCase() ?? '';
            return name.contains(query) ||
                brand.contains(query) ||
                description.contains(query);
          }).toList();
    }

    // Áp dụng sắp xếp
    filteredProducts.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      switch (_sortBy) {
        case 'nameAZ':
          return (aData['name'] as String).compareTo(bData['name'] as String);
        case 'nameZA':
          return (bData['name'] as String).compareTo(aData['name'] as String);
        case 'priceLowHigh':
          return (aData['price'] as num).compareTo(bData['price'] as num);
        case 'priceHighLow':
          return (bData['price'] as num).compareTo(aData['price'] as num);
        case 'newest':
        default:
          final aDate = aData['createdAt'] as Timestamp;
          final bDate = bData['createdAt'] as Timestamp;
          return bDate.compareTo(aDate);
      }
    });

    setState(() {
      _productDocs = filteredProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          _user != null
              ? PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundImage:
                      _user?.photoURL != null
                          ? NetworkImage(_user!.photoURL!)
                          : null,
                  child:
                      _user?.photoURL == null ? const Icon(Icons.person) : null,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                      break;
                    case 'cart':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                      break;
                    case 'orders':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderListPage(),
                        ),
                      );
                      break;
                    case 'chat_user':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserChatScreen()),
                      );
                      break;
                    case 'logout':
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      _buildMenuItem('profile', Icons.person, 'Hồ sơ cá nhân'),
                      _buildMenuItem(
                        'cart',
                        Icons.shopping_cart,
                        'Giỏ hàng của tôi',
                      ),
                      _buildMenuItem(
                        'orders',
                        Icons.list_alt,
                        'Đơn hàng của tôi',
                      ),
                      _buildMenuItem(
                        'chat_user',
                        Icons.chat,
                        'Tư vấn sản phẩm',
                      ),
                      _buildMenuItem('logout', Icons.logout, 'Đăng xuất'),
                    ],
              )
              : IconButton(
                icon: const Icon(Icons.login),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
        ],
      ),
      body:
          _selectedIndex == 0
              ? _buildProductListView(_productDocs)
              : _screens[_selectedIndex],
    );
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
