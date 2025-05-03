import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final userId = FirebaseAuth.instance.currentUser?.email;
    if (userId == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('email', isEqualTo: userId)
              .get();

      setState(() {
        orders =
            snapshot.docs.map((doc) {
              final data = doc.data();
              final orderDate =
                  data['orderDate'] is Timestamp
                      ? data['orderDate'].toDate().toString().split(' ')[0]
                      : data['orderDate'].toString();

              // Lấy thông tin chi tiết từ 'items' trong đơn hàng
              final items =
                  (data['items'] as List<dynamic>?)?.map((item) {
                    return {
                      'productName': item['productName'],
                      'quantity': item['quantity'],
                    };
                  }).toList() ??
                  [];

              return {
                'id': doc.id, // Mã đơn hàng là mã của document
                'orderCode': doc.id, // Mã đơn hàng hiển thị là ID của document
                'orderDate': orderDate,
                'status': _getLatestStatus(data['status']),
                'totalAmount': data['total']?.toDouble() ?? 0.0, // Tổng tiền
                'items': items,
              };
            }).toList();
      });
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  String _getLatestStatus(Map<String, dynamic> status) {
    if (status == null || status.isEmpty) return 'Unknown';

    // Duyệt qua tất cả trạng thái và chọn trạng thái có Timestamp mới nhất
    DateTime latestTimestamp = DateTime(1970); // Khởi tạo thời gian cũ nhất
    String latestStatus = 'Unknown';

    status.forEach((key, value) {
      if (value is Timestamp) {
        DateTime statusTime = value.toDate();
        if (statusTime.isAfter(latestTimestamp)) {
          latestTimestamp = statusTime;
          latestStatus = key; // Cập nhật trạng thái mới nhất
        }
      }
    });

    return latestStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách đơn hàng')),
      body: _buildOrderList(),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã đơn hàng: ${order['orderCode']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngày đặt: ${order['orderDate']}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng số tiền: ' +
                      Text(
                        moneyFormat(order['totalAmount']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ), // In đậm số tiền
                      ).data! +
                      ' (${order['items'].length} Sản phẩm)',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trạng thái: ${order['status']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // In đậm trạng thái
                    color: _getStatusColor(order['status']),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to format currency
  String moneyFormat(double amount) {
    return '${amount.toStringAsFixed(0)}đ';
  }

  // Helper method to determine the color based on order status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Shipping':
        return Colors.blueAccent;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
