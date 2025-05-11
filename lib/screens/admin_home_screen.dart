import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'category_screen.dart';
import 'chat_admin.dart';
import 'profile_screen.dart';
import 'product_form_screen.dart';
import 'package:my_store/screens/ManageProduct.dart';
import 'package:my_store/screens/dashboard.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Đảm bảo rằng DashboardScreen là trang mặc định khi khởi động
    _selectedIndex = 0; // Đảm bảo rằng trang Dashboard là trang đầu tiên
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const DashboardScreen(), // Trang mặc định
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
            // Đoạn mã popup menu
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
      body: _screens[_selectedIndex],
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
}
