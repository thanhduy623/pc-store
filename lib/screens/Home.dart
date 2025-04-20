import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'chat_user.dart';
import 'category_screen.dart';
import 'product_form_screen.dart'; // Trang thêm/sửa sản phẩm

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _selectedCategoryId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    final tokenResult = await user?.getIdTokenResult();
    final isAdmin = tokenResult?.claims?['admin'] == true;

    setState(() {
      _isAdmin = isAdmin ?? false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const SizedBox(), // Sẽ render theo index
    const ProfileScreen(),
    UserChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Người dùng';
    final photoURL = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
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
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Hồ sơ cá nhân'),
                    ),
                  ),
                  if (_isAdmin)
                    const PopupMenuItem(
                      value: 'manage_categories',
                      child: ListTile(
                        leading: Icon(Icons.category),
                        title: Text('Quản lý danh mục'),
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'chat_user',
                    child: ListTile(
                      leading: Icon(Icons.chat),
                      title: Text('Tư vấn sản phẩm'),
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
      floatingActionButton:
          _isAdmin && _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductFormScreen()),
                  );
                },
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  // Dropdown chọn danh mục
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

  // Hiển thị sản phẩm
  Widget _buildProductList() {
    Query query = FirebaseFirestore.instance.collection('products');
    if (_selectedCategoryId != null) {
      query = query.where('categoryId', isEqualTo: _selectedCategoryId);
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
                trailing:
                    _isAdmin
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
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
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          ],
                        )
                        : null,
              ),
            );
          },
        );
      },
    );
  }
}
