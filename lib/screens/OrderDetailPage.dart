import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final statusMap = order['status'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('THÔNG TIN NGƯỜI NHẬN'),
                _buildOrderDetailRow('Họ tên:', order['fullName']),
                _buildOrderDetailRow('Email:', order['email']),
                _buildOrderDetailRow('SĐT:', order['phoneNumber']),
                _buildOrderDetailRow('Địa chỉ:', order['shippingAddress']),
                const SizedBox(height: 16),

                _buildSectionTitle('THÔNG TIN ĐƠN HÀNG'),
                _buildOrderDetailRow('Mã đơn hàng:', order['orderCode']),
                _buildOrderDetailRow(
                  'Ngày đặt:',
                  (order['orderDate'] is Timestamp)
                      ? DateFormat(
                        'yyyy-MM-dd',
                      ).format((order['orderDate'] as Timestamp).toDate())
                      : order['orderDate'].toString(),
                ),
                const SizedBox(height: 16),

                _buildSectionTitle('LỊCH SỬ TRẠNG THÁI'),
                _buildEqualWidthTimeline(statusMap),
                const SizedBox(height: 16),

                _buildSectionTitle('SẢN PHẨM ĐÃ ĐẶT'),
                _buildItemTable(items),
                const SizedBox(height: 16),

                _buildSectionTitle('CHI TIẾT THANH TOÁN'),
                _buildOrderDetailRow(
                  'Tạm tính:',
                  moneyFormat(order['subtotal']),
                ),
                _buildOrderDetailRow(
                  'Phí vận chuyển:',
                  moneyFormat(order['shippingFee']),
                ),
                _buildOrderDetailRow('VAT:', moneyFormat(order['vat'])),
                _buildOrderDetailRow(
                  'Giảm giá (mã):',
                  '- ${moneyFormat(order['discountFromCode'])}',
                ),
                _buildOrderDetailRow(
                  'Giảm giá (điểm):',
                  '- ${moneyFormat(order['discountFromPoints'])}',
                ),
                _buildOrderDetailRow('Tổng cộng:', moneyFormat(order['total'])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildOrderDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label)),
          Flexible(
            child: Text(
              value?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualWidthTimeline(Map<String, dynamic>? statusMap) {
    if (statusMap == null || statusMap.isEmpty) {
      return const Text('Không có thông tin trạng thái');
    }

    final sortedEntries =
        statusMap.entries.toList()..sort((a, b) {
          final aTime =
              a.value is Timestamp
                  ? a.value.toDate()
                  : DateTime.tryParse(a.value.toString());
          final bTime =
              b.value is Timestamp
                  ? b.value.toDate()
                  : DateTime.tryParse(b.value.toString());
          return aTime?.compareTo(bTime ?? DateTime(1970)) ?? 0;
        });

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemCount = sortedEntries.length;
        final itemWidth = width / itemCount;

        return Row(
          children:
              sortedEntries.map((entry) {
                final status = entry.key;
                final timestamp =
                    entry.value is Timestamp
                        ? (entry.value as Timestamp).toDate()
                        : DateTime.tryParse(entry.value.toString()) ??
                            DateTime(1970);

                return SizedBox(
                  width: itemWidth,
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getStatusName(status),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd/MM HH:mm').format(timestamp),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildItemTable(List<Map<String, dynamic>> items) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(4), // Tên sản phẩm
        1: FlexColumnWidth(1), // Số lượng
        2: FlexColumnWidth(2), // Đơn giá
        3: FlexColumnWidth(3), // Thành tiền
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Sản phẩm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Đơn giá',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Thành tiền',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ...items.map((item) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item['productName'] ?? ''),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${item['quantity']}'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(moneyFormat(item['unitPrice'])),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(moneyFormat(item['totalPrice'])),
              ),
            ],
          );
        }),
      ],
    );
  }

  String moneyFormat(dynamic amount) {
    final number = (amount is num) ? amount : 0;
    return '${NumberFormat("#,###", "vi_VN").format(number)}đ';
  }

  String getStatusName(String statusKey) {
    switch (statusKey) {
      case 'Pending':
      case 'Chờ xử lý':
        return 'Chờ xử lý';
      case 'Confirmed':
      case 'Đã xác nhận':
        return 'Đã xác nhận';
      case 'Shipping':
      case 'Đang giao hàng':
        return 'Đang giao hàng';
      case 'Delivered':
      case 'Đã giao':
        return 'Đã giao';
      default:
        return statusKey;
    }
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
      case 'Chờ xử lý':
        return Icons.hourglass_empty;
      case 'Confirmed':
      case 'Đã xác nhận':
        return Icons.check_circle_outline;
      case 'Shipping':
      case 'Đang giao hàng':
        return Icons.local_shipping;
      case 'Delivered':
      case 'Đã giao':
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }
}
