import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase/auth_service.dart';
import '../models/product.dart';
import 'ConfirmOrderPage.dart';

class LoginDialog extends StatefulWidget {
  final List<Product> selectedProducts;

  const LoginDialog({super.key, required this.selectedProducts});

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
    String email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        loginResult = "Vui lòng nhập đủ thông tin";
      });
      return;
    }

    if (!isValidEmailFormat(email)) {
      email = "$email@gmail.com";
      emailController.text = email;
    }

    final user = await _auth.signIn(email, password);

    if (user != null) {
      // Fetch role from Firestore (you might not need the role check here if the flow is just for checkout)
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

        // Đăng nhập thành công, chuyển đến trang xác nhận đơn hàng
        Navigator.of(context).pop(); // Đóng dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ConfirmPage(
                  selectedProducts: widget.selectedProducts,
                  userEmail: user.email,
                ),
          ),
        );
      } else {
        setState(() {
          loginResult = "Không tìm thấy thông tin người dùng";
        });
        await FirebaseAuth.instance.signOut();
      }
    } else {
      setState(() {
        loginResult = "Đăng nhập thất bại";
      });
    }
  }

  // Helper function to validate email format
  bool isValidEmailFormat(String email) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                isDense: true,
              ),
              onSubmitted: (value) {
                login();
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                isDense: true,
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
            ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
              ),
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 10),
            if (loginResult.isNotEmpty)
              Text(
                loginResult,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Đóng dialog khi chưa đăng nhập
            if (loginResult.isNotEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(loginResult)));
            }
          },
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}
