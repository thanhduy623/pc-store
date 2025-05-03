import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final snapshot =
        await FirebaseFirestore.instance.collection('orders').get();

    setState(() {
      orders =
          snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'status': doc['status'],
              'total': doc['total'],
              'shippingAddress': doc['shippingAddress'],
              'orderDate': doc['orderDate'],
            };
          }).toList();
    });
  }

  Future<void> updateOrderStatus(
    String orderId,
    String currentStatus, {
    bool isCancel = false,
  }) async {
    final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId);
    final currentOrder = orders.firstWhere((order) => order['id'] == orderId);
    final statusMap = Map<String, dynamic>.from(currentOrder['status']);

    if (statusMap.containsKey('Đã huỷ') && !isCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đơn hàng này đã bị huỷ, không thể cập nhật trạng thái.',
          ),
        ),
      );
      return;
    }

    final nextStatus = isCancel ? 'Đã huỷ' : _getNextStatus(currentStatus);

    if (nextStatus != null) {
      await orderRef.update({
        'status': {...statusMap, nextStatus: Timestamp.now()},
      });
      await loadOrders(); // Load lại danh sách sau khi cập nhật
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trạng thái không hợp lệ hoặc không thể lùi lại.'),
        ),
      );
    }
  }

  String? _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'Chờ xử lý':
        return 'Đã xác nhận';
      case 'Đã xác nhận':
        return 'Đang vận chuyển';
      case 'Đang vận chuyển':
        return 'Đã giao';
      default:
        return null;
    }
  }

  String getLatestStatus(Map<String, dynamic> statusMap) {
    String latestStatus = '';
    Timestamp latestTime = Timestamp(0, 0);

    statusMap.forEach((status, timestamp) {
      if (timestamp is Timestamp && timestamp.compareTo(latestTime) > 0) {
        latestStatus = status;
        latestTime = timestamp;
      }
    });

    return latestStatus;
  }

  String _getFirestoreStatusName(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ xử lý';
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Shipping':
        return 'Đang vận chuyển';
      case 'Delivered':
        return 'Đã giao';
      case 'Canceled':
        return 'Đã huỷ';
      default:
        return '';
    }
  }

  String moneyFormat(double amount) {
    return '${amount.toStringAsFixed(0)}đ';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xử lý':
        return Colors.orange;
      case 'Đã xác nhận':
        return Colors.blue;
      case 'Đang vận chuyển':
        return Colors.blueAccent;
      case 'Đã giao':
        return Colors.green;
      case 'Đã huỷ':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách đơn hàng')),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Chờ xử lý'),
                Tab(text: 'Đã xác nhận'),
                Tab(text: 'Đang vận chuyển'),
                Tab(text: 'Đã giao'),
                Tab(text: 'Đã huỷ'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  OrderListTab(
                    status: 'Pending',
                    orders: orders,
                    getLatestStatus: getLatestStatus,
                    moneyFormat: moneyFormat,
                    getStatusColor: _getStatusColor,
                    updateOrderStatus: updateOrderStatus,
                    getStatusLabel: _getFirestoreStatusName,
                  ),
                  OrderListTab(
                    status: 'Confirmed',
                    orders: orders,
                    getLatestStatus: getLatestStatus,
                    moneyFormat: moneyFormat,
                    getStatusColor: _getStatusColor,
                    updateOrderStatus: updateOrderStatus,
                    getStatusLabel: _getFirestoreStatusName,
                  ),
                  OrderListTab(
                    status: 'Shipping',
                    orders: orders,
                    getLatestStatus: getLatestStatus,
                    moneyFormat: moneyFormat,
                    getStatusColor: _getStatusColor,
                    updateOrderStatus: updateOrderStatus,
                    getStatusLabel: _getFirestoreStatusName,
                  ),
                  OrderListTab(
                    status: 'Delivered',
                    orders: orders,
                    getLatestStatus: getLatestStatus,
                    moneyFormat: moneyFormat,
                    getStatusColor: _getStatusColor,
                    updateOrderStatus: updateOrderStatus,
                    getStatusLabel: _getFirestoreStatusName,
                  ),
                  OrderListTab(
                    status: 'Canceled',
                    orders: orders,
                    getLatestStatus: getLatestStatus,
                    moneyFormat: moneyFormat,
                    getStatusColor: _getStatusColor,
                    updateOrderStatus: updateOrderStatus,
                    getStatusLabel: _getFirestoreStatusName,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderListTab extends StatefulWidget {
  final String status;
  final List<Map<String, dynamic>> orders;
  final String Function(Map<String, dynamic>) getLatestStatus;
  final String Function(double) moneyFormat;
  final Color Function(String) getStatusColor;
  final void Function(String, String, {bool isCancel}) updateOrderStatus;
  final String Function(String) getStatusLabel;

  const OrderListTab({
    super.key,
    required this.status,
    required this.orders,
    required this.getLatestStatus,
    required this.moneyFormat,
    required this.getStatusColor,
    required this.updateOrderStatus,
    required this.getStatusLabel,
  });

  @override
  State<OrderListTab> createState() => _OrderListTabState();
}

class _OrderListTabState extends State<OrderListTab> {
  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.getStatusLabel(widget.status);
    final filteredOrders =
        widget.orders.where((order) {
          final statusMap = Map<String, dynamic>.from(order['status']);
          final latest = widget.getLatestStatus(statusMap);
          return latest == currentStatus;
        }).toList();

    if (filteredOrders.isEmpty) {
      return const Center(
        child: Text('Không có đơn hàng nào trong trạng thái này'),
      );
    }

    return ListView.builder(
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final statusMap = Map<String, dynamic>.from(order['status']);
        final latestStatus = widget.getLatestStatus(statusMap);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã đơn hàng: ${order['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Nơi nhận: ${order['shippingAddress']}'),
                const SizedBox(height: 8),
                Text(
                  'Ngày đặt: ${order['orderDate'].toDate().toString().split(' ')[0]}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng tiền: ${widget.moneyFormat(order['total'])}',
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trạng thái: $latestStatus',
                  style: TextStyle(color: widget.getStatusColor(latestStatus)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (latestStatus != 'Đã huỷ' && latestStatus != 'Đã giao')
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed:
                            () => widget.updateOrderStatus(
                              order['id'],
                              latestStatus,
                            ),
                      ),
                    if (latestStatus != 'Đã huỷ' && latestStatus != 'Đã giao')
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed:
                            () => widget.updateOrderStatus(
                              order['id'],
                              latestStatus,
                              isCancel: true,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
