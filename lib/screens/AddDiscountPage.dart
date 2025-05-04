import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_store/services/firebase/firestore_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AddDiscountPage extends StatefulWidget {
  const AddDiscountPage({super.key});

  @override
  State<AddDiscountPage> createState() => _AddDiscountPageState();
}

class _AddDiscountPageState extends State<AddDiscountPage> {
  final codeController = TextEditingController();
  final valueController = TextEditingController();
  final itemController = TextEditingController();
  final categoryController = TextEditingController();

  String selectedType = 'Khuyến mãi';
  String selectedValueType = 'Phần trăm';
  DateTime? expiryDate;

  final FirestoreService _firestoreService = FirestoreService();

  void _submit() async {
    // Kiểm tra các trường dữ liệu không được trống
    if (codeController.text.isEmpty) {
      _showMessage("Mã giảm giá không được trống.");
      return;
    }
    if (expiryDate == null) {
      _showMessage("Ngày hết hạn không được trống.");
      return;
    }

    // Kiểm tra xem mã giảm giá đã tồn tại trong Firestore hay chưa
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('discounts')
            .where('code', isEqualTo: codeController.text.trim())
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Nếu mã giảm giá đã tồn tại, hiển thị thông báo
      _showMessage("Mã giảm giá đã tồn tại, vui lòng chọn mã khác.");
      return;
    }

    // Kiểm tra giá trị giảm giá (Phần trăm hoặc Số tiền)
    double value = double.tryParse(valueController.text.trim()) ?? 0;
    if (selectedValueType == 'Phần trăm' && (value < 0 || value > 50)) {
      _showMessage("Giá trị phần trăm phải nằm trong khoảng từ 0 đến 50.");
      return;
    }

    Map<String, dynamic> discount = {
      'code': codeController.text.trim(),
      'expiry': expiryDate,
      'type': selectedType,
      'value': value,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Thêm các trường khác tuỳ vào loại giảm giá
    if (selectedType == 'Mặt hàng') {
      if (itemController.text.isEmpty) {
        _showMessage("Mã sản phẩm không được trống.");
        return;
      }
      discount['productId'] = itemController.text.trim();
    }

    try {
      // Gửi dữ liệu lên Firestore (collection: discounts)
      Map<String, dynamic> newDiscount = await _firestoreService
          .addWithCustomId('discounts', discount['code'], discount);

      print(newDiscount);
      _showMessage("Mã giảm giá đã được thêm thành công.", success: true);
    } catch (e) {
      print('Lỗi khi thêm mã giảm giá: $e');
      _showMessage('Thêm thất bại, vui lòng thử lại!');
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => expiryDate = picked);
    }
  }

  // Hàm hiển thị thông báo (SnackBar)
  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm mã giảm giá")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // Mã giảm giá và Ngày hết hạn
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: "Mã giảm giá",
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        title: Text(
                          expiryDate == null
                              ? "Chọn ngày hết hạn"
                              : "Hết hạn: ${DateFormat('dd/MM/yyyy').format(expiryDate!)}",
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _pickExpiryDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Loại giảm giá
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: "Loại giảm giá"),
                  items:
                      const ['Khuyến mãi', 'Mặt hàng'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                      valueController.clear();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Giá trị giảm
                TextFormField(
                  controller: valueController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(labelText: "Giảm (%)"),
                ),
                const SizedBox(height: 20),

                // Thêm trường cho mặt hàng và nhóm hàng nếu cần
                if (selectedType == 'Mặt hàng')
                  TextField(
                    controller: itemController,
                    decoration: const InputDecoration(labelText: "Mã sản phẩm"),
                  ),
                // Gửi mã giảm giá
                ElevatedButton(onPressed: _submit, child: const Text("Gửi")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
