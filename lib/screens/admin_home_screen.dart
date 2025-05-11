import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_screen.dart';
import 'chat_admin.dart';
import 'profile_screen.dart';
import 'product_form_screen.dart';
import 'package:my_store/screens/ManageProduct.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  String? _selectedCategoryId;
  String? _selectedFilter;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const SizedBox(),
    const ProfileScreen(),
    const AdminChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Admin';
    final photoURL = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
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
                case 'manage_categories':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryScreen()),
                  );
                  break;
                case 'manage_products':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductManagementScreen(),
                    ),
                  );
                  break;
                case 'chat':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminChatScreen()),
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
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Hồ sơ cá nhân'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'manage_categories',
                    child: ListTile(
                      leading: Icon(Icons.category),
                      title: Text('Quản lý danh mục'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'manage_products',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Quản lý sản phẩm'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'chat',
                    child: ListTile(
                      leading: Icon(Icons.chat),
                      title: Text('Tin nhắn'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Đăng xuất'),
                    ),
                  ),
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
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Tin nhắn'),
        ],
      ),
      floatingActionButton:
          _selectedIndex == 0
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
              ...categories.map(
                (doc) =>
                    DropdownMenuItem(value: doc.id, child: Text(doc['name'])),
              ),
            ],
            onChanged: (value) => setState(() => _selectedCategoryId = value),
          );
        },
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
      onSelected:
          (_) => setState(() {
            _selectedFilter = isSelected ? null : value;
          }),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ProductFormScreen(
                                    productId: doc.id,
                                    productData: data,
                                  ),
                            ),
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(doc.id)
                            .delete();
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
