import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  DateTimeRange? selectedRange;
  String selectedTimeFilter = 'Hôm nay';

  List<String> timeOptions = [
    'Hôm nay',
    'Hôm qua',
    '3 ngày trước',
    '7 ngày trước',
    'Tháng này',
    'Tùy chọn',
  ];

  DateTimeRange _getDateRangeFromFilter(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'Hôm nay':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case 'Hôm qua':
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(yesterday.year, yesterday.month, yesterday.day),
          end: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
            59,
          ),
        );
      case '3 ngày trước':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 3)),
          end: now,
        );
      case '7 ngày trước':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case 'Tháng này':
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      default:
        return selectedRange ?? DateTimeRange(start: DateTime(2000), end: now);
    }
  }

  Future<int> _getTotalUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.size;
  }

  Future<int> _getTotalOrders() async {
    final range = _getDateRangeFromFilter(selectedTimeFilter);
    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where(
              'orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
            )
            .where(
              'orderDate',
              isLessThanOrEqualTo: Timestamp.fromDate(range.end),
            )
            .get();
    return snapshot.size;
  }

  Future<double> _getTotalRevenue() async {
    final range = _getDateRangeFromFilter(selectedTimeFilter);
    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where(
              'orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
            )
            .where(
              'orderDate',
              isLessThanOrEqualTo: Timestamp.fromDate(range.end),
            )
            .get();
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['subtotal'] ?? 0).toDouble();
    }
    return total;
  }

  Future<double> _getTotalTax() async {
    final range = _getDateRangeFromFilter(selectedTimeFilter);
    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where(
              'orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
            )
            .where(
              'orderDate',
              isLessThanOrEqualTo: Timestamp.fromDate(range.end),
            )
            .get();
    double totalVat = 0;
    for (var doc in snapshot.docs) {
      totalVat += (doc.data()['vat'] ?? 0).toDouble();
    }
    return totalVat;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê tổng quan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Row cards
          Row(
            children: [
              Expanded(
                child: FutureBuilder<int>(
                  future: _getTotalUsers(),
                  builder:
                      (context, snapshot) => Card(
                        child: ListTile(
                          title: const Text('Tổng người dùng'),
                          subtitle: Text(
                            snapshot.hasData ? '${snapshot.data}' : '...',
                          ),
                        ),
                      ),
                ),
              ),
              Expanded(
                child: FutureBuilder<int>(
                  future: _getTotalOrders(),
                  builder:
                      (context, snapshot) => Card(
                        child: ListTile(
                          title: const Text('Tổng đơn hàng'),
                          subtitle: Text(
                            snapshot.hasData ? '${snapshot.data}' : '...',
                          ),
                        ),
                      ),
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedTimeFilter,
                  decoration: const InputDecoration(labelText: 'Thời gian'),
                  items:
                      timeOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) async {
                    if (value == 'Tùy chọn') {
                      DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedRange = picked;
                        });
                      }
                    }
                    setState(() {
                      selectedTimeFilter = value!;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Revenue and Tax
          Row(
            children: [
              Expanded(
                child: FutureBuilder<double>(
                  future: _getTotalRevenue(),
                  builder:
                      (context, snapshot) => Card(
                        child: ListTile(
                          title: const Text('Tổng doanh thu (chưa VAT)'),
                          subtitle: Text(
                            snapshot.hasData
                                ? NumberFormat.currency(
                                  locale: 'vi_VN',
                                  symbol: '₫',
                                ).format(snapshot.data)
                                : '...',
                          ),
                        ),
                      ),
                ),
              ),
              Expanded(
                child: FutureBuilder<double>(
                  future: _getTotalTax(),
                  builder:
                      (context, snapshot) => Card(
                        child: ListTile(
                          title: const Text('Tổng thuế phải đóng'),
                          subtitle: Text(
                            snapshot.hasData
                                ? NumberFormat.currency(
                                  locale: 'vi_VN',
                                  symbol: '₫',
                                ).format(snapshot.data)
                                : '...',
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Placeholder for charts (can be implemented using packages like fl_chart)
          const Placeholder(fallbackHeight: 200, strokeWidth: 2),
          const SizedBox(height: 20),
          const Placeholder(fallbackHeight: 200, strokeWidth: 2),
          const SizedBox(height: 20),
          const Placeholder(fallbackHeight: 250, strokeWidth: 2),
        ],
      ),
    );
  }
}
