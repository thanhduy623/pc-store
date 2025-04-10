import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();

  User? user = FirebaseAuth.instance.currentUser;

  String email = '';

  @override
  void initState() {
    super.initState();
    if (user != null) {
      email = user!.email!;
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

    if (userDoc.exists) {
      setState(() {
        _fullNameController.text = userDoc['fullName'] ?? '';
        _addressController.text = userDoc['shippingAddress'] ?? '';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'fullName': _fullNameController.text.trim(),
            'shippingAddress': _addressController.text.trim(),
          });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hồ sơ đã được cập nhật')));
    }
  }

  Future<void> _changePassword() async {
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Đổi mật khẩu'),
            content: TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await user!.updatePassword(
                      newPasswordController.text.trim(),
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã đổi mật khẩu thành công')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
                child: Text('Xác nhận'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý hồ sơ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                readOnly: true,
                initialValue: email,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: 'Họ tên đầy đủ'),
                validator:
                    (value) => value!.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Địa chỉ giao hàng'),
                validator:
                    (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Lưu thay đổi'),
              ),
              TextButton(
                onPressed: _changePassword,
                child: Text('Đổi mật khẩu'),
              ),
              TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
