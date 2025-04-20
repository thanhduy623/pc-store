import 'package:flutter/material.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<Map<String, dynamic>> orders = [
    {
      'orderCode': 'ORD123',
      'address': '1234 Elm Street, District 1, HCM City',
      'totalAmount': 500000,
      'orderDate': '2025-04-01',
      'status': 'Pending',
    },
    {
      'orderCode': 'ORD124',
      'address': '4567 Oak Avenue, District 2, HCM City',
      'totalAmount': 200000,
      'orderDate': '2025-04-02',
      'status': 'Confirmed',
    },
    {
      'orderCode': 'ORD125',
      'address': '7890 Pine Road, District 3, HCM City',
      'totalAmount': 750000,
      'orderDate': '2025-04-03',
      'status': 'Shipping',
    },
    {
      'orderCode': 'ORD126',
      'address': '1357 Maple Boulevard, District 4, HCM City',
      'totalAmount': 400000,
      'orderDate': '2025-04-04',
      'status': 'Delivered',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách đơn hàng')),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Chờ xử lý'),
                Tab(text: 'Đã xác nhận'),
                Tab(text: 'Đang vận chuyển'),
                Tab(text: 'Đã giao'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Pending Orders Tab
                  _buildOrderList('Pending'),
                  // Confirmed Orders Tab
                  _buildOrderList('Confirmed'),
                  // Shipping Orders Tab
                  _buildOrderList('Shipping'),
                  // Delivered Orders Tab
                  _buildOrderList('Delivered'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(String status) {
    // Filter orders by status
    final filteredOrders =
        orders.where((order) => order['status'] == status).toList();

    if (filteredOrders.isEmpty) {
      return const Center(
        child: Text('Không có đơn hàng nào trong trạng thái này'),
      );
    }

    return ListView.builder(
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
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
                  'Nơi nhận: ${order['address']}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng tiền: ${moneyFormat(order['totalAmount'])}',
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngày đặt: ${order['orderDate']}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trạng thái: ${order['status']}',
                  style: TextStyle(
                    fontSize: 14,
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
