import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import '../services/firebase/auth_service.dart';
import 'home_admin.dart';
import 'Home.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  _LoginDialogState createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = AuthService();

  bool _obscurePassword = true;
  String loginResult = ''; // This will hold the login result message

  // Đăng nhập bằng email + mật khẩu
  void login() async {
    String email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        loginResult = "Vui lòng nhập đủ thông tin";
      });
      return;
    }

    // Check and fix email format if needed
    if (!isValidEmail(email)) {
      email = "$email@gmail.com";
    }

    final user = await _auth.signIn(email, password);

    if (user != null) {
      // Fetch role from Firestore after login
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final role =
            userDoc.data()?['role']; // Assuming 'role' is stored in Firestore

        // Navigate to Admin Chat Screen if role is "Admin"
        if (role == "Admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreenAdmin()),
          );
        } else {
          // Navigate to Home Screen for other roles
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        setState(() {
          loginResult = "Không tìm thấy thông tin người dùng";
        });
      }
    } else {
      setState(() {
        loginResult = "Đăng nhập thất bại";
      });
    }
  }

  // Helper function to validate email format
  bool isValidEmail(String email) {
    // Regular expression to check if the email is valid
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  // Khôi phục mật khẩu
  void resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        loginResult = "Vui lòng nhập email để khôi phục";
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        loginResult = "Đã gửi email khôi phục mật khẩu";
      });
    } catch (e) {
      setState(() {
        loginResult = "Lỗi: $e";
      });
    }
  }

  // Đăng nhập bằng Google
  void loginWithGoogle() async {
    final user = await _auth.signInWithGoogle();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        loginResult = "Đăng nhập Google thất bại";
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đăng nhập'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children
          children: [
            // Email TextField
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                isDense: true, // Makes the field take up more width
              ),
              onSubmitted: (value) {
                login();
              },
            ),
            const SizedBox(height: 10),

            // Password TextField
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                isDense: true, // Makes the field take up more width
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onSubmitted: (value) {
                login();
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: resetPassword,
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: 20),

            // Login Button
            ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(45), // Makes button larger
              ),
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 10),

            // Google Login Button
            ElevatedButton.icon(
              onPressed: loginWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập bằng Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: Size.fromHeight(45), // Makes button larger
              ),
            ),
            const SizedBox(height: 10),
            // Display the login result message
            if (loginResult.isNotEmpty)
              Text(
                loginResult,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
