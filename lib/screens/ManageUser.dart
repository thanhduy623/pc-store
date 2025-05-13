import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen_user.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  final int _usersPerPage = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  List<DocumentSnapshot> _users = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(_usersPerPage);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();
    final newUsers =
        snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final email = (data['email'] ?? '').toString().toLowerCase();
          final role = (data['role'] ?? '').toString().toLowerCase();
          return role != 'admin' && email.contains(_searchQuery);
        }).toList();

    setState(() {
      _isLoading = false;
      if (newUsers.isNotEmpty) {
        _users.addAll(newUsers);
        _lastDocument = newUsers.last;
      } else {
        _hasMore = false;
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý người dùng")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm người dùng theo email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                  _users.clear();
                  _lastDocument = null;
                  _hasMore = true;
                  _fetchUsers();
                });
              },
            ),
          ),
          Expanded(child: _buildUserList()),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_users.isEmpty && !_isLoading)
            const Center(child: Text('Không tìm thấy người dùng.')),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _users.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _users.length) {
          final doc = _users[index];
          final data = doc.data() as Map<String, dynamic>;

          final fullName = data['fullName'] ?? 'Không tên';
          final email = data['email'] ?? 'Không có email';
          final isBlocked = data['isBlocked'] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(fullName),
              subtitle: Text(email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProfileScreenUser(
                                userData: {'id': doc.id, 'data': data},
                              ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      isBlocked ? Icons.lock : Icons.lock_open,
                      color: isBlocked ? Colors.red : Colors.green,
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(doc.id)
                          .update({'isBlocked': !isBlocked});
                    },
                  ),
                ],
              ),
            ),
          );
        } else if (_hasMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          return Container();
        }
      },
    );
  }
}
