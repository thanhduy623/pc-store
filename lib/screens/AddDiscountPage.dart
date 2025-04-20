import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddDiscountPage extends StatefulWidget {
  const AddDiscountPage({super.key});

  @override
  State<AddDiscountPage> createState() => _AddDiscountPageState();
}

class _AddDiscountPageState extends State<AddDiscountPage> {
  final codeController = TextEditingController();
  final valueController = TextEditingController();
  final itemController = TextEditingController(); // For Mặt hàng
  final categoryController = TextEditingController(); // For Nhóm hàng

  String selectedType = 'Phần trăm';
  DateTime? expiryDate;

  void _submit() {
    if (codeController.text.isEmpty || expiryDate == null) return;

    final discount = {
      'code': codeController.text.trim(),
      'type': selectedType,
      'value': valueController.text.trim(),
      'item': itemController.text.trim(),
      'category': categoryController.text.trim(),
      'expiry': DateFormat('yyyy-MM-dd').format(expiryDate!),
    };

    // Gửi lên Firebase Firestore
    // FirebaseFirestore.instance.collection('discounts').add(discount);

    Navigator.pop(context, discount);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm mã giảm giá")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: "Mã giảm giá"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: "Loại giảm giá"),
              items:
                  const ['Phần trăm', 'Cụ thể', 'Mặt hàng', 'Nhóm hàng'].map((
                    type,
                  ) {
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
            if (selectedType == 'Phần trăm') ...[
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Giảm (%)"),
              ),
            ] else if (selectedType == 'Cụ thể') ...[
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Số tiền giảm (VNĐ)",
                ),
              ),
            ] else if (selectedType == 'Mặt hàng') ...[
              TextField(
                controller: itemController,
                decoration: const InputDecoration(labelText: "Tên sản phẩm"),
              ),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Giảm (%) hoặc số tiền",
                ),
              ),
            ] else if (selectedType == 'Nhóm hàng') ...[
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: "Phân loại/Nhóm hàng",
                ),
              ),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Giảm (%) hoặc số tiền",
                ),
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                expiryDate == null
                    ? "Chọn ngày hết hạn"
                    : "Hết hạn: ${DateFormat('dd/MM/yyyy').format(expiryDate!)}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickExpiryDate,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: const Text("Gửi")),
          ],
        ),
      ),
    );
  }
}
