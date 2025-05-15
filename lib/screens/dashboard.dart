import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_store/utils/moneyFormat.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  String _userRatio = "0/0";
  int _orders = 0;
  double _totalRevenue = 0;
  DateTimeRange? _selectedDateRange;
  String _selectedViewMode = 'Theo năm';
  List<RevenueData> _chartData = [];
  List<MonthlyRevenueData> _monthlyChartData = [];
  List<QuarterlyRevenueData> _quarterlyChartData = [];
  List<YearlyRevenueData> _yearlyChartData = [];
  List<WeeklyRevenueData> _weeklyChartData = [];
  final List<OrderData> _orderData = [];
  List<Map<String, dynamic>> _bestSellingProducts = [];

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );
    _updateData();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('vi_VN');
  }

  Future<void> _updateData() async {
    await _updateUsersData();
    await _updateOrdersData();
    _updateChartData();
    _updateMonthlyChartData();
    _updateQuarterlyChartData();
    _updateYearlyChartData();
    _updateWeeklyChartData();
    await _updateBestSellingProducts();
  }

  Future<void> _updateUsersData() async {
    try {
      // 1. Lấy tổng số người dùng:
      final QuerySnapshot totalUsersSnapshot =
          await _firestore.collection('users').get();
      final int totalUsers = totalUsersSnapshot.docs.length;

      final QuerySnapshot newUsersSnapshot =
          await _firestore
              .collection('users')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: _selectedDateRange!.start,
                isLessThanOrEqualTo: _selectedDateRange!.end,
              )
              .get();
      final int newUsersInPeriod = newUsersSnapshot.docs.length;
      _userRatio = '$newUsersInPeriod/$totalUsers';
    } catch (e) {
      // 4. Xử lý lỗi:
      print("Error fetching user data: $e");
      _userRatio = '0/0';
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateOrdersData() async {
    _orderData.clear();
    _totalRevenue = 0;
    _orders = 0;
    try {
      // Get orders within the selected date range
      final QuerySnapshot orderSnapshot =
          await _firestore
              .collection('orders')
              .where(
                'orderDate',
                isGreaterThanOrEqualTo: normalizeDate(
                  _selectedDateRange!.start,
                ),
              )
              .where(
                'orderDate',
                isLessThan: normalizeDate(
                  _selectedDateRange!.end.add(const Duration(days: 1)),
                ),
              )
              .get();

      for (final doc in orderSnapshot.docs) {
        print(doc); // Added for debugging
        final data = doc.data() as Map<String, dynamic>;
        final orderDate =
            data['orderDate'] != null
                ? (data['orderDate'] as Timestamp).toDate()
                : DateTime.now();
        final orderId = data['orderId'] ?? '';
        final total = (data['total'] ?? 0).toDouble();

        // Chỉ tính các đơn hàng trong ngày được chọn
        if (isSameDay(orderDate, _selectedDateRange!.start) ||
            isSameDay(orderDate, _selectedDateRange!.end) ||
            (orderDate.isAfter(normalizeDate(_selectedDateRange!.start)) &&
                orderDate.isBefore(normalizeDate(_selectedDateRange!.end)))) {
          _orders++;
          _totalRevenue += total;
          _orderData.add(OrderData(_formatDate(orderDate), orderId, total));
        }
      }
    } catch (e) {
      print("Error fetching order data: $e");
      // Handle error: keep previous values or set to 0
    } finally {
      if (mounted) setState(() {});
    }
  }

  // Hàm tiện ích để chuẩn hóa DateTime (loại bỏ thời gian)
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  //Hàm tiện ích để so sánh ngày
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _updateChartData() {
    List<RevenueData> newData = [];
    if (_selectedDateRange != null) {
      for (
        DateTime date = _selectedDateRange!.start;
        date.isBefore(_selectedDateRange!.end) ||
            date.isAtSameMomentAs(_selectedDateRange!.end);
        date = date.add(const Duration(days: 1))
      ) {
        // Fetch revenue for each day
        double dailyRevenue = 0; // Default
        //get data from firebase
        getDailyRevenue(date).then((value) {
          dailyRevenue = value;
          newData.add(RevenueData(_formatDate(date), dailyRevenue));
          if (date == _selectedDateRange!.end) {
            _chartData = newData;
            if (mounted) setState(() {});
          }
        });
      }
    }
    _chartData = newData;
    if (mounted) setState(() {});
  }

  Future<double> getDailyRevenue(DateTime date) async {
    double dailyRevenue = 0;
    try {
      final dailyOrderSnapshot =
          await _firestore
              .collection('orders')
              .where('orderDate', isGreaterThanOrEqualTo: normalizeDate(date))
              .where(
                'orderDate',
                isLessThan: normalizeDate(date.add(const Duration(days: 1))),
              )
              .get();

      for (final doc in dailyOrderSnapshot.docs) {
        final data = doc.data();
        dailyRevenue += (data['total'] ?? 0).toDouble();
      }
    } catch (e) {
      print("Error fetching daily revenue: $e");
    }
    return dailyRevenue;
  }

  void _updateMonthlyChartData() {
    List<MonthlyRevenueData> newMonthlyData = [];
    if (_selectedDateRange != null) {
      int months =
          (_selectedDateRange!.end.year - _selectedDateRange!.start.year) * 12 +
          _selectedDateRange!.end.month -
          _selectedDateRange!.start.month +
          1;

      for (int i = 0; i < months; i++) {
        DateTime monthDate = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month + i,
          1,
        );
        String monthName = DateFormat('MMMM', 'vi_VN').format(monthDate);
        double monthlyRevenue = 0;
        getMonthlyRevenue(monthDate).then((value) {
          monthlyRevenue = value;
          newMonthlyData.add(MonthlyRevenueData(monthName, monthlyRevenue));
          if (i == months - 1) {
            _monthlyChartData = newMonthlyData;
            if (mounted) setState(() {});
          }
        });
      }
    }
    _monthlyChartData = newMonthlyData;
    if (mounted) setState(() {});
  }

  Future<double> getMonthlyRevenue(DateTime monthDate) async {
    double monthlyRevenue = 0;
    DateTime nextMonth = DateTime(
      monthDate.year,
      monthDate.month + 1,
      monthDate.day,
    );
    try {
      final monthlyOrderSnapshot =
          await _firestore
              .collection('orders')
              .where(
                'orderDate',
                isGreaterThanOrEqualTo: normalizeDate(monthDate),
                isLessThan: normalizeDate(nextMonth),
              )
              .get();
      for (final doc in monthlyOrderSnapshot.docs) {
        final data = doc.data();
        monthlyRevenue += (data['total'] ?? 0).toDouble();
      }
    } catch (e) {
      print("Error fetching monthly revenue: $e");
    }
    return monthlyRevenue;
  }

  void _updateQuarterlyChartData() {
    List<QuarterlyRevenueData> newQuarterlyData = [];
    if (_selectedDateRange != null) {
      int startQuarter = (_selectedDateRange!.start.month / 3).ceil();
      int endQuarter = (_selectedDateRange!.end.month / 3).ceil();
      int quarters =
          (_selectedDateRange!.end.year - _selectedDateRange!.start.year) * 4 +
          endQuarter -
          startQuarter +
          1;

      for (int i = 0; i < quarters; i++) {
        int quarter = startQuarter + i;
        int year = _selectedDateRange!.start.year + ((quarter - 1) ~/ 4);
        if (quarter > 4) {
          quarter -= 4;
        }
        double quarterlyRevenue = 0;
        DateTime quarterStartDate = getQuarterStartDate(year, quarter);
        DateTime quarterEndDate = getQuarterEndDate(year, quarter);
        getQuarterlyRevenue(quarterStartDate, quarterEndDate).then((value) {
          quarterlyRevenue = value;
          newQuarterlyData.add(
            QuarterlyRevenueData(year, quarter, quarterlyRevenue),
          );
          if (i == quarters - 1) {
            _quarterlyChartData = newQuarterlyData;
            if (mounted) setState(() {});
          }
        });
      }
    }
    _quarterlyChartData = newQuarterlyData;
    if (mounted) setState(() {});
  }

  DateTime getQuarterStartDate(int year, int quarter) {
    if (quarter == 1) {
      return DateTime(year, 1, 1);
    } else if (quarter == 2) {
      return DateTime(year, 4, 1);
    } else if (quarter == 3) {
      return DateTime(year, 7, 1);
    } else {
      return DateTime(year, 10, 1);
    }
  }

  DateTime getQuarterEndDate(int year, int quarter) {
    if (quarter == 1) {
      return DateTime(year, 3, 31);
    } else if (quarter == 2) {
      return DateTime(year, 6, 30);
    } else if (quarter == 3) {
      return DateTime(year, 9, 30);
    } else {
      return DateTime(year, 12, 31);
    }
  }

  Future<double> getQuarterlyRevenue(
    DateTime quarterStartDate,
    DateTime quarterEndDate,
  ) async {
    double quarterlyRevenue = 0;
    try {
      final quarterlyOrderSnapshot =
          await _firestore
              .collection('orders')
              .where(
                'orderDate',
                isGreaterThanOrEqualTo: normalizeDate(quarterStartDate),
                isLessThanOrEqualTo: normalizeDate(quarterEndDate),
              )
              .get();
      for (final doc in quarterlyOrderSnapshot.docs) {
        final data = doc.data();
        quarterlyRevenue += (data['total'] ?? 0).toDouble();
      }
    } catch (e) {
      print("Error fetching quarterly revenue:$e");
    }
    return quarterlyRevenue;
  }

  void _updateYearlyChartData() {
    List<YearlyRevenueData> newYearlyData = [];
    if (_selectedDateRange != null) {
      int startYear = _selectedDateRange!.start.year;
      int endYear = _selectedDateRange!.end.year;
      int years = endYear - startYear + 1;

      for (int i = 0; i < years; i++) {
        int year = startYear + i;
        double yearlyRevenue = 0;
        DateTime yearStartDate = DateTime(year, 1, 1);
        DateTime yearEndDate = DateTime(year, 12, 31);
        getYearlyRevenue(yearStartDate, yearEndDate).then((value) {
          yearlyRevenue = value;
          newYearlyData.add(YearlyRevenueData(year, yearlyRevenue));
          if (i == years - 1) {
            _yearlyChartData = newYearlyData;
            if (mounted) setState(() {});
          }
        });
      }
    }
    _yearlyChartData = newYearlyData;
    if (mounted) setState(() {});
  }

  Future<double> getYearlyRevenue(
    DateTime yearStartDate,
    DateTime yearEndDate,
  ) async {
    double yearlyRevenue = 0;
    try {
      final yearlyOrderSnapshot =
          await _firestore
              .collection('orders')
              .where(
                'orderDate',
                isGreaterThanOrEqualTo: normalizeDate(yearStartDate),
                isLessThanOrEqualTo: normalizeDate(yearEndDate),
              )
              .get();
      for (final doc in yearlyOrderSnapshot.docs) {
        final data = doc.data();
        yearlyRevenue += (data['total'] ?? 0).toDouble();
      }
    } catch (e) {
      print("Error fetching yearly revenue: $e");
    }
    return yearlyRevenue;
  }

  void _updateWeeklyChartData() {
    List<WeeklyRevenueData> newWeeklyData = [];
    if (_selectedDateRange != null) {
      // Calculate the number of weeks between start and end date
      int weeks =
          (_selectedDateRange!.end
                      .difference(_selectedDateRange!.start)
                      .inDays /
                  7)
              .ceil();

      for (int i = 0; i < weeks; i++) {
        DateTime weekStartDate = _selectedDateRange!.start.add(
          Duration(days: i * 7),
        );
        double weeklyRevenue = 0;
        DateTime weekEndDate = weekStartDate.add(const Duration(days: 6));
        getWeeklyRevenue(weekStartDate, weekEndDate).then((value) {
          weeklyRevenue = value;
          newWeeklyData.add(WeeklyRevenueData(weekStartDate, weeklyRevenue));
          if (i == weeks - 1) {
            _weeklyChartData = newWeeklyData;
            if (mounted) setState(() {});
          }
        });
      }
    }
    _weeklyChartData = newWeeklyData;
    if (mounted) setState(() {});
  }

  Future<double> getWeeklyRevenue(
    DateTime weekStartDate,
    DateTime weekEndDate,
  ) async {
    double weeklyRevenue = 0;
    try {
      final weeklyOrderSnapshot =
          await _firestore
              .collection('orders')
              .where(
                'orderDate',
                isGreaterThanOrEqualTo: normalizeDate(weekStartDate),
                isLessThanOrEqualTo: normalizeDate(weekEndDate),
              )
              .get();
      for (final doc in weeklyOrderSnapshot.docs) {
        final data = doc.data();
        weeklyRevenue += (data['total'] ?? 0).toDouble();
      }
    } catch (e) {
      print("Error fetching weekly revenue: $e");
    }
    return weeklyRevenue;
  }

  Future<void> _updateBestSellingProducts() async {
    try {
      final snapshot =
          await _firestore
              .collection('orders')
              .where(
                'orderDate',
                isGreaterThanOrEqualTo: normalizeDate(
                  _selectedDateRange!.start,
                ),
              )
              .where(
                'orderDate',
                isLessThan: normalizeDate(
                  _selectedDateRange!.end.add(const Duration(days: 1)),
                ),
              )
              .get();

      final Map<String, Map<String, dynamic>> productMap = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;

        if (items == null) continue;

        for (final item in items) {
          final productId = item['productId'].toString();
          final name = item['productName'] ?? 'Không tên';
          final quantity = (item['quantity'] ?? 0) as int;

          if (productMap.containsKey(productId)) {
            productMap[productId]!['quantity'] += quantity;
          } else {
            productMap[productId] = {
              'productId': productId,
              'productName': name,
              'quantity': quantity,
            };
          }
        }
      }

      final products = productMap.values.toList();

      // Sắp xếp giảm dần theo số lượng bán
      products.sort(
        (a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int),
      );

      // Lấy top 10
      _bestSellingProducts = products.take(10).toList();
    } catch (e) {
      print("Error fetching best selling products: $e");
      _bestSellingProducts = [];
    } finally {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTopCards(context),
            const SizedBox(height: 20),
            _buildMiddleCards(context),
            const SizedBox(height: 20),
            _buildMonthlyRevenueCard(context),
            const SizedBox(height: 20),
            _buildBestSellingProductsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Kích thước card tối thiểu
        const minCardWidth = 200.0;

        // Tính số cột có thể hiển thị dựa trên chiều rộng
        int crossAxisCount =
            (constraints.maxWidth / (minCardWidth + 16)).floor();
        crossAxisCount = crossAxisCount.clamp(1, 4); // Giới hạn từ 1 đến 4 cột

        final cardWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

        final cards = [
          _buildStatCard(
            'Người dùng',
            _userRatio,
            Icons.person,
            width: cardWidth,
          ),
          _buildStatCard(
            'Đơn hàng',
            '$_orders',
            Icons.shopping_cart,
            width: cardWidth,
          ),
          _buildStatCard(
            'Tổng tiền',
            moneyFormat(_totalRevenue),
            Icons.attach_money,
            width: cardWidth,
          ),
          _buildTimePeriodDropdown(context, width: cardWidth),
        ];

        return Wrap(spacing: 16.0, runSpacing: 16.0, children: cards);
      },
    );
  }

  Widget _buildMiddleCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Ngưỡng để chuyển layout: 600 px (bạn có thể điều chỉnh)
        final isWideScreen = maxWidth > 600;

        if (isWideScreen) {
          final orderListWidth = maxWidth * 2 / 5;
          final revenueChartWidth = maxWidth * 3 / 5 - 16;

          return Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: [
              _buildRevenueChartCard(width: revenueChartWidth),
              _buildOrderListCard(width: orderListWidth),
            ],
          );
        } else {
          // Điện thoại: xếp dọc, full-width
          return Column(
            children: [
              _buildRevenueChartCard(width: maxWidth),
              const SizedBox(height: 16),
              _buildOrderListCard(width: maxWidth),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    double? width,
  }) {
    return SizedBox(
      width: width,
      height: 150,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.blue),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePeriodDropdown(BuildContext context, {double? width}) {
    return SizedBox(
      width: width,
      height: 150,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thời gian:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDateRange != null
                          ? 'Từ: ${_formatDate(_selectedDateRange!.start)} \n'
                              'Đến: ${_formatDate(_selectedDateRange!.end)}'
                          : 'Chọn khoảng ngày',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: const Text('Chọn', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Chế độ xem: ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedViewMode,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedViewMode = newValue;
                            _updateChartData();
                            _updateMonthlyChartData();
                            _updateQuarterlyChartData();
                            _updateYearlyChartData();
                            _updateWeeklyChartData();
                          });
                        }
                      },
                      items:
                          <String>[
                            'Theo ngày',
                            'Theo tuần',
                            'Theo tháng',
                            'Theo quý',
                            'Theo năm',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                      padding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChartCard({double? width}) {
    return SizedBox(
      width: width,
      height: 300,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getChartTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildRevenueChart()),
            ],
          ),
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedViewMode) {
      case 'Theo ngày':
        return 'Doanh thu theo ngày';
      case 'Theo tuần':
        return 'Doanh thu theo tuần';
      case 'Theo tháng':
        return 'Doanh thu theo tháng';
      case 'Theo quý':
        return 'Doanh thu theo quý';
      case 'Theo năm':
        return 'Doanh thu theo năm';
      default:
        return 'Doanh thu';
    }
  }

  Widget _buildRevenueChart() {
    List<BarChartGroupData> barGroups = [];
    switch (_selectedViewMode) {
      case 'Theo ngày':
        barGroups =
            _chartData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return _buildBarChartGroupData(index, data.revenue, Colors.blue);
            }).toList();
        break;
      case 'Theo tuần':
        barGroups =
            _weeklyChartData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return _buildBarChartGroupData(index, data.revenue, Colors.green);
            }).toList();
        break;
      case 'Theo tháng':
        barGroups =
            _monthlyChartData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return _buildBarChartGroupData(
                index,
                data.revenue,
                Colors.orange,
              );
            }).toList();
        break;
      case 'Theo quý':
        barGroups =
            _quarterlyChartData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return _buildBarChartGroupData(
                index,
                data.revenue,
                Colors.purple,
              );
            }).toList();
        break;
      case 'Theo năm':
        barGroups =
            _yearlyChartData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return _buildBarChartGroupData(index, data.revenue, Colors.red);
            }).toList();
        break;
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: _buildFlTitlesData(),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (
              BarChartGroupData group,
              int groupIndex,
              BarChartRodData rod,
              int rodIndex,
            ) {
              String title = '';
              switch (_selectedViewMode) {
                case 'Theo ngày':
                  title = _chartData[groupIndex].day;
                  break;
                case 'Theo tuần':
                  title = 'Tuần ${groupIndex + 1}';
                  break;
                case 'Theo tháng':
                  title = _monthlyChartData[groupIndex].monthName;
                  break;
                case 'Theo quý':
                  final data = _quarterlyChartData[groupIndex];
                  title = 'Quý ${data.quarter}/${data.year}';
                  break;
                case 'Theo năm':
                  title = _yearlyChartData[groupIndex].year.toString();
                  break;
              }

              double revenue = double.parse(rod.toY.toStringAsFixed(2));

              return BarTooltipItem(
                '$title\nDoanh số: ${moneyFormat(revenue)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarChartGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: BorderRadius.zero,
        ),
      ],
      groupVertically: true,
    );
  }

  FlTitlesData _buildFlTitlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final int index = value.toInt();
            switch (_selectedViewMode) {
              case 'Theo ngày':
                if (index >= 0 && index < _chartData.length) {
                  return Text(
                    _chartData[index].day,
                    style: const TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }
                break;
              case 'Theo tuần':
                return Text(
                  'Tuần ${index + 1}',
                  style: const TextStyle(
                    color: Color(0xff7589a2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              case 'Theo tháng':
                if (index >= 0 && index < _monthlyChartData.length) {
                  return Text(
                    _monthlyChartData[index].monthName,
                    style: const TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }
                break;
              case 'Theo quý':
                if (index >= 0 && index < _quarterlyChartData.length) {
                  return Text(
                    'Quý ${index + 1}',
                    style: const TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }
                break;

              case 'Theo năm':
                if (index >= 0 && index < _yearlyChartData.length) {
                  return Text(
                    _yearlyChartData[index].year.toString(),
                    style: const TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }
                break;
            }
            return const Text('');
          },
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildOrderListCard({double? width}) {
    final hasData = _orderData.isNotEmpty;

    return SizedBox(
      width: width,
      height: 300,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh sách đơn hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Nếu có dữ liệu -> hiển thị danh sách, ngược lại -> hiển thị thông báo
              Expanded(
                child:
                    hasData
                        ? ListView.builder(
                          itemCount: _orderData.length,
                          itemBuilder: (context, index) {
                            final order = _orderData[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderDate,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    order.orderId,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    moneyFormat(order.total),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                        : const Center(
                          child: Text(
                            'Không có đơn hàng nào được bán ra.',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyRevenueCard(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng doanh thu trong 12 tháng của năm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildMonthlyRevenueChart()),
              _buildRevenueComparison(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyRevenueChart() {
    return BarChart(
      BarChartData(
        barGroups:
            _monthlyChartData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data.revenue,
                    color: Colors.green,
                    width: 20,
                    borderRadius: BorderRadius.zero,
                  ),
                ],
                groupVertically: true,
              );
            }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final int monthValue = value.toInt();
                if (monthValue >= 0 && monthValue < _monthlyChartData.length) {
                  return Text(
                    _monthlyChartData[monthValue].monthName,
                    style: const TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (
              BarChartGroupData group,
              int groupIndex,
              BarChartRodData rod,
              int rodIndex,
            ) {
              String monthName = _monthlyChartData[groupIndex].monthName;
              double revenue = double.parse(rod.toY.toStringAsFixed(2));
              return BarTooltipItem(
                '$monthName\nDoanh số: ${moneyFormat(revenue)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final totalQuantity = _bestSellingProducts.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.yellow,
      Colors.cyan,
      Colors.brown,
      Colors.pink,
    ];

    return List.generate(_bestSellingProducts.length, (i) {
      final product = _bestSellingProducts[i];
      final quantity = product['quantity'] as int;
      final percentage =
          totalQuantity == 0 ? 0 : (quantity / totalQuantity) * 100;

      return PieChartSectionData(
        color: colors[i % colors.length],
        value: quantity.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildRevenueComparison() {
    double maxRevenue = 0;
    String maxRevenueMonth = '';
    double minRevenue = double.infinity;
    String minRevenueMonth = '';

    for (final data in _monthlyChartData) {
      if (data.revenue > maxRevenue) {
        maxRevenue = data.revenue;
        maxRevenueMonth = data.monthName;
      }
      if (data.revenue < minRevenue) {
        minRevenue = data.revenue;
        minRevenueMonth = data.monthName;
      }
    }

    String comparisonText;
    if (_monthlyChartData.isNotEmpty) {
      comparisonText =
          '$maxRevenueMonth có doanh thu cao nhất: \$${maxRevenue.toStringAsFixed(2)}, '
          '$minRevenueMonth có doanh thu thấp nhất: \$${minRevenue.toStringAsFixed(2)}.';
    } else {
      comparisonText = 'Không có dữ liệu doanh thu để so sánh.';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        comparisonText,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _updateData();
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'vi_VN').format(date);
  }

  Widget _buildBestSellingProductsCard() {
    final totalQuantity = _bestSellingProducts.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    final hasData = _bestSellingProducts.isNotEmpty && totalQuantity > 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm bán chạy nhất - TOP 10',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (hasData) ...[
              // Biểu đồ tròn
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tiêu đề bảng
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Tên sản phẩm',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Phần trăm',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Số lượng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Danh sách dữ liệu
              SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: _bestSellingProducts.length,
                  itemBuilder: (context, index) {
                    final product = _bestSellingProducts[index];
                    final quantity = product['quantity'] as int;

                    // Bỏ qua sản phẩm có số lượng 0
                    if (quantity == 0) return const SizedBox.shrink();

                    final percentage =
                        totalQuantity == 0
                            ? 0
                            : (quantity / totalQuantity * 100).toStringAsFixed(
                              1,
                            );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(product['productId'].toString()),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(product['productName'].toString()),
                          ),
                          Expanded(flex: 2, child: Text('$percentage%')),
                          Expanded(flex: 2, child: Text(quantity.toString())),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'Không có sản phẩm nào được bán ra.',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RevenueData {
  final String day;
  final double revenue;

  RevenueData(this.day, this.revenue);
}

class MonthlyRevenueData {
  final String monthName;
  final double revenue;

  MonthlyRevenueData(this.monthName, this.revenue);
}

class QuarterlyRevenueData {
  final int year;
  final int quarter;
  final double revenue;

  QuarterlyRevenueData(this.year, this.quarter, this.revenue);
}

class YearlyRevenueData {
  final int year;
  final double revenue;

  YearlyRevenueData(this.year, this.revenue);
}

class WeeklyRevenueData {
  final DateTime weekStartDate;
  final double revenue;

  WeeklyRevenueData(this.weekStartDate, this.revenue);
}

class OrderData {
  final String orderDate;
  final String orderId;
  final double total;

  OrderData(this.orderDate, this.orderId, this.total);
}
