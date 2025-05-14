import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase/auth_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_store/utils/location_service.dart';

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

  List<Map<String, dynamic>> provinceList = [];
  List<Map<String, dynamic>> districtList = [];
  List<Map<String, dynamic>> wardList = [];

  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedWard;

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.refFromURL(
    'https://my-store-fb27a-default-rtdb.firebaseio.com/',
  );
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await LocationService.fetchProvinces();
      if (mounted) setState(() => provinceList = provinces);
    } catch (e) {
      print("Lỗi khi tải tỉnh/thành: $e");
    }
  }

  Future<void> _loadDistricts(int provinceCode) async {
    try {
      final districts = await LocationService.fetchDistricts(provinceCode);
      if (mounted) {
        setState(() {
          districtList = districts;
          _selectedDistrict = null;
          wardList.clear();
          _selectedWard = null;
        });
      }
    } catch (e) {
      print("Lỗi khi tải quận/huyện: $e");
    }
  }

  Future<void> _loadWards(int districtCode) async {
    try {
      final wards = await LocationService.fetchWards(districtCode);
      if (mounted) {
        setState(() {
          wardList = wards;
          _selectedWard = null;
        });
      }
    } catch (e) {
      print("Lỗi khi tải xã/phường: $e");
    }
  }

  bool _validateInputs() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();
    final address = addressController.text.trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        address.isEmpty ||
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null) {
      Fluttertoast.showToast(msg: 'Vui lòng điền đầy đủ thông tin.');
      return false;
    }

    if (!emailRegex.hasMatch(email)) {
      Fluttertoast.showToast(msg: 'Email không hợp lệ.');
      return false;
    }

    if (password.length < 6) {
      Fluttertoast.showToast(msg: 'Mật khẩu phải có ít nhất 6 ký tự.');
      return false;
    }

    return true;
  }

  void register() async {
    if (!_validateInputs()) return;

    try {
      final user = await _auth.register(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (user != null) {
        await saveUserData(user.uid);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đăng ký thành công")));
        countAccount();
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đăng ký thất bại: $e")));
    }
  }

  Future<void> saveUserData(String uid) async {
    String address =
        "${addressController.text.trim()}, "
        "${_selectedWard?['name'] ?? ''}, "
        "${_selectedDistrict?['name'] ?? ''}, "
        "${_selectedProvince?['name'] ?? ''}";

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': emailController.text.trim(),
        'fullName': nameController.text.trim(),
        'shippingAddress': address,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Lỗi lưu thông tin người dùng: $e");
    }
  }

  void countAccount() {
    _databaseRef.child("users").get().then((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null && data.containsKey('amount')) {
          int currentAmount = data['amount'] ?? 0;
          _databaseRef.child("users").update({'amount': currentAmount + 1});
        }
      } else {
        _databaseRef.child("users").set({'amount': 1});
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Tạo tài khoản mới",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ cụ thể',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(
                    labelText: "Tỉnh / Thành phố",
                  ),
                  value: _selectedProvince,
                  items:
                      provinceList
                          .map(
                            (province) => DropdownMenuItem(
                              value: province,
                              child: Text(province['name'] ?? ''),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null;
                      _selectedWard = null;
                      districtList.clear();
                      wardList.clear();
                    });
                    if (value != null) {
                      _loadDistricts(value['code']);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(labelText: "Quận / Huyện"),
                  value: _selectedDistrict,
                  items:
                      districtList
                          .map(
                            (district) => DropdownMenuItem(
                              value: district,
                              child: Text(district['name'] ?? ''),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                      _selectedWard = null;
                      wardList.clear();
                    });
                    if (value != null) {
                      _loadWards(value['code']);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(labelText: "Xã / Phường"),
                  value: _selectedWard,
                  items:
                      wardList
                          .map(
                            (ward) => DropdownMenuItem(
                              value: ward,
                              child: Text(ward['name'] ?? ''),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedWard = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: register,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Đăng ký', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
