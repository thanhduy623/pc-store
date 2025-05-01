import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_store/screens/chat_admin.dart';
import 'CountAccount.dart';
import 'profile_screen.dart';
import 'DiscountManagerPage.dart';
import 'OrderListPage_Admin.dart';

class HomeScreenAdmin extends StatefulWidget {
  const HomeScreenAdmin({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenAdmin> {
  int _selectedIndex = 0;

  // Function to handle navigation based on selected index.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // List of screens to navigate to for each bottom navigation item.
  final List<Widget> _screens = [
    const HomeScreenContent(), // Home Screen content
    const ProfileScreen(), // Profile screen content
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Quản trị viên';
    final email = user?.email ?? '';
    final photoURL = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ - Admin'),
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
                case 'chat-admin':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminChatScreen()),
                  );
                  break;
                case 'discount':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DiscountManagerPage(),
                    ),
                  );
                  break;
                case 'orders':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderListPage()),
                  );
                  break;
                case 'count':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AmountScreen()),
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
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: const [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Hồ sơ cá nhân'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'orders',
                    child: Row(
                      children: const [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Quản lí đơn hàng'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'discount',
                    child: Row(
                      children: const [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Quản lí giảm giá'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'chat-admin',
                    child: Row(
                      children: const [
                        Icon(Icons.chat),
                        SizedBox(width: 8),
                        Text('Trả lời tư vấn'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'count',
                    child: Row(
                      children: const [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Số lượng người dùng'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: const [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Đăng xuất'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: _screens[_selectedIndex], // Display the current screen
    );
  }
}

// This is just a placeholder for the Home content.
class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Người dùng';
    final email = user?.email ?? '';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Chào mừng, $displayName!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(email),
        ],
      ),
    );
  }
}
