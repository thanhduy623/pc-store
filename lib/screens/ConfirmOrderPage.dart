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
import 'package:my_store/screens/Home.dart';

class ConfirmPage extends StatefulWidget {
  final List<Product> selectedProducts;
  final String? userEmail;

  const ConfirmPage({
    super.key,
    required this.selectedProducts,
    required this.userEmail,
  });

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

    shippingFee = Random().nextInt(51) * 1000.0; // phí ship ngẫu nhiên
    double enteredPoints = double.tryParse(pointsController.text) ?? 0;
    double maxTotalBeforeDiscount = subtotal + shippingFee;

    // Nếu mã giảm giá đã lớn hơn tổng cần thanh toán thì không dùng điểm
    if (discountFromCode >= maxTotalBeforeDiscount) {
      discountFromPoints = 0;
      total = 0;
      pointsController.text = '0';
    } else {
      double remainingAfterCode = maxTotalBeforeDiscount - discountFromCode;

      // Nếu điểm nhập vào lớn hơn phần còn lại thì điều chỉnh lại
      if (enteredPoints * 1000 > remainingAfterCode) {
        double optimizedPoints = remainingAfterCode / 1000;
        discountFromPoints = optimizedPoints * 1000;
        pointsController.text = optimizedPoints.floor().toString();
      } else {
        discountFromPoints = enteredPoints * 1000;
      }

      double subtotalAfterDiscount =
          subtotal - discountFromPoints - discountFromCode;
      double vatAmount = subtotalAfterDiscount * vat;

      total = subtotalAfterDiscount + vatAmount + shippingFee;

      if (total < 0) total = 0;
    }

    setState(() {});
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
          pointsHint = "Bạn có $userPoints điểm (1 điểm = 1.000 đồng)";
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
      final orderData = {
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

      // Tạo document mới và lấy ID
      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData);
      final orderId = docRef.id;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đơn hàng đã được xác nhận")),
      );

      // Cập nhật điểm
      await updateUserPointsIfExists(orderId); // Pass orderId

      // Cập nhật mã giảm giá (nếu có nhập)
      String discountCode = discountCodeController.text.trim();
      if (discountCode.isNotEmpty) {
        await updateDiscountCode(discountCode, orderId);
      }

      // Gửi mail
      sendEmailViaEmailJS(
        emailController.text.trim(),
        nameController.text.trim(),
        {
          ...orderData,
          'orderId': orderId, // Gửi thêm mã đơn hàng qua mail
        },
      );

      // Xóa giỏ hàng
      await _removeOrderedProductsFromCart();

      // Navigate to home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ), // Replace MyHomePage() with your actual home page widget
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      print("Lỗi khi lưu đơn hàng: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã có lỗi xảy ra, vui lòng thử lại")),
      );
    }
  }

  Future<void> updateUserPointsIfExists(String orderId) async {
    // Add orderId
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
        double earnedPoints = (total * 10 / 100) / 1000; // 10% of total / 1000
        double usedPoints = double.tryParse(pointsController.text) ?? 0;
        double updatedPoints = currentPoints - usedPoints + earnedPoints;

        if (updatedPoints < 0) updatedPoints = 0;

        // Cập nhật lại điểm và lịch sử điểm
        await FirebaseFirestore.instance.collection('users').doc(doc.id).update(
          {
            'point': updatedPoints,
            'pointHistory': FieldValue.arrayUnion([
              // Store history
              {
                'orderId': orderId, // Store orderId
                'pointsEarned': earnedPoints,
                'pointsUsed': usedPoints,
                'timestamp': DateTime.now(),
                'totalOrderValue': total,
              },
            ]),
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cập nhật điểm thành công: $updatedPoints điểm"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Không tìm thấy người dùng với email này"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi cập nhật điểm: $e")));
    }
  }

  Future<void> updateDiscountCode(String discountCode, String orderId) async {
    try {
      DocumentReference discountRef = FirebaseFirestore.instance
          .collection('discounts')
          .doc(discountCode);

      DocumentSnapshot doc = await discountRef.get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        List<dynamic> listBill = data['listBill'] ?? [];

        if (!listBill.contains(orderId)) {
          listBill.add(orderId);

          await discountRef.update({'listBill': listBill});
        }
      }
    } catch (e) {
      print("Lỗi khi cập nhật mã giảm giá: $e");
    }
  }

  Future<void> _checkEmailAndCreateAccount() async {
    try {
      final email = emailController.text.trim();
      final password =
          phoneController.text.trim(); // Tạm dùng số điện thoại làm mật khẩu

      // Kiểm tra xem email đã tồn tại trong Firebase Auth chưa
      List<String> signInMethods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(email);

      if (signInMethods.isEmpty) {
        // Nếu chưa có tài khoản → tạo mới
        final authResult = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        if (authResult.user != null) {
          // Đăng nhập ngay sau khi tạo
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Lưu thông tin người dùng vào Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(authResult.user!.uid)
              .set({
                'email': email,
                'fullName': nameController.text.trim(),
                'phone': phoneController.text.trim(),
                'shippingAddress': addressController.text.trim(),
                'point': 0,
                'createdAt': Timestamp.now(),
              });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Tạo tài khoản thành công, mật khẩu là số điện thoại của bạn",
              ),
            ),
          );
        }
      } else {
        // Nếu email đã tồn tại, đăng nhập ngay
        final authResult = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        if (authResult.user != null) {
          // Lấy thông tin người dùng từ Firestore nếu cần
          DocumentSnapshot userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(authResult.user?.uid)
                  .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            // Bạn có thể làm gì đó với dữ liệu người dùng nếu cần
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đăng nhập thành công, tiếp tục đặt hàng"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đăng nhập thất bại, vui lòng kiểm tra thông tin"),
            ),
          );
        }
      }
    } catch (e) {
      print("Lỗi khi tạo hoặc đăng nhập tài khoản: $e");
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

  Future<bool> _validateDiscountCode() async {
    String discountCode = discountCodeController.text.trim();
    if (discountCode.isEmpty) return false;

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('discounts')
              .doc(discountCode)
              .get();

      if (doc.exists) {
        Map<String, dynamic> discountData = doc.data() as Map<String, dynamic>;

        DateTime? startDate;
        DateTime? expiryDate;

        if (discountData['startDate'] != null) {
          startDate = (discountData['startDate'] as Timestamp).toDate();
        }

        if (discountData['endDate'] != null) {
          expiryDate = (discountData['endDate'] as Timestamp).toDate();
        }

        int quantity =
            discountData['quantity'] - (discountData['listBill']?.length ?? 0);

        if (startDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ngày bắt đầu không hợp lệ")),
          );
          return false;
        }

        if (expiryDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ngày hết hạn không hợp lệ")),
          );
          return false;
        }

        if (DateTime.now().isBefore(startDate) ||
            DateTime.now().isAfter(expiryDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mã giảm giá không thể áp dụng")),
          );
          return false;
        }

        if (quantity <= 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Đã hết mã giảm giá")));
          return false;
        }

        double totalOrder = subtotal + shippingFee + vat;

        if (discountData['type'] == 'Khuyến mãi') {
          double calculatedDiscount = subtotal * discountData['value'] / 100;

          if (calculatedDiscount >= totalOrder) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Mức giảm vượt quá tổng đơn hàng")),
            );
            return false;
          }

          discountFromCode = calculatedDiscount;
          setState(() {});
          return true;
        } else if (discountData['type'] == 'Mặt hàng') {
          String productId = discountData['productId'];
          bool productFound = false;
          double productDiscount = 0;

          for (var product in widget.selectedProducts) {
            if (product.productId == productId) {
              productFound = true;
              productDiscount =
                  (product.price *
                      product.quantity *
                      (discountData['value'] ?? 0) /
                      100);
              break;
            }
          }

          if (productFound) {
            if (productDiscount >= totalOrder) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Không thể áp dụng mã giảm giá do vượt hạn mức",
                  ),
                ),
              );
              return false;
            }

            discountFromCode = productDiscount;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Giảm giá cho sản phẩm: ${widget.selectedProducts.firstWhere((p) => p.productId == productId).name}",
                ),
              ),
            );
            setState(() {});
            return true;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Mã giảm giá không thể áp dụng")),
            );
            return false;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mã giảm giá không hợp lệ")),
          );
          return false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy mã giảm giá")),
        );
        return false;
      }
    } catch (e) {
      print("Error validating discount code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xảy ra lỗi khi kiểm tra mã giảm giá")),
      );
      return false;
    }
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
                  const SnackBar(
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
            hintText: "Nhập mã giảm giá (ví dụ: IT50)",
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
        onStepContinue: () async {
          if (_currentStep == 0) {
            // Kiểm tra dữ liệu bước 1
            final email = emailController.text.trim();
            final name = nameController.text.trim();
            final address = addressController.text.trim();
            final phone = phoneController.text.trim();

            final emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
            final phoneValid = RegExp(r'^0\d{9}$').hasMatch(phone); // 0 + 9 số

            if (email.isEmpty ||
                name.isEmpty ||
                address.isEmpty ||
                phone.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
              );
              return;
            }

            if (!emailValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Email không hợp lệ")),
              );
              return;
            }

            if (!phoneValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Số điện thoại không hợp lệ (0XXXXXXXXX)"),
                ),
              );
              return;
            }

            setState(() {
              _currentStep++;
            });
          } else if (_currentStep == 1) {
            // Lấy điểm người dùng đã nhập
            double enteredPoints =
                double.tryParse(pointsController.text.trim()) ?? 0;

            // Tối ưu điểm: chỉ dùng phần cần thiết
            double maxUsablePoints = subtotal + shippingFee - discountFromCode;
            if (maxUsablePoints < 0) maxUsablePoints = 0;

            if (enteredPoints > userPoints) {
              enteredPoints = userPoints;
            }
            if (enteredPoints > maxUsablePoints) {
              enteredPoints = maxUsablePoints;
            }

            discountFromPoints = enteredPoints;

            // Cập nhật lại điểm đã tối ưu (nếu người dùng nhập quá mức cần thiết)
            pointsController.text = discountFromPoints.toStringAsFixed(0);

            // Kiểm tra mã giảm giá nếu có nhập
            if (discountCodeController.text.trim().isNotEmpty) {
              bool isValid = await _validateDiscountCode();

              if (!isValid) {
                return; // Dừng lại, không cho qua bước 3
              }
            }

            // Tính lại tổng
            _calculateOrderDetails();

            setState(() {
              _currentStep++;
            });
          } else {
            // Bước xác nhận đơn hàng
            await _processOrder();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          String continueText;
          switch (_currentStep) {
            case 0:
              continueText = "Tiếp theo";
              break;
            case 1:
              continueText = "Áp dụng";
              break;
            case 2:
              continueText = "Xác nhận";
              break;
            default:
              continueText = "Tiếp tục";
          }

          return Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: details.onStepContinue,
                child: Text(continueText),
              ),
              const SizedBox(width: 8),
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: details.onStepCancel,
                  child: const Text("Quay lại"),
                ),
            ],
          );
        },
        steps: [
          Step(
            title: const Text("Thông tin nhận hàng"),
            content: _buildStep1(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text("Sử dụng điểm & mã giảm giá"),
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
            _buildSummaryRow("VAT (8%)", moneyFormat(subtotal * vat)),
            const Divider(),
            _buildSummaryRow("Tổng cộng", moneyFormat(total), bold: true),
          ],
        ),
      ),
    );
  }
}
