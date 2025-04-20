import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient Information Section
            _buildSectionTitle('Thông tin người nhận'),
            _buildOrderDetailRow('Mã đơn hàng:', order['orderCode']),
            _buildOrderDetailRow('Nơi nhận:', order['address']),
            const SizedBox(height: 20),

            // Order Information Section
            _buildSectionTitle('Thông tin đơn hàng'),
            _buildOrderDetailRow(
              'Tổng tiền:',
              moneyFormat(order['totalAmount']),
            ),
            _buildOrderDetailRow('Ngày đặt:', order['orderDate']),
            const SizedBox(height: 20),

            // Order Status Section
            _buildSectionTitle('Thông tin trạng thái'),
            _buildOrderStatusRow(
              'Trạng thái:',
              order['status'],
              order['status'],
            ),
            _buildOrderDetailRow(
              'Ngày giờ cập nhật:',
              '${order['statusUpdateDate']}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOrderStatusRow(String label, String status, String statusType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(statusType),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _getStatusIcon(statusType),
                color: _getStatusColor(statusType),
              ),
            ],
          ),
        ],
      ),
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

  // Helper method to get an icon based on order status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Confirmed':
        return Icons.check_circle_outline;
      case 'Shipping':
        return Icons.local_shipping;
      case 'Delivered':
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }
}

// This is the entry point for running the OrderDetailPage directly
void main() {
  runApp(
    MaterialApp(
      home: OrderDetailPage(
        order: {
          'orderCode': 'ORD123',
          'address': '1234 Elm Street, District 1, HCM City',
          'totalAmount': 500000,
          'orderDate': '2025-04-01',
          'status': 'Pending',
          'statusUpdateDate': '2025-04-01 14:30:00',
        },
      ),
    ),
  );
}
