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
  final phoneController = TextEditingController();
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

  // Fetch provinces
  Future<void> _loadProvinces() async {
    try {
      final provinces =
          await LocationService.fetchProvinces(); // Replace with your logic
      if (mounted) {
        setState(() {
          provinceList = provinces;
        });
      }
    } catch (e) {
      print("Lỗi khi tải tỉnh/thành: $e");
    }
  }

  // Fetch districts based on province
  Future<void> _loadDistricts(int provinceCode) async {
    try {
      final districts = await LocationService.fetchDistricts(
        provinceCode,
      ); // Replace with your logic
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

  // Fetch wards based on district
  Future<void> _loadWards(int districtCode) async {
    try {
      final wards = await LocationService.fetchWards(
        districtCode,
      ); // Replace with your logic
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

  // Register user
  void register() async {
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
        countAcount();
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đăng ký thất bại: $e")));
    }
  }

  // Save user data to Firestore
  Future<void> saveUserData(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': emailController.text.trim(),
        'fullName': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'shippingAddress': addressController.text.trim(),
        'province': _selectedProvince?['name'] ?? '',
        'district': _selectedDistrict?['name'] ?? '',
        'ward': _selectedWard?['name'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Lỗi lưu thông tin người dùng: $e");
    }
  }

  // Update the account count
  void countAcount() {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
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
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ giao hàng',
                    ),
                  ),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(
                      labelText: "Tỉnh / Thành phố",
                    ),
                    value: _selectedProvince,
                    items:
                        provinceList
                            .map<DropdownMenuItem<Map<String, dynamic>>>(
                              (province) =>
                                  DropdownMenuItem<Map<String, dynamic>>(
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
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(
                      labelText: "Quận / Huyện",
                    ),
                    value: _selectedDistrict,
                    items:
                        districtList
                            .map<DropdownMenuItem<Map<String, dynamic>>>(
                              (district) =>
                                  DropdownMenuItem<Map<String, dynamic>>(
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
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(labelText: "Xã / Phường"),
                    value: _selectedWard,
                    items:
                        wardList
                            .map<DropdownMenuItem<Map<String, dynamic>>>(
                              (ward) => DropdownMenuItem<Map<String, dynamic>>(
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: register,
                    child: const Text('Đăng ký'),
                  ),
                ],
              ),
            ),
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
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
