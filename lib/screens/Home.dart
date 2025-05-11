import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_store/screens/profile_screen.dart';
import 'package:my_store/screens/chat_user.dart';
import 'package:my_store/screens/CartPage.dart';
import 'package:my_store/screens/OrderListPage_User.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _selectedCategoryId;
  String? _selectedFilter;
  String? photoURL;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    photoURL = user?.photoURL;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const SizedBox(), // Trang chủ ở index 0 (sẽ xử lý riêng)
    const ProfileScreen(),
    UserChatScreen(),
  ];

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String title,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [Icon(icon), const SizedBox(width: 8), Text(title)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Người dùng';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundImage:
                  photoURL != null ? NetworkImage(photoURL!) : null,
              child: photoURL == null ? const Icon(Icons.person) : null,
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
                    MaterialPageRoute(builder: (_) => const OrderListPage()),
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
                  _buildMenuItem('orders', Icons.list_alt, 'Đơn hàng của tôi'),
                  _buildMenuItem('chat_user', Icons.chat, 'Tư vấn sản phẩm'),
                  _buildMenuItem('logout', Icons.logout, 'Đăng xuất'),
                ],
          ),
        ],
      ),
      body:
          _selectedIndex == 0
              ? Column(
                children: [
                  _buildCategoryDropdown(),
                  _buildFilterOptions(),
                  const SizedBox(height: 10),
                  Expanded(child: _buildProductList()),
                ],
              )
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

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final categories = snapshot.data!.docs;

          return DropdownButton<String>(
            isExpanded: true,
            hint: const Text("Chọn danh mục"),
            value: _selectedCategoryId,
            items: [
              const DropdownMenuItem(value: null, child: Text("Tất cả")),
              ...categories.map((doc) {
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(doc['name']),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _buildFilterChip('Mới nhất', 'newest'),
          _buildFilterChip('Khuyến mãi', 'sale'),
          _buildFilterChip('Bán chạy', 'popular'),
          _buildFilterChip('Giá ↑', 'price_asc'),
          _buildFilterChip('Giá ↓', 'price_desc'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = isSelected ? null : value;
        });
      },
    );
  }

  Widget _buildProductList() {
    Query query = FirebaseFirestore.instance.collection('products');

    if (_selectedCategoryId != null) {
      query = query.where('categoryId', isEqualTo: _selectedCategoryId);
    }

    switch (_selectedFilter) {
      case 'newest':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'sale':
        query = query.where('isSale', isEqualTo: true);
        break;
      case 'popular':
        query = query.orderBy('sold', descending: true);
        break;
      case 'price_asc':
        query = query.orderBy('price');
        break;
      case 'price_desc':
        query = query.orderBy('price', descending: true);
        break;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return const Center(child: Text('Không có sản phẩm nào.'));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final doc = products[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading:
                    data['imageUrl'] != null
                        ? Image.network(
                          data['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                        : const Icon(Icons.image),
                title: Text(data['name'] ?? ''),
                subtitle: Text("Giá: ${data['price'] ?? 0} đ"),
              ),
            );
          },
        );
      },
    );
  }
}
