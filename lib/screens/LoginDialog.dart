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
    String email =
        emailController.text.trim().toLowerCase(); // Changed to lowerCase()
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        loginResult = "Vui lòng nhập đủ thông tin";
      });
      return;
    }

    // Check and fix email format if needed
    if (!isValidEmailFormat(email)) {
      // Changed to isValidEmailFormat
      email = "$email@gmail.com";
      emailController.text = email; // Update the controller's text
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
        final isBlocked =
            userDoc.data()?['isBlocked'] as bool? ??
            false; // Check for isBlocked
        if (isBlocked) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            loginResult = "Tài khoản của bạn đã bị khóa.";
          });
          return;
        }

        final role =
            userDoc
                .data()?['role']
                ?.toString()
                .toLowerCase(); // Assuming 'role' is stored in Firestore

        // Navigate to Admin Chat Screen if role is "Admin"
        if (role == "admin") {
          // Changed to lower case "admin"
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
        await FirebaseAuth.instance.signOut(); // Sign out if user doc not found
      }
    } else {
      setState(() {
        loginResult = "Đăng nhập thất bại";
      });
    }
  }

  // Helper function to validate email format
  bool isValidEmailFormat(String email) {
    // Changed function name
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

    if (!isValidEmailFormat(email)) {
      // Changed to isValidEmailFormat
      setState(() {
        loginResult = "Email không hợp lệ";
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
      // Fetch user data and role after Google sign-in
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final isBlocked = userDoc.data()?['isBlocked'] as bool? ?? false;
        if (isBlocked) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            loginResult = "Tài khoản của bạn đã bị khóa.";
          });
          return;
        }

        final role = userDoc.data()?['role']?.toString().toLowerCase();
        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreenAdmin()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        setState(() {
          loginResult = "Không tìm thấy thông tin người dùng.";
        });
        await FirebaseAuth.instance.signOut();
      }
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
