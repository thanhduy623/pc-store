import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_store/screens/admin_home_screen.dart';
import 'package:my_store/screens/home.dart';
import '../services/firebase/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = AuthService();
  bool _obscurePassword = true;

  // Đăng nhập bằng email + mật khẩu
  void login() async {
    String email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showSnackBar("Vui lòng nhập đủ thông tin");
      return;
    }

    if (!isValidEmailFormat(email)) {
      email = '$email@gmail.com';
      emailController.text = email;
    }

    final user = await _auth.signIn(email, password);

    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        final isBlocked = userDoc.data()?['isBlocked'] as bool? ?? false;
        if (isBlocked) {
          await FirebaseAuth.instance.signOut();
          showSnackBar("Tài khoản của bạn đã bị khóa.");
          return;
        }
        await _navigateBasedOnRole(user.uid);
      } else {
        showSnackBar("Không tìm thấy thông tin người dùng.");
        await FirebaseAuth.instance.signOut();
      }
    } else {
      showSnackBar("Đăng nhập thất bại");
    }
  }

  // Validate email format
  bool isValidEmailFormat(String email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  // Điều hướng theo vai trò
  Future<void> _navigateBasedOnRole(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      showSnackBar("Không tìm thấy thông tin người dùng");
      return;
    }

    final role = userDoc.data()?['role']?.toString().toLowerCase();
    final isAdmin = role == 'admin';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isAdmin ? const AdminHomeScreen() : const HomeScreen(),
      ),
    );
  }

  void resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showSnackBar("Vui lòng nhập email để khôi phục");
      return;
    }

    if (!isValidEmailFormat(email)) {
      showSnackBar("Email không hợp lệ");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showSnackBar("Đã gửi email khôi phục mật khẩu");
    } catch (e) {
      showSnackBar("Lỗi: $e");
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Chào mừng bạn quay lại',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => login(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  onSubmitted: (_) => login(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: resetPassword,
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: login,
                  child: const Text('Đăng nhập'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Chưa có tài khoản?"),
                    TextButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                      child: const Text('Đăng ký'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
