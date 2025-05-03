import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AddDiscountPage.dart';
import 'package:intl/intl.dart';

class DiscountManagerPage extends StatefulWidget {
  const DiscountManagerPage({super.key});

  @override
  State<DiscountManagerPage> createState() => _DiscountManagerPageState();
}

class _DiscountManagerPageState extends State<DiscountManagerPage> {
  // Danh sách mã giảm giá lấy từ Firestore
  List<Map<String, dynamic>> discounts = [];

  @override
  void initState() {
    super.initState();
    _loadDiscounts();
  }

  // Hàm tải danh sách mã giảm giá từ Firestore
  void _loadDiscounts() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('discounts')
              .orderBy('expiry') // Sắp xếp theo ngày hết hạn
              .get();

      setState(() {
        discounts =
            snapshot.docs.map((doc) {
              return doc.data() as Map<String, dynamic>;
            }).toList();
      });
    } catch (e) {
      print("Lỗi khi tải dữ liệu mã giảm giá: $e");
    }
  }

  // Hàm xóa mã giảm giá
  void _deleteDiscount(String discountCode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Xác nhận xóa"),
          content: const Text("Bạn có chắc chắn muốn xóa mã giảm giá này?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Hủy"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Xóa mã giảm giá từ Firestore
                  await FirebaseFirestore.instance
                      .collection('discounts')
                      .doc(discountCode)
                      .delete();

                  // Cập nhật lại danh sách
                  setState(() {
                    discounts.removeWhere(
                      (discount) => discount['code'] == discountCode,
                    );
                  });
                } catch (e) {
                  print("Lỗi khi xóa mã giảm giá: $e");
                }
                Navigator.of(context).pop();
              },
              child: const Text("Xóa"),
            ),
          ],
        );
      },
    );
  }

  // Hàm điều hướng đến trang thêm mã giảm giá
  void _navigateToAdd() async {
    final newDiscount = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDiscountPage()),
    );

    if (newDiscount != null) {
      setState(() {
        discounts.add(newDiscount);
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
    return 'Không rõ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý mã giảm giá')),
      body:
          discounts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  itemCount: discounts.length,
                  itemBuilder: (context, index) {
                    final item = discounts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 5,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          item['code'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Loại: ${item['type']}"),
                            Text(
                              "Giá trị: ${item['value']}${item['valueType'] == 'Phần trăm' ? '%' : 'đ'}",
                            ),
                            Text(
                              "Ngày hết hạn: ${_formatDate(item['expiry'])}",
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDiscount(item['code']),
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
        tooltip: 'Thêm mã mới',
      ),
    );
  }
}
