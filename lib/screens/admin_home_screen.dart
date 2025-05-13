import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'category_screen.dart';
import 'chat_admin.dart';
import 'profile_screen.dart';
import 'package:my_store/screens/ManageProduct.dart';
import 'package:my_store/screens/DiscountManagerPage.dart';
import 'package:my_store/screens/dashboard.dart';
import 'package:my_store/screens/ManageUser.dart';

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

  final List<Widget> _screens = [
    const DashboardScreen(), // Trang mặc định
    const ProfileScreen(),
    const AdminChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
                case 'manage_discounts':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DiscountManagerPage(),
                    ),
                  );
                  break;
                case 'manage_users':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementScreen(),
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
                    value: 'manage_categories',
                    child: ListTile(
                      leading: Icon(Icons.category),
                      title: Text('Quản lý danh mục'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'manage_products',
                    child: ListTile(
                      leading: Icon(Icons.shopping_bag),
                      title: Text('Quản lý sản phẩm'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'manage_discounts',
                    child: ListTile(
                      leading: Icon(Icons.local_offer),
                      title: Text('Quản lý giảm giá'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'manage_users',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Quản lý người dùng'),
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
    );
  }
}
