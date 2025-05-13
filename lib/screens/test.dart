import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> provinceList = [];
  final List<Map<String, dynamic>> districtList = [];
  final List<Map<String, dynamic>> wardList = [];

  Map<String, dynamic>? _randomProvince;
  Map<String, dynamic>? _randomDistrict;
  Map<String, dynamic>? _randomWard;

  // Dummy location data (replace with your actual data loading if needed)
  final List<Map<String, dynamic>> _dummyProvinces = [
    {'code': 79, 'name': 'Hồ Chí Minh'},
    {'code': 1, 'name': 'Hà Nội'},
    {'code': 48, 'name': 'Đà Nẵng'},
  ];
  final Map<int, List<Map<String, dynamic>>> _dummyDistricts = {
    79: [
      {'code': 760, 'name': 'Quận 1'},
      {'code': 769, 'name': 'Quận 3'},
      {'code': 778, 'name': 'Quận Gò Vấp'},
    ],
    1: [
      {'code': 001, 'name': 'Quận Ba Đình'},
      {'code': 002, 'name': 'Quận Hoàn Kiếm'},
      {'code': 003, 'name': 'Quận Tây Hồ'},
    ],
    48: [
      {'code': 490, 'name': 'Quận Hải Châu'},
      {'code': 491, 'name': 'Quận Thanh Khê'},
      {'code': 492, 'name': 'Quận Sơn Trà'},
    ],
  };
  final Map<int, List<Map<String, dynamic>>> _dummyWards = {
    760: [
      {'code': 26734, 'name': 'Phường Bến Nghé'},
      {'code': 26737, 'name': 'Phường Bến Thành'},
    ],
    769: [
      {'code': 26794, 'name': 'Phường 6'},
      {'code': 26797, 'name': 'Phường 7'},
    ],
    778: [
      {'code': 26899, 'name': 'Phường 1'},
      {'code': 26902, 'name': 'Phường 3'},
    ],
    // Add more wards for other districts as needed
  };

  Future<void> _createRandomUsers() async {
    final random = Random();
    final startDate = DateTime(2024, 12, 1);
    final endDate = DateTime.now();
    final duration = endDate.difference(startDate);

    for (int i = 1; i <= 30; i++) {
      final email = 'user$i@gmail.com';
      const password = 'user123';
      final displayName = 'Người dùng $i';
      final phoneNumber = '00000000${i.toString().padLeft(2, '0')}';

      // Generate a random second offset within the duration
      final randomSeconds = random.nextInt(duration.inSeconds + 1);
      final createdAt = startDate.add(Duration(seconds: randomSeconds));

      // Pick a random province, district, and ward
      final randomProvinceIndex = random.nextInt(_dummyProvinces.length);
      _randomProvince = _dummyProvinces[randomProvinceIndex];
      final provinceCode = _randomProvince?['code'];

      List<Map<String, dynamic>> availableDistricts = [];
      if (provinceCode != null && _dummyDistricts.containsKey(provinceCode)) {
        availableDistricts = _dummyDistricts[provinceCode]!;
      }
      if (availableDistricts.isNotEmpty) {
        final randomDistrictIndex = random.nextInt(availableDistricts.length);
        _randomDistrict = availableDistricts[randomDistrictIndex];
        final districtCode = _randomDistrict?['code'];

        List<Map<String, dynamic>> availableWards = [];
        if (districtCode != null && _dummyWards.containsKey(districtCode)) {
          availableWards = _dummyWards[districtCode]!;
        }
        if (availableWards.isNotEmpty) {
          final randomWardIndex = random.nextInt(availableWards.length);
          _randomWard = availableWards[randomWardIndex];
        } else {
          _randomWard = null;
        }
      } else {
        _randomDistrict = null;
        _randomWard = null;
      }

      final randomAddressDetail = 'Số ${random.nextInt(100)} Đường XYZ';
      final address =
          '$randomAddressDetail, ${_randomWard?['name'] ?? ''}, ${_randomDistrict?['name'] ?? ''}, ${_randomProvince?['name'] ?? ''}';

      try {
        final UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);
        final User? user = userCredential.user;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': email,
            'fullName': displayName,
            'phoneNumber': phoneNumber,
            'shippingAddress': address,
            'createdAt': Timestamp.fromDate(createdAt),
          });
          print('User $i created: $email, $phoneNumber');
        }
      } catch (e) {
        print('Error creating user $i: $e');
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo 30 người dùng ngẫu nhiên.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Người Dùng Hàng Loạt')),
      body: Center(
        child: ElevatedButton(
          onPressed: _createRandomUsers,
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Tạo 30 Người Dùng Ngẫu Nhiên',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
