import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  int _totalUsers = 0;
  String _userRatio = "0/0";
  int _orders = 0;
  double _totalRevenue = 0;

  String _selectedTimePeriod = 'Hôm nay';
  String _selectedViewMode = 'Theo ngày';

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  List<RevenueData> _chartData = [];
  List<MonthlyRevenueData> _monthlyChartData = [];
  List<QuarterlyRevenueData> _quarterlyChartData = [];
  List<YearlyRevenueData> _yearlyChartData = [];
  List<WeeklyRevenueData> _weeklyChartData = [];
  List<OrderData> _orderData = [];
  List<Map<String, dynamic>> _bestSellingProducts = [];

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _fetchDashboardData();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('vi_VN');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          const SizedBox(height: 20),
          _buildHelloText(),
        ],
      ),
    );
  }

  // Xây dựng các thẻ trên cùng
  Widget _buildTopCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 4;
        return Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
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
              '\$${_totalRevenue.toStringAsFixed(2)}',
              Icons.attach_money,
              width: cardWidth,
            ),
            _buildTimePeriodDropdown(width: cardWidth),
          ],
        );
      },
    );
  }

  // Xây dựng các thẻ ở giữa
  Widget _buildMiddleCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double orderListWidth = constraints.maxWidth * 2 / 5;
        final double revenueChartWidth = constraints.maxWidth * 3 / 5 - 16;
        return Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            _buildRevenueChartCard(width: revenueChartWidth),
            _buildOrderListCard(width: orderListWidth),
          ],
        );
      },
    );
  }

  // Xây dựng text "Hello"
  Widget _buildHelloText() {
    return const Text(
      'Hello',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  // Xây dựng một thẻ thống kê
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    double? width,
  }) {
    if (title == 'Người dùng') {
      return SizedBox(
        width: width,
        height: 180,
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Icon(icon, size: 28, color: Colors.blue),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tổng tài khoản',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _userRatio,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng số tài khoản: $_totalUsers',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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

    return SizedBox(
      width: width,
      height: 180,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
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

  // Xây dựng dropdown chọn khoảng thời gian
  Widget _buildTimePeriodDropdown({double? width}) {
    return SizedBox(
      width: width,
      height: 150,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thời gian:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Từ: ${_formatDate(_startDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, true),
                    child: const Text(
                      'Chọn',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đến: ${_formatDate(_endDate)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, false),
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
                            _fetchRevenueData();
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

  // Xây dựng thẻ biểu đồ doanh thu
  Widget _buildRevenueChartCard({double? width}) {
    return SizedBox(
      width: width,
      height: 200,
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

  // Hàm để xây dựng biểu đồ doanh thu bằng fl_chart
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
                  title = 'Quý ${groupIndex + 1}';
                  break;
                case 'Theo năm':
                  title = _yearlyChartData[groupIndex].year.toString();
                  break;
              }
              String revenue = rod.toY.toStringAsFixed(2);
              return BarTooltipItem(
                '$title\nRevenue: \$$revenue',
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

  // Xây dựng thẻ danh sách đơn hàng
  Widget _buildOrderListCard({double? width}) {
    return SizedBox(
      width: width,
      height: 200,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh sách đơn hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _orderData.length,
                  itemBuilder: (context, index) {
                    final order = _orderData[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.date,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            order.orderId,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '\$${order.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Xây dựng thẻ biểu đồ doanh thu hàng tháng
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
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

  // Hàm để xây dựng biểu đồ doanh thu hàng tháng
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
              String revenue = rod.toY.toStringAsFixed(2);
              return BarTooltipItem(
                '$monthName\nRevenue: \$$revenue',
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

  // Hàm để hiển thị so sánh doanh thu
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
          'Tháng $maxRevenueMonth có doanh thu cao nhất: \$${maxRevenue.toStringAsFixed(2)}, '
          'Tháng $minRevenueMonth có doanh thu thấp nhất: \$${minRevenue.toStringAsFixed(2)}.';
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

  // Logic chọn ngày
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
      await _fetchDashboardData();
    }
  }

  // Định dạng ngày để hiển thị
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'vi_VN').format(date);
  }

  // Fetch all dashboard data
  Future<void> _fetchDashboardData() async {
    await Future.wait([
      _fetchUserStats(),
      _fetchOrderStats(),
      _fetchRevenueData(),
      _fetchBestSellingProducts(),
    ]);
  }

  // Fetch user statistics
  Future<void> _fetchUserStats() async {
    try {
      // Lấy tổng số tài khoản (bao gồm cả admin)
      final totalUsersSnapshot = await _firestore
          .collection('users')
          .get();
      final totalUsers = totalUsersSnapshot.size;

      // Lấy số tài khoản được tạo trong khoảng thời gian đã chọn
      final usersInPeriodSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: _startDate)
          .where('createdAt', isLessThanOrEqualTo: _endDate)
          .get();
      final usersInPeriod = usersInPeriodSnapshot.size;

      setState(() {
        _totalUsers = totalUsers;
        _userRatio = "$usersInPeriod/$totalUsers";
      });
    } catch (e) {
      print('Error fetching user stats: $e');
    }
  }

  // Fetch order statistics
  Future<void> _fetchOrderStats() async {
    try {
      final QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: _startDate)
          .where('createdAt', isLessThanOrEqualTo: _endDate)
          .get();

      double total = 0;
      List<OrderData> orders = [];

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num).toDouble();
        total += amount;

        orders.add(OrderData(
          DateFormat('dd/MM/yyyy').format(data['createdAt'].toDate()),
          data['orderId'],
          amount,
        ));
      }

      setState(() {
        _orders = ordersSnapshot.size;
        _totalRevenue = total;
        _orderData = orders;
      });
    } catch (e) {
      print('Error fetching order stats: $e');
    }
  }

  // Fetch revenue data based on selected view mode
  Future<void> _fetchRevenueData() async {
    try {
      final QuerySnapshot revenueSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: _startDate)
          .where('createdAt', isLessThanOrEqualTo: _endDate)
          .orderBy('createdAt')
          .get();

      switch (_selectedViewMode) {
        case 'Theo ngày':
          _updateDailyRevenueData(revenueSnapshot);
          break;
        case 'Theo tuần':
          _updateWeeklyRevenueData(revenueSnapshot);
          break;
        case 'Theo tháng':
          _updateMonthlyRevenueData(revenueSnapshot);
          break;
        case 'Theo quý':
          _updateQuarterlyRevenueData(revenueSnapshot);
          break;
        case 'Theo năm':
          _updateYearlyRevenueData(revenueSnapshot);
          break;
      }
    } catch (e) {
      print('Error fetching revenue data: $e');
    }
  }

  void _updateDailyRevenueData(QuerySnapshot snapshot) {
    Map<String, double> dailyRevenue = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = DateFormat('dd/MM/yyyy').format((data['createdAt'] as Timestamp).toDate());
      final amount = (data['amount'] as num).toDouble();
      
      dailyRevenue[date] = (dailyRevenue[date] ?? 0) + amount;
    }

    setState(() {
      _chartData = dailyRevenue.entries
          .map((e) => RevenueData(e.key, e.value))
          .toList()
        ..sort((a, b) => DateFormat('dd/MM/yyyy').parse(a.day)
            .compareTo(DateFormat('dd/MM/yyyy').parse(b.day)));
    });
  }

  void _updateWeeklyRevenueData(QuerySnapshot snapshot) {
    Map<DateTime, double> weeklyRevenue = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp).toDate();
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final amount = (data['amount'] as num).toDouble();
      
      weeklyRevenue[weekStart] = (weeklyRevenue[weekStart] ?? 0) + amount;
    }

    setState(() {
      _weeklyChartData = weeklyRevenue.entries
          .map((e) => WeeklyRevenueData(e.key, e.value))
          .toList()
        ..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));
    });
  }

  void _updateMonthlyRevenueData(QuerySnapshot snapshot) {
    Map<String, double> monthlyRevenue = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp).toDate();
      final monthName = DateFormat('MMMM yyyy', 'vi_VN').format(date);
      final amount = (data['amount'] as num).toDouble();
      
      monthlyRevenue[monthName] = (monthlyRevenue[monthName] ?? 0) + amount;
    }

    setState(() {
      _monthlyChartData = monthlyRevenue.entries
          .map((e) => MonthlyRevenueData(e.key, e.value))
          .toList();
    });
  }

  void _updateQuarterlyRevenueData(QuerySnapshot snapshot) {
    Map<String, QuarterlyRevenueData> quarterlyRevenue = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp).toDate();
      final quarter = ((date.month - 1) ~/ 3) + 1;
      final year = date.year;
      final amount = (data['amount'] as num).toDouble();
      
      final key = '$year-Q$quarter';
      if (quarterlyRevenue.containsKey(key)) {
        quarterlyRevenue[key]!.revenue += amount;
      } else {
        quarterlyRevenue[key] = QuarterlyRevenueData(year, quarter, amount);
      }
    }

    setState(() {
      _quarterlyChartData = quarterlyRevenue.values.toList()
        ..sort((a, b) => a.year == b.year 
            ? a.quarter.compareTo(b.quarter)
            : a.year.compareTo(b.year));
    });
  }

  void _updateYearlyRevenueData(QuerySnapshot snapshot) {
    Map<int, double> yearlyRevenue = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp).toDate();
      final amount = (data['amount'] as num).toDouble();
      
      yearlyRevenue[date.year] = (yearlyRevenue[date.year] ?? 0) + amount;
    }

    setState(() {
      _yearlyChartData = yearlyRevenue.entries
          .map((e) => YearlyRevenueData(e.key, e.value))
          .toList()
        ..sort((a, b) => a.year.compareTo(b.year));
    });
  }

  // Fetch best selling products
  Future<void> _fetchBestSellingProducts() async {
    try {
      final QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .orderBy('soldQuantity', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> bestSellers = [];
      for (var doc in productsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        bestSellers.add({
          'name': data['name'],
          'quantity': data['soldQuantity'],
        });
      }

      setState(() {
        _bestSellingProducts = bestSellers;
      });
    } catch (e) {
      print('Error fetching best selling products: $e');
    }
  }

  // Xây dựng thẻ cho sản phẩm bán chạy nhất
  Widget _buildBestSellingProductsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm bán chạy nhất',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: _bestSellingProducts.length,
                itemBuilder: (context, index) {
                  final product = _bestSellingProducts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${product['quantity']} sản phẩm',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mô hình dữ liệu cho doanh thu
class RevenueData {
  final String day;
  double revenue;

  RevenueData(this.day, this.revenue);
}

// Mô hình dữ liệu cho doanh thu hàng tháng
class MonthlyRevenueData {
  final String monthName;
  double revenue;

  MonthlyRevenueData(this.monthName, this.revenue);
}

// Mô hình dữ liệu cho doanh thu theo quý
class QuarterlyRevenueData {
  final int year;
  final int quarter;
  double revenue;

  QuarterlyRevenueData(this.year, this.quarter, this.revenue);
}

// Mô hình dữ liệu cho doanh thu theo năm
class YearlyRevenueData {
  final int year;
  double revenue;

  YearlyRevenueData(this.year, this.revenue);
}

// Data model for weekly revenue
class WeeklyRevenueData {
  final DateTime weekStartDate;
  double revenue;

  WeeklyRevenueData(this.weekStartDate, this.revenue);
}

// Mô hình dữ liệu cho đơn hàng
class OrderData {
  final String date;
  final String orderId;
  final double amount;

  OrderData(this.date, this.orderId, this.amount);
}
