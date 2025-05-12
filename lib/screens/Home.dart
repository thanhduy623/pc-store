import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_store/screens/product_detail_screen.dart';
import 'package:my_store/utils/controllPicture.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_store/screens/profile_screen.dart';
import 'package:my_store/screens/chat_user.dart';
import 'package:my_store/screens/CartPage.dart';
import 'package:my_store/screens/OrderListPage_User.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  User? _user = FirebaseAuth.instance.currentUser;
  final int _limit = 5;
  final ScrollController _scrollController = ScrollController();

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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadNewestProducts();
    await _loadCategoriesAndProducts();
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

  Widget _buildProductGrid(List<DocumentSnapshot> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        mainAxisExtent: 200.0, // Chiều cao card là 200px
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final doc = products[index];
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic>? imageList = data['image'];
        Uint8List? imageBytes;

        if (imageList != null &&
            imageList.isNotEmpty &&
            imageList[0] is String) {
          try {
            imageBytes = Base64ImageTool.base64ToImage(imageList[0]);
          } catch (e) {
            print(
              "❌ Lỗi giải mã ảnh ở HomeScreen (giống ProductManagement): $e",
            );
          }
        }

        Widget imageWidget;
        if (imageBytes != null) {
          imageWidget = Padding(
            padding: const EdgeInsets.all(8.0), // Giảm padding xuống 8.0
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(Icons.image),
            ),
          );
        } else {
          imageWidget = const Padding(
            padding: EdgeInsets.all(8.0), // Giảm padding xuống 8.0
            child: Icon(
              Icons.image,
              size: 36,
            ), // Tăng kích thước icon nếu không có ảnh
          );
        }

        return KeyedSubtree(
          // Sử dụng KeyedSubtree
          key: ValueKey(doc.id),
          child: Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ProductDetailScreen(
                          productData: {'id': doc.id, ...data},
                        ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 4, // Tăng flex cho phần hình ảnh
                    child: imageWidget,
                  ),
                  Expanded(
                    flex: 2, // Giữ nguyên hoặc giảm flex cho phần text
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            data['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${data['price'] ?? 0} đ',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              () {}, // Implement logic for sale products
            ),
            ..._categories.map((category) {
              final categoryId = category.id;
              return _buildSection(
                category['name'] as String,
                _categoryProducts[categoryId] ?? [],
                _isLoadingCategory[categoryId] ?? false,
                _hasMoreCategory[categoryId] ?? false,
                () => _loadProductsByCategory(categoryId, loadMore: true),
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const SizedBox(), // Trang chủ - sẽ được build ở body
    const ProfileScreen(),
    UserChatScreen(),
  ];

  Widget _buildCategoryDropdown() {
    // Phần này bạn có thể tùy chỉnh hoặc bỏ qua nếu không cần dropdown danh mục
    return const SizedBox.shrink();
  }

  Widget _buildFilterOptions() {
    // Phần này bạn có thể tùy chỉnh hoặc bỏ qua nếu không cần bộ lọc
    return const SizedBox.shrink();
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Tư vấn'),
        ],
      ),
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
