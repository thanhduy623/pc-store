import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_store/screens/OrderDetailPage.dart';
import 'package:my_store/utils/moneyFormat.dart' as util;

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
                      ? data['orderDate'].toDate()
                      : DateTime.tryParse(data['orderDate'].toString()) ??
                          DateTime.now();

              final statusMap = data['status'] as Map<String, dynamic>?;
              String latestStatus = _getLatestStatus(statusMap);
              String statusUpdateDate = _getLatestStatusTime(statusMap);

              final items =
                  (data['items'] as List<dynamic>?)
                      ?.map(
                        (item) => {
                          'productName': item['productName'],
                          'quantity': item['quantity'],
                          'unitPrice': item['unitPrice'],
                          'totalPrice': item['totalPrice'],
                          'productId': item['productId'],
                        },
                      )
                      .toList() ??
                  [];

              return {
                'id': doc.id,
                'orderCode': doc.id,
                'orderDate': orderDate.toString().split(' ')[0],
                'status': statusMap,
                'statusKey': latestStatus,
                'statusUpdateDate': statusUpdateDate,
                'total': data['total'] ?? 0,
                'subtotal': data['subtotal'] ?? 0,
                'shippingFee': data['shippingFee'] ?? 0,
                'vat': data['vat'] ?? 0,
                'discountFromCode': data['discountFromCode'] ?? 0,
                'discountFromPoints': data['discountFromPoints'] ?? 0,
                'email': data['email'] ?? '',
                'phoneNumber': data['phoneNumber'] ?? '',
                'fullName': data['fullName'] ?? '',
                'shippingAddress': data['shippingAddress'] ?? '',
                'items': items,
              };
            }).toList();

        orders.sort((a, b) {
          final dateA = DateTime.parse(a['orderDate'] as String);
          final dateB = DateTime.parse(b['orderDate'] as String);
          return dateB.compareTo(dateA);
        });
      });
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  String _getLatestStatus(Map<String, dynamic>? statusMap) {
    if (statusMap == null || statusMap.isEmpty) return 'Unknown';
    DateTime latest = DateTime(1970);
    String latestStatus = 'Unknown';
    statusMap.forEach((key, value) {
      if (value is Timestamp) {
        DateTime t = value.toDate();
        if (t.isAfter(latest)) {
          latest = t;
          latestStatus = key;
        }
      }
    });
    return latestStatus;
  }

  String _getLatestStatusTime(Map<String, dynamic>? statusMap) {
    if (statusMap == null || statusMap.isEmpty) return '';
    DateTime latest = DateTime(1970);
    statusMap.forEach((_, value) {
      if (value is Timestamp) {
        DateTime t = value.toDate();
        if (t.isAfter(latest)) latest = t;
      }
    });
    return latest.toString();
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
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailPage(order: order),
              ),
            );
          },
          child: Card(
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
                  Text('Ngày đặt: ${order['orderDate']}'),
                  const SizedBox(height: 8),
                  Text(
                    'Tổng tiền: ${util.moneyFormat(order['total'])} (${order['items'].length} sản phẩm)',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trạng thái: ${order['statusKey']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order['statusKey']),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
      case 'Chờ xử lý':
        return Colors.orange;
      case 'Confirmed':
      case 'Đã xác nhận':
        return Colors.blue;
      case 'Shipping':
      case 'Đang giao hàng':
        return Colors.blueAccent;
      case 'Delivered':
      case 'Đã giao':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
