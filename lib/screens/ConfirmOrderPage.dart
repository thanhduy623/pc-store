import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_store/models/product.dart';
import 'package:my_store/utils/moneyFormat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_store/utils/sendOrderMail.dart';

class ConfirmPage extends StatefulWidget {
  final List<Product> selectedProducts;
  final String? userEmail;

  const ConfirmPage({
    Key? key,
    required this.selectedProducts,
    required this.userEmail,
  }) : super(key: key);

  @override
  _ConfirmPageState createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  int _currentStep = 0;
  bool isEmailReadOnly = false;
  String pointsHint = "Bạn có 0 điểm (1 điểm = 1.000 đồng)";
  double userPoints = 0;

  // Dummy values for subtotal, discount, shipping fee, VAT, etc.
  double subtotal = 0;
  double discountFromPoints = 0;
  double discountFromCode = 0;
  Random random = Random();
  double shippingFee = Random().nextInt(51) * 1000.0;
  double vat = 0.08; // 8% VAT
  double total = 0;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  final TextEditingController discountCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calculateOrderDetails();

    // Chỉ cập nhật nếu đăng nhập
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      _loadUserData();
    }
  }

  // Tính tiền
  void _calculateOrderDetails() {
    subtotal = widget.selectedProducts.fold(0, (sum, item) {
      return sum + (item.price * item.quantity);
    });

    discountFromPoints = 0;
    discountFromCode = 0;

    double subtotalAfterDiscount =
        subtotal - discountFromPoints - discountFromCode;
    double vatAmount = subtotalAfterDiscount * vat;
    total = subtotalAfterDiscount + vatAmount + shippingFee;
  }

  Future<void> _loadUserData() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: widget.userEmail)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        String address =
            "${userData['shippingAddress']}, "
            "${userData['ward']}, "
            "${userData['district']}, "
            "${userData['province']}";

        emailController.text = userData['email'] ?? '';
        nameController.text = userData['fullName'] ?? '';
        phoneController.text = userData['phone'] ?? '';
        addressController.text = address;
        setState(() {
          isEmailReadOnly = true;
          userPoints = userData['point'] ?? 0;
          pointsHint = "Bạn có ${userPoints} điểm (1 điểm = 1.000 đồng)";
        });
      } else {
        print("No user found with that email.");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _saveOrder() async {
    try {
      final order = {
        'fullName': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'shippingAddress': addressController.text.trim(),
        'subtotal': subtotal,
        'discountFromPoints': discountFromPoints,
        'discountFromCode': discountFromCode,
        'shippingFee': shippingFee,
        'vat': subtotal * vat,
        'total': total,
        'orderDate': DateTime.now(),
        'status': {'Chờ xử lý': DateTime.now()},
        'items':
            widget.selectedProducts.map((item) {
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
      await FirebaseFirestore.instance.collection('orders').add(order);

      // Sau khi lưu đơn hàng thành công, có thể đưa người dùng đến trang cảm ơn hoặc thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đơn hàng đã được xác nhận")),
      );

      // Cập nhật điểm
      updateUserPointsIfExists();

      // Gửi mail
      sendEmailViaEmailJS(
        emailController.text.trim(),
        nameController.text.trim(),
        order,
      );

      // Xóa sản phẩm đã chọn trong đơn hàng
      await _removeOrderedProductsFromCart();
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
        double earnedPoints = total * 10 / 100;
        double usedPoints = double.tryParse(pointsController.text) ?? 0;
        double updatedPoints = currentPoints - usedPoints + earnedPoints;

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

  Future<void> _checkEmailAndCreateAccount() async {
    try {
      final email = emailController.text.trim();
      final password = phoneController.text.trim(); // Mặc định là số điện thoại

      // Kiểm tra xem email đã tồn tại chưa
      final authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (authResult.user != null) {
        // Sau khi đăng ký, thực hiện đăng nhập
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tạo tài khoản và đăng nhập thành công"),
          ),
        );
      }
    } catch (e) {
      print("Error during user creation or login: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xảy ra lỗi khi tạo tài khoản")),
      );
    }
  }

  Future<void> _removeOrderedProductsFromCart() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartData = prefs.getStringList('localCart') ?? [];

    // Convert shared pref data to Product list
    List<Product> cartProducts =
        cartData.map((item) => Product.fromJson(jsonDecode(item))).toList();

    // Lọc ra những sản phẩm không nằm trong đơn hàng (giữ lại)
    List<Product> updatedCart =
        cartProducts.where((cartItem) {
          return !widget.selectedProducts.any(
            (orderedItem) => orderedItem.id == cartItem.id,
          );
        }).toList();

    // Lưu lại cart đã cập nhật
    List<String> updatedData =
        updatedCart.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('localCart', updatedData);
  }

  Future<void> _processOrder() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      await _checkEmailAndCreateAccount();
    }

    // Sau khi đăng nhập hoặc tạo tài khoản, lưu đơn hàng
    await _saveOrder();
  }

  // Build step 1 content (Recipient information)
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Email"),
        TextField(
          controller: emailController,
          readOnly: isEmailReadOnly,
          decoration: const InputDecoration(hintText: "Nhập email"),
        ),
        const SizedBox(height: 10),
        const Text("Họ và tên"),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Nhập họ và tên"),
        ),
        const SizedBox(height: 10),
        const Text("Địa chỉ"),
        TextField(
          controller: addressController,
          decoration: const InputDecoration(hintText: "Nhập địa chỉ"),
        ),
        const SizedBox(height: 10),
        const Text("Số điện thoại"),
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(hintText: "Nhập số điện thoại"),
        ),
      ],
    );
  }

  // Build step 2 content (Use points and discount code)
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text("Nhập số điểm sử dụng"),
        TextField(
          controller: pointsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: pointsHint),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            // Kiểm tra điểm nhập vào không vượt quá số điểm người dùng có
            if (double.tryParse(value) != null) {
              double enteredPoints = double.parse(value);
              if (enteredPoints > userPoints) {
                pointsController.text = userPoints.toString();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Số điểm không thể lớn hơn điểm hiện có"),
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(height: 10),
        const Text("Nhập mã giảm giá"),
        TextField(
          controller: discountCodeController,
          decoration: const InputDecoration(
            hintText: "Nhập mã giảm giá (ví dụ: IT-50)",
          ),
        ),
      ],
    );
  }

  // Build step 3 content (Review order details)
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tóm tắt đơn hàng"),
        // Display selected products and order summary
        Column(
          children:
              widget.selectedProducts
                  .map(
                    (item) => ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        "${item.quantity} x ${moneyFormat(item.price)}",
                      ),
                      trailing: Text(moneyFormat(item.price * item.quantity)),
                    ),
                  )
                  .toList(),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text("Tổng cộng: "), Text(moneyFormat(total))],
        ),
      ],
    );
  }

  // Summary row widget
  Widget _buildSummaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xác nhận đơn hàng")),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() {
              _currentStep++;
            });
          } else {
            _processOrder();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          }
        },
        steps: [
          Step(
            title: const Text("Thông tin nhận hàng"),
            content: _buildStep1(),
          ),
          Step(
            title: const Text("Sử dụng điểm & mã giảm giá"),
            content: _buildStep2(),
          ),
          Step(title: const Text("Xem lại đơn hàng"), content: _buildStep3()),
        ],
      ),
      bottomNavigationBar: Container(
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
    );
  }
}
