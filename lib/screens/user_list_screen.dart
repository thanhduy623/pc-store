import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  Future<void> _toggleUserLock(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isLocked': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý người dùng")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          if (users.isEmpty)
            return const Center(child: Text("Không có người dùng nào."));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final isLocked = data['isLocked'] == true;

              return ListTile(
                leading: Icon(
                  Icons.person,
                  color: isLocked ? Colors.red : Colors.green,
                ),
                title: Text(name),
                subtitle: Text(email),
                trailing: TextButton.icon(
                  icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
                  label: Text(isLocked ? "Mở khóa" : "Khóa"),
                  onPressed: () => _toggleUserLock(doc.id, isLocked),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
