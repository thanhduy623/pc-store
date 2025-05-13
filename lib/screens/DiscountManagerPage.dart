import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AddDiscountPage.dart';
import 'package:intl/intl.dart';
import 'OrderDetailPage.dart'; // Import OrderDetailPage

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
              .orderBy('createdAt') // Sắp xếp theo ngày hết hạn
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

  // Hàm định dạng ngày
  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
    return 'Không rõ';
  }

  // Hàm điều hướng đến trang chi tiết đơn hàng
  void _navigateToOrderDetail(String codeBill) async {
    // Tải thông tin chi tiết đơn hàng từ Firestore
    final orderDoc =
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(codeBill)
            .get();

    if (orderDoc.exists) {
      final orderData = orderDoc.data() as Map<String, dynamic>;
      // Điều hướng tới trang chi tiết đơn hàng
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailPage(order: orderData)),
      );
    }
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
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    mainAxisExtent: 150,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: discounts.length,
                  itemBuilder: (context, index) {
                    final item = discounts[index];
                    final listBill = List<String>.from(item['listBill'] ?? []);
                    final listBillLength = listBill.length;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          // Khi nhấn vào Card, hiển thị danh sách mã đơn hàng
                          if (listBill.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Danh sách đơn hàng"),
                                  content: SizedBox(
                                    width: 300,
                                    height: 200,
                                    child: ListView.builder(
                                      itemCount: listBill.length,
                                      itemBuilder: (context, i) {
                                        return ListTile(
                                          title: Text(listBill[i]),
                                          onTap:
                                              () => _navigateToOrderDetail(
                                                listBill[i],
                                              ), // Điều hướng đến chi tiết đơn hàng
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Đóng"),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      item['code'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _deleteDiscount(item['code']),
                                    iconSize: 18,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Ngày bắt đầu: ${_formatDate(item['startDate'])}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "Hết hạn: ${_formatDate(item['endDate'])}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "Loại: ${item['type']}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "Giá trị: ${item['value']}%",
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "Số lượng: ${item['quantity'] - listBillLength} / ${item['quantity']}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        tooltip: 'Thêm mã giảm giá',
        child: const Icon(Icons.add),
      ),
    );
  }
}
