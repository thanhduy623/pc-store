import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'OrderDetailPage.dart';
import 'package:intl/intl.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> orders = [];
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMore = true;

  DateTime? filterStartDate;
  DateTime? filterEndDate;

  @override
  void initState() {
    super.initState();
    loadOrders();

    // Lắng nghe khi người dùng cuộn đến gần cuối danh sách để tải thêm dữ liệu.
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoading &&
          hasMore) {
        loadOrders();
      }
    });
  }

  Future<void> loadOrders({bool reset = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    if (reset) {
      setState(() {
        orders = [];
        lastDocument = null;
        hasMore = true; // Đặt lại trạng thái không còn dữ liệu
      });
    }

    Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(20);

    // Áp dụng bộ lọc nếu có
    if (filterStartDate != null && filterEndDate != null) {
      query = query
          .where(
            'orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(filterStartDate!),
          )
          .where(
            'orderDate',
            isLessThanOrEqualTo: Timestamp.fromDate(filterEndDate!),
          );
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      final newOrders =
          snapshot.docs.map((doc) {
            // Lấy toàn bộ dữ liệu của document
            final data = doc.data() as Map<String, dynamic>;

            return {
              'id': doc.id,
              ...data, // Sử dụng spread operator để thêm tất cả các trường từ data
            };
          }).toList();

      setState(() {
        orders.addAll(newOrders);
        lastDocument = snapshot.docs.last;
      });
    } else {
      setState(() {
        hasMore = false; // Không còn dữ liệu nữa
      });
    }

    // Nếu tải ít hơn 20 đơn hàng, không thực hiện tải thêm
    if (snapshot.docs.length < 20) {
      setState(() {
        hasMore = false;
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> updateOrderStatus(String orderId, String currentStatus) async {
    final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId);
    final orderIndex = orders.indexWhere((order) => order['id'] == orderId);
    if (orderIndex == -1) return;

    final statusMap = Map<String, dynamic>.from(
      orders[orderIndex]['status'] ?? {},
    );

    final nextStatus = _getNextStatus(currentStatus);
    if (nextStatus != null) {
      await orderRef.update({
        'status': {...statusMap, nextStatus: Timestamp.now()},
      });

      // Cập nhật trạng thái và latestStatus trong danh sách orders
      setState(() {
        orders[orderIndex]['status'] = {
          ...statusMap,
          nextStatus: Timestamp.now(),
        };
        orders[orderIndex]['latestStatus'] = nextStatus;
      });
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
      default:
        return Colors.grey;
    }
  }

  String moneyFormat(double amount) => '${amount.toStringAsFixed(0)}đ';

  void _openFilterDialog() {
    TextEditingController startController = TextEditingController(
      text:
          filterStartDate != null
              ? DateFormat('dd/MM/yyyy').format(filterStartDate!)
              : '',
    );

    TextEditingController endController = TextEditingController(
      text:
          filterEndDate != null
              ? DateFormat('dd/MM/yyyy').format(filterEndDate!)
              : '',
    );

    void selectQuick(DateTime start, DateTime end) {
      setState(() {
        filterStartDate = start;
        filterEndDate = end;
      });
      Navigator.pop(context);
      loadOrders(reset: true);
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Lọc theo thời gian'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chọn ngày bắt đầu và kết thúc
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: startController,
                    readOnly: true,
                    onTap: () async {
                      final pickedStart = await showDatePicker(
                        context: context,
                        initialDate: filterStartDate ?? DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate:
                            DateTime.now(), // Prevent selecting a future date
                      );
                      if (pickedStart != null) {
                        setState(() {
                          filterStartDate = pickedStart;
                        });
                        startController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(pickedStart);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Ngày bắt đầu',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: endController,
                    readOnly: true,
                    onTap: () async {
                      final pickedEnd = await showDatePicker(
                        context: context,
                        initialDate: filterEndDate ?? DateTime.now(),
                        firstDate: filterStartDate ?? DateTime(2023),
                        lastDate:
                            DateTime.now(), // Prevent selecting a future date
                      );
                      if (pickedEnd != null) {
                        setState(() {
                          filterEndDate = pickedEnd;
                        });
                        endController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(pickedEnd);

                        // Xử lý thay đổi ngày nếu ngày kết thúc nhỏ hơn ngày bắt đầu
                        if (filterStartDate != null && filterEndDate != null) {
                          if (filterEndDate!.isBefore(filterStartDate!)) {
                            // Hoán đổi ngày nếu ngày kết thúc trước ngày bắt đầu
                            DateTime temp = filterStartDate!;
                            filterStartDate = filterEndDate!;
                            filterEndDate = temp;

                            // Cập nhật lại các trường nhập
                            startController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(filterStartDate!);
                            endController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(filterEndDate!);
                          }
                        }
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Ngày kết thúc',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                // Các nút chọn thời gian nhanh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final today = DateTime.now();
                          selectQuick(
                            DateTime(today.year, today.month, today.day),
                            DateTime(
                              today.year,
                              today.month,
                              today.day,
                              23,
                              59,
                              59,
                            ),
                          );
                        },
                        child: const Text('Hôm nay'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final yesterday = DateTime.now().subtract(
                            const Duration(days: 1),
                          );
                          selectQuick(
                            DateTime(
                              yesterday.year,
                              yesterday.month,
                              yesterday.day,
                            ),
                            DateTime(
                              yesterday.year,
                              yesterday.month,
                              yesterday.day,
                              23,
                              59,
                              59,
                            ),
                          );
                        },
                        child: const Text('Hôm qua'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final now = DateTime.now();
                          final startOfWeek = now.subtract(
                            Duration(days: now.weekday - 1),
                          );
                          selectQuick(
                            DateTime(
                              startOfWeek.year,
                              startOfWeek.month,
                              startOfWeek.day,
                            ),
                            DateTime.now(),
                          );
                        },
                        child: const Text('Tuần này'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final now = DateTime.now();
                          selectQuick(
                            DateTime(now.year, now.month, 1),
                            DateTime.now(),
                          );
                        },
                        child: const Text('Tháng này'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Nút xóa bộ lọc
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    filterStartDate = null;
                    filterEndDate = null;
                  });
                  loadOrders(reset: true);
                },
                child: const Text('Xoá bộ lọc'),
              ),
              // Nút lọc
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  loadOrders(reset: true);
                },
                child: const Text('Lọc'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterDialog,
            tooltip: 'Lọc theo thời gian',
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount:
            orders.length + (hasMore ? 1 : 0), // Thêm 1 spinner nếu còn dữ liệu
        itemBuilder: (context, index) {
          if (index >= orders.length) {
            // Hiển thị spinner khi có dữ liệu cần tải thêm
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final order = orders[index];
          final latestStatus = getLatestStatus(
            Map<String, dynamic>.from(order['status']),
          );

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailPage(order: order),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
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
                      'Ngày đặt: ${DateFormat('dd/MM/yyyy').format(order['orderDate'].toDate())}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng tiền: ${moneyFormat(order['total'])}',
                      style: const TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trạng thái: $latestStatus',
                      style: TextStyle(color: _getStatusColor(latestStatus)),
                    ),
                    if (latestStatus != 'Đã giao')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed:
                                () => updateOrderStatus(
                                  order['id'],
                                  latestStatus,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
