import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final _auth = AuthService();

  void register() async {
    try {
      final user = await _auth.register(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (user != null) {
        // 🔥 Lưu thông tin vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': emailController.text.trim(),
          'fullName': nameController.text.trim(),
          'shippingAddress': addressController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đăng ký thành công")));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email này đã được đăng ký")),
        );
        emailController.clear();
        passwordController.clear();
        nameController.clear();
        addressController.clear();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi đăng ký: ${e.message}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đăng ký thất bại")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Họ tên'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ giao hàng',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: register, child: const Text('Đăng ký')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
