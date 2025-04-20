import 'package:flutter/material.dart';
import 'package:my_store/utils/location_service.dart';
import 'package:my_store/utils/moneyFormat.dart';
import 'package:my_store/models/cart_item.dart';

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
  final detailAddressController = TextEditingController();

  Map<String, dynamic>? selectedProvince;
  Map<String, dynamic>? selectedDistrict;
  Map<String, dynamic>? selectedWard;

  List<Map<String, dynamic>> provinceList = [];
  List<Map<String, dynamic>> districtList = [];
  List<Map<String, dynamic>> wardList = [];

  int userPoints = 100;
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
  }

  void _loadProvinces() async {
    try {
      final provinces = await LocationService.fetchProvinces();
      setState(() {
        provinceList = provinces;
      });
    } catch (e) {
      print("Lỗi khi tải tỉnh/thành: $e");
    }
  }

  void _loadDistricts(int provinceCode) async {
    try {
      final districts = await LocationService.fetchDistricts(provinceCode);
      setState(() {
        districtList = districts;
      });
    } catch (e) {
      print("Lỗi khi tải quận/huyện: $e");
    }
  }

  void _loadWards(int districtCode) async {
    try {
      final wards = await LocationService.fetchWards(districtCode);
      setState(() {
        wardList = wards;
      });
    } catch (e) {
      print("Lỗi khi tải xã/phường: $e");
    }
  }

  void _submitOrder() {
    print("Đã xác nhận đơn hàng");
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
                if (_currentStep < 2) {
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
        TextField(
          controller: detailAddressController,
          decoration: const InputDecoration(labelText: "Địa chỉ chi tiết"),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Map<String, dynamic>>(
          decoration: const InputDecoration(labelText: "Tỉnh / Thành phố"),
          value: selectedProvince,
          items:
              provinceList
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p['name'] ?? ''),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              selectedProvince = value;
              selectedDistrict = null;
              selectedWard = null;
              districtList.clear();
              wardList.clear();
            });
            if (value != null) {
              _loadDistricts(value['code']);
            }
          },
        ),
        DropdownButtonFormField<Map<String, dynamic>>(
          decoration: const InputDecoration(labelText: "Quận / Huyện"),
          value: selectedDistrict,
          items:
              districtList
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(d['name'] ?? ''),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              selectedDistrict = value;
              selectedWard = null;
              wardList.clear();
            });
            if (value != null) {
              _loadWards(value['code']);
            }
          },
        ),
        DropdownButtonFormField<Map<String, dynamic>>(
          decoration: const InputDecoration(labelText: "Xã / Phường"),
          value: selectedWard,
          items:
              wardList
                  .map(
                    (w) => DropdownMenuItem(
                      value: w,
                      child: Text(w['name'] ?? ''),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              selectedWard = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bạn có $userPoints điểm tích lũy."),
        Text("Mỗi điểm giảm 1.000đ."),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Số điểm muốn dùng",
                ),
                onChanged: (value) {
                  final entered = int.tryParse(value) ?? 0;
                  setState(() {
                    pointsToUse = (entered > userPoints) ? userPoints : entered;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "-${moneyFormat(discountFromPoints)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text("🔸 Nhập mã giảm giá:"),
        TextField(
          decoration: const InputDecoration(
            labelText: "Mã giảm giá",
            hintText: "VD: GIAM50",
          ),
          onChanged: (value) {
            setState(() {
              discountCode = value;
              discountFromCode = 20000; // Ví dụ: xử lý thực tế sẽ gọi API
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.selectedItems.map(
          (item) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(item.name),
            trailing: Text("${item.quantity} x ${moneyFormat(item.price)}"),
          ),
        ),
        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            value,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}
