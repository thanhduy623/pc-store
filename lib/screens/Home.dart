import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
// import 'chat_screen.dart'; // Import your ChatScreen here.
import 'package:cloud_firestore/cloud_firestore.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    const ProfileScreen(),     // Profile screen content
    const ChatScreen(),        // Chat screen content
  ];

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
            itemBuilder: (context) => [
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
      body: _screens[_selectedIndex], // Display the current screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
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

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String userId = user?.uid ?? ''; // Lấy UID của người dùng hiện tại

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Đợi dữ liệu
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Có lỗi khi tải thông tin người dùng.'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Thông tin người dùng không tồn tại.'));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String address = userData['address'] ?? 'Chưa cập nhật địa chỉ';

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Chat Screen', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              Text('Địa chỉ: $address', style: const TextStyle(fontSize: 18)),
            ],
          ),
        );
      },
    );
  }
}
