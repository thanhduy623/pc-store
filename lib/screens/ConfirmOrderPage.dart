import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_store/utils/location_service.dart';
import 'package:my_store/utils/moneyFormat.dart';
import 'package:my_store/models/cart_item.dart';
import 'package:my_store/services/firebase/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

FirestoreService _firestoreService = FirestoreService();

class ConfirmOrderPage extends StatefulWidget {
  final List<CartItem> selectedItems;

  const ConfirmOrderPage({super.key, required this.selectedItems});

  @override
  State<ConfirmOrderPage> createState() => _ConfirmOrderPageState();
}

class _ConfirmOrderPageState extends State<ConfirmOrderPage> {
  int _currentStep = 0;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final detailAddressController = TextEditingController();

  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedWard;

  List<Map<String, dynamic>> provinceList = [];
  List<Map<String, dynamic>> districtList = [];
  List<Map<String, dynamic>> wardList = [];

  int userPoints = 0;
  int pointsToUse = 0;
  String? discountCode;
  double discountFromCode = 0;

  double get subtotal {
    return widget.selectedItems.fold(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );
  }

  double shippingFee = 20000;
  double vat = 0.08;

  double get discountFromPoints => pointsToUse * 1000;

  double get total {
    final afterPoints = subtotal - discountFromPoints;
    final afterCode = afterPoints - discountFromCode;
    final vatAmount = afterCode * vat;
    return afterCode + shippingFee + vatAmount;
  }

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _getUserData();
  }

  Future<void> _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print("User Email: ${user.email}");

      List<Map<String, dynamic>> data = await _firestoreService
          .getDataWithExactMatch("users", {"email": user.email});

      if (data.isNotEmpty) {
        var userData = data.first;
        print("User Data: $userData");

        nameController.text = userData['fullName'] ?? '';
        phoneController.text = userData['phone'] ?? '';
        detailAddressController.text = userData['shippingAddress'] ?? '';
        emailController.text = userData['email'] ?? '';

        setState(() {
          userPoints = userData['point'] ?? 0;
        });

        if (userData['province'] != null) {
          final provinceMatch = provinceList.firstWhereOrNull(
            (province) => province['name'] == userData['province'],
          );
          if (provinceMatch != null) {
            _selectedProvince = provinceMatch;
            await _loadDistricts(provinceMatch['code']);
          }
        }

        if (userData['district'] != null && _selectedProvince != null) {
          // Ensure districtList is loaded if province was found
          if (districtList.isEmpty) {
            await _loadDistricts(_selectedProvince!['code']);
          }
          final districtMatch = districtList.firstWhereOrNull(
            (district) => district['name'] == userData['district'],
          );
          if (districtMatch != null) {
            _selectedDistrict = districtMatch;
            await _loadWards(districtMatch['code']);
          }
        }

        if (userData['ward'] != null && _selectedDistrict != null) {
          // Ensure wardList is loaded if district was found
          if (wardList.isEmpty) {
            await _loadWards(_selectedDistrict!['code']);
          }
          _selectedWard = wardList.firstWhereOrNull(
            (ward) => ward['name'] == userData['ward'],
          );
        }

        // Ensure UI updates after all async operations
        if (mounted) {
          setState(() {});
        }
      } else {
        print("Không tìm thấy người dùng với email ${user.email}");
      }
    } else {
      print("No user is signed in.");
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await LocationService.fetchProvinces();
      if (mounted) {
        setState(() {
          provinceList = provinces;
        });
      }
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
          // Only reset if no initial match
          if (_selectedDistrict == null ||
              (_selectedProvince != null &&
                  _selectedProvince!['code'] != provinceCode)) {
            _selectedDistrict = null;
          }
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
          // Only reset if no initial match
          if (_selectedWard == null ||
              (_selectedDistrict != null &&
                  _selectedDistrict!['code'] != districtCode)) {
            _selectedWard = null;
          }
        });
      }
    } catch (e) {
      print("Lỗi khi tải xã/phường: $e");
    }
  }

  void _checkAndSelectProvince(
    List<Map<String, dynamic>> provinceList,
    Map<String, dynamic>? selectedProvince,
  ) {
    if (selectedProvince != null) {
      print("Tỉnh ${selectedProvince['name']} đã được chọn");
    }
  }

  void _checkAndSelectDistrict(
    List<Map<String, dynamic>> districtList,
    Map<String, dynamic>? selectedDistrict,
  ) {
    if (selectedDistrict != null) {
      print("Quận/Huyện ${selectedDistrict['name']} đã được chọn");
    }
  }

  void _checkAndSelectWard(
    List<Map<String, dynamic>> wardList,
    Map<String, dynamic>? selectedWard,
  ) {
    if (selectedWard != null) {
      print("Xã/Phường ${selectedWard['name']} đã được chọn");
    }
  }

  void _applyDiscountCode() async {
    if (discountCode == null || discountCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập mã khuyến mãi")),
      );
      return;
    }

    final discountData = await _firestoreService.getDataById(
      "discounts",
      discountCode!.trim(),
    );

    if (discountData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mã khuyến mãi không hợp lệ")),
      );
      setState(() {
        discountFromCode = 0;
      });
      return;
    }

    if (discountData['type'] != "Khuyến mãi") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mã này không phải khuyến mãi")),
      );
      return;
    }

    // Check hạn sử dụng
    final expiryString = discountData['expiry'] as String;
    final expiryDate = DateFormat('dd/MM/yyyy').parse(expiryString);
    if (expiryDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Mã khuyến mãi đã hết hạn")));
      return;
    }

    setState(() {
      if (discountData['valueType'] == "Phần trăm") {
        final value = double.tryParse(discountData['value'].toString()) ?? 0;
        final afterPoints = subtotal - discountFromPoints;
        discountFromCode = afterPoints * (value / 100);
      } else if (discountData['valueType'] == "Số tiền") {
        discountFromCode =
            double.tryParse(discountData['value'].toString()) ?? 0;
      } else {
        discountFromCode = 0;
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Áp dụng mã thành công!")));

    _validateTotal();
  }

  bool _checkStep1Completed() {
    return nameController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        detailAddressController.text.isNotEmpty &&
        _selectedProvince != null &&
        _selectedDistrict != null &&
        _selectedWard != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xác nhận đơn hàng")),
      body: Column(
        children: [
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  if (_checkStep1Completed()) {
                    setState(() {
                      _currentStep++;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Vui lòng điền đầy đủ thông tin."),
                      ),
                    );
                  }
                } else if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _submitOrder();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              steps: [
                Step(
                  title: const Text("Thông tin người nhận"),
                  content: _buildStep1(),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: const Text("Sử dụng điểm"),
                  content: _buildStep2(),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: const Text("Xem lại đơn hàng"),
                  content: _buildStep3(),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSummaryRow("Tạm tính", moneyFormat(subtotal)),
                _buildSummaryRow(
                  "Giảm từ điểm",
                  "-${moneyFormat(discountFromPoints)}",
                ),
                _buildSummaryRow(
                  "Mã giảm giá",
                  "-${moneyFormat(discountFromCode)}",
                ),
                _buildSummaryRow("Phí vận chuyển", moneyFormat(shippingFee)),
                _buildSummaryRow(
                  "VAT (8%)",
                  moneyFormat(
                    (subtotal - discountFromPoints - discountFromCode) * vat,
                  ),
                ),
                const Divider(),
                _buildSummaryRow("Tổng cộng", moneyFormat(total), bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Họ tên"),
        ),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "Số điện thoại"),
        ),
        // Thêm trường email
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        TextField(
          controller: detailAddressController,
          decoration: const InputDecoration(labelText: "Địa chỉ chi tiết"),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Map<String, dynamic>>(
          decoration: const InputDecoration(labelText: "Tỉnh / Thành phố"),
          value: _selectedProvince,
          items:
              provinceList
                  .map<DropdownMenuItem<Map<String, dynamic>>>(
                    (p) => DropdownMenuItem<Map<String, dynamic>>(
                      value: p,
                      child: Text(p['name'] ?? ''),
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
              _checkAndSelectProvince(provinceList, value);
            }
          },
        ),
        DropdownButtonFormField<Map<String, dynamic>>(
          decoration: const InputDecoration(labelText: "Quận / Huyện"),
          value: _selectedDistrict,
          items:
              districtList
                  .map<DropdownMenuItem<Map<String, dynamic>>>(
                    (d) => DropdownMenuItem<Map<String, dynamic>>(
                      value: d,
                      child: Text(d['name'] ?? ''),
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
              _checkAndSelectDistrict(districtList, value);
            }
          },
        ),
        DropdownButtonFormField<Map<String, dynamic>>(
          decoration: const InputDecoration(labelText: "Xã / Phường"),
          value: _selectedWard,
          items:
              wardList
                  .map<DropdownMenuItem<Map<String, dynamic>>>(
                    (w) => DropdownMenuItem<Map<String, dynamic>>(
                      value: w,
                      child: Text(w['name'] ?? ''),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedWard = value;
            });
            if (value != null) {
              _checkAndSelectWard(wardList, value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final discountCodeController = TextEditingController(
      text: discountCode ?? '',
    );
    final pointController = TextEditingController(text: pointsToUse.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bạn có $userPoints điểm tích lũy."),
        Text("Mỗi điểm giảm 1.000đ."),
        const SizedBox(height: 10),

        // Nhập điểm
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: pointController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Số điểm muốn dùng",
                ),
                onChanged: (value) {
                  // Cập nhật giá trị điểm trong controller khi người dùng nhập
                  final entered = int.tryParse(value) ?? 0;
                  setState(() {
                    if (entered > userPoints) {
                      pointsToUse = userPoints;
                      pointController.text = userPoints.toString();
                      pointController.selection = TextSelection.fromPosition(
                        TextPosition(offset: pointController.text.length),
                      );
                    } else {
                      pointsToUse = entered;
                    }
                  });
                  _validateTotal(); // Gọi hàm kiểm tra tổng khi thay đổi điểm
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Nhập mã giảm giá
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: discountCodeController,
                decoration: const InputDecoration(
                  labelText: "Nhập mã khuyến mãi",
                  hintText: "VD: GIAM50",
                ),
                onChanged: (value) {
                  discountCode = value;
                },
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _applyDiscountCode,
              child: const Text("Áp dụng"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final items = widget.selectedItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ...items.map(
          (item) => ListTile(
            title: Text(item.name),
            subtitle: Text(
              "Đơn giá: ${moneyFormat(item.price)} x ${item.quantity}",
            ),
            trailing: Text(moneyFormat(item.price * item.quantity)),
          ),
        ),
      ],
    );
  }

  Future<void> _checkAndHandleEmail() async {
    final email = emailController.text.trim();

    if (email.isNotEmpty) {
      // Kiểm tra email trong cơ sở dữ liệu
      final userData = await _firestoreService.getDataWithExactMatch("users", {
        "email": email,
      });

      if (userData.isNotEmpty) {
        // Email đã tồn tại trong hệ thống, hiển thị popup yêu cầu đăng nhập
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Thông báo"),
              content: const Text(
                "Email này đã tồn tại trong hệ thống. Vui lòng đăng nhập để sử dụng điểm tích lũy.",
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Chuyển sang màn hình đăng nhập
                  },
                  child: const Text("Đăng nhập"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Hủy"),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _submitOrder() async {
    // Kiểm tra xem người dùng đã đăng nhập chưa
    User? user = FirebaseAuth.instance.currentUser;

    // Nếu người dùng chưa đăng nhập và email đã tồn tại trong hệ thống
    if (user == null) {
      final email = emailController.text.trim();

      // Kiểm tra xem email có tồn tại trong cơ sở dữ liệu không
      final userData = await _firestoreService.getDataWithExactMatch("users", {
        "email": email,
      });

      if (userData.isNotEmpty) {
        // Email đã tồn tại, yêu cầu đăng nhập
        _checkAndHandleEmail();
      } else {
        // Tạo người dùng mới và lưu đơn hàng
        await _createUserAndSaveOrder();
      }
    } else {
      // Người dùng đã đăng nhập, tiến hành lưu đơn hàng
      await _saveOrder();
    }
  }

  Future<void> _createUserAndSaveOrder() async {
    try {
      // Lưu thông tin người dùng mới vào Firestore
      try {
        // Tạo tài khoản mới
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password:
                  phoneController.text.trim(), // Mặc định là số điện thoại
            );

        final user = userCredential.user;
        if (user != null) {
          final uid = user.uid;

          // Lưu dữ liệu người dùng vào Firestore
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'email': emailController.text.trim(),
            'fullName': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            'shippingAddress': detailAddressController.text.trim(),
            'province': _selectedProvince?['name'] ?? '',
            'district': _selectedDistrict?['name'] ?? '',
            'ward': _selectedWard?['name'] ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'point': ((total * 0.05) / 1000).floor(),
          });

          // Tăng số lượng tài khoản (nếu có quản lý ở Realtime Database)
          final databaseRef = FirebaseDatabase.instance.ref();
          final snapshot = await databaseRef.child("users").get();
          if (snapshot.exists) {
            final data = snapshot.value as Map?;
            int currentAmount = data?['amount'] ?? 0;
            await databaseRef.child("users").update({
              'amount': currentAmount + 1,
            });
          } else {
            await databaseRef.child("users").set({'amount': 1});
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Tạo tài khoản thành công\nTài khoản: ${emailController.text.trim()}\nMật khẩu: ${phoneController.text.trim()}",
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi tạo tài khoản: $e")));
      }

      // Sau khi tạo người dùng, lưu đơn hàng
      await _saveOrder();
    } catch (e) {
      print("Lỗi khi tạo người dùng: $e");
    }
  }

  Future<void> _saveOrder() async {
    try {
      final order = {
        'fullName': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'shippingAddress':
            "${detailAddressController.text.trim()}, ${_selectedWard?['name']}, ${_selectedDistrict?['name']}, ${_selectedProvince?['name']}",
        'subtotal': subtotal,
        'discountFromPoints': discountFromPoints,
        'discountFromCode': discountFromCode,
        'shippingFee': shippingFee,
        'vat': (subtotal - discountFromPoints - discountFromCode) * vat,
        'total': total,
        'orderDate': DateTime.now(),
        'status': 'Chờ xử lí',
        'items':
            widget.selectedItems.map((item) {
              return {
                'productId': item.id,
                'productName': item.name,
                'quantity': item.quantity,
                'unitPrice': item.price,
                'totalPrice': item.price * item.quantity,
              };
            }).toList(),
      };

      // Lưu đơn hàng vào Firestore
      await _firestoreService.addWithAutoId('orders', order);

      // Sau khi lưu đơn hàng thành công, có thể đưa người dùng đến trang cảm ơn hoặc thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đơn hàng đã được xác nhận")),
      );

      updateUserPointsIfExists();
    } catch (e) {
      print("Lỗi khi lưu đơn hàng: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã có lỗi xảy ra, vui lòng thử lại")),
      );
    }
  }

  void updateUserPointsIfExists() async {
    try {
      final email = emailController.text.trim();

      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userSnapshot.docs.isNotEmpty) {
        final doc = userSnapshot.docs.first;
        final data = doc.data();

        // Nếu chưa có trường 'point', mặc định là 0
        final currentPoints =
            (data.containsKey('point') && data['point'] != null)
                ? (data['point'] as int)
                : 0;

        // Tính điểm mới cộng thêm
        int earnedPoints = ((total * 0.05) / 1000).floor();

        // Tính điểm còn lại sau khi trừ và cộng
        int updatedPoints = currentPoints - pointsToUse + earnedPoints;
        if (updatedPoints < 0) updatedPoints = 0;

        // Cập nhật lại điểm
        await FirebaseFirestore.instance.collection('users').doc(doc.id).update(
          {'point': updatedPoints},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cập nhật điểm thành công: $updatedPoints điểm"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không tìm thấy người dùng với email này")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi cập nhật điểm: $e")));
    }
  }

  void _validateTotal() {
    final totalDiscount = discountFromPoints + discountFromCode;
    if (totalDiscount >= subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tổng giảm giá vượt quá giá trị đơn hàng. Đơn hàng tối thiểu phải có giá 0đ.",
          ),
        ),
      );
      return;
    }
  }

  Widget _buildSummaryRow(String title, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(value),
      ],
    );
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
