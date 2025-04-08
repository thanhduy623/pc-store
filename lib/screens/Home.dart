import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Người dùng';
    final email = user?.email ?? '';
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
      body: Center(
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
      ),
    );
  }
}
