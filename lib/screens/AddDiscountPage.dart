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
  final quantityController = TextEditingController();
  final valueController = TextEditingController();
  final itemController = TextEditingController();

  String selectedType = 'Khuyến mãi';
  DateTime? startDate;
  DateTime? endDate;

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _submit() async {
    final code = codeController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
    final value = double.tryParse(valueController.text.trim()) ?? 0;
    final productId = itemController.text.trim();

    // Validate fields
    if (code.isEmpty || code.length != 5) {
      _showMessage("Mã giảm giá phải gồm 5 ký tự.");
      return;
    }
    if (quantity <= 0) {
      _showMessage("Số lượng phải lớn hơn 0.");
      return;
    }
    if (startDate == null || startDate!.difference(DateTime.now()).inDays < 0) {
      _showMessage("Ngày bắt đầu phải từ hôm nay trở đi.");
      return;
    }

    if (endDate == null || endDate!.difference(startDate!).inDays < 0) {
      _showMessage("Ngày kết thúc phải sau hoặc bằng ngày bắt đầu.");
      return;
    }

    if (value <= 0 || value > 50) {
      _showMessage("Giá trị giảm phải lớn hơn 0 và không quá 50.");
      return;
    }

    // Check if code already exists
    final existing =
        await FirebaseFirestore.instance
            .collection('discounts')
            .doc(code)
            .get();
    if (existing.exists) {
      _showMessage("Mã giảm giá đã tồn tại.");
      return;
    }

    Map<String, dynamic> discount = {
      'code': code,
      'quantity': quantity,
      'value': value,
      'type': selectedType,
      'startDate': Timestamp.fromDate(startDate!),
      'endDate': Timestamp.fromDate(endDate!),
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (selectedType == 'Mặt hàng') {
      if (productId.isEmpty) {
        _showMessage("Mã sản phẩm không được bỏ trống.");
        return;
      }

      // Kiểm tra mã sản phẩm
      final productDoc =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

      if (!productDoc.exists) {
        _showMessage("Mã sản phẩm không tồn tại.");
        return;
      }

      discount['productId'] = productId;
    }

    // Gửi lên Firestore
    try {
      await _firestoreService.addWithCustomId('discounts', code, discount);
      _showMessage("Thêm mã giảm giá thành công.", success: true);
      Navigator.pop(context, discount);
    } catch (e) {
      print(e);
      _showMessage("Thêm thất bại.");
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

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
    final inputDecoration = InputDecoration(
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Thêm mã giảm giá")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: codeController,
                        maxLength: 5,
                        decoration: inputDecoration.copyWith(
                          labelText: "Mã giảm giá (5 ký tự)",
                          counter: const SizedBox.shrink(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration.copyWith(
                          labelText: "Số lượng mã",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickStartDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: inputDecoration.copyWith(
                              labelText: "Ngày bắt đầu",
                              hintText: "dd/MM/yyyy",
                            ),
                            controller: TextEditingController(
                              text:
                                  startDate == null
                                      ? ''
                                      : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(startDate!),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickEndDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: inputDecoration.copyWith(
                              labelText: "Ngày kết thúc",
                              hintText: "dd/MM/yyyy",
                            ),
                            controller: TextEditingController(
                              text:
                                  endDate == null
                                      ? ''
                                      : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(endDate!),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: inputDecoration.copyWith(
                    labelText: "Loại khuyến mãi",
                  ),
                  items:
                      ['Khuyến mãi', 'Mặt hàng']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
                if (selectedType == 'Mặt hàng') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: itemController,
                    decoration: inputDecoration.copyWith(
                      labelText: "Mã sản phẩm",
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: inputDecoration.copyWith(labelText: "Giảm (%)"),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text("Tạo mã giảm giá"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
