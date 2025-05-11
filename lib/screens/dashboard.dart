import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Dữ liệu cố định
  final int _newUsers = 45;
  final int _orders = 23;
  final double _totalRevenue = 1450.75;

  // Khoảng thời gian được chọn
  String _selectedTimePeriod = 'Hôm nay';
  String _selectedViewMode = 'Theo ngày'; // Thêm chế độ xem

  // Ngày bắt đầu và ngày kết thúc
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // Dữ liệu biểu đồ
  List<RevenueData> _chartData = [];
  List<MonthlyRevenueData> _monthlyChartData = [];
  List<QuarterlyRevenueData> _quarterlyChartData =
      []; // Dữ liệu biểu đồ doanh thu theo quý
  List<YearlyRevenueData> _yearlyChartData =
      []; // Dữ liệu biểu đồ doanh thu theo năm
  List<WeeklyRevenueData> _weeklyChartData = []; // Biểu đồ doanh thu theo tuần

  // Dữ liệu đơn hàng
  final List<OrderData> _orderData = [
    OrderData('01/01/2024', 'DH001', 200.00),
    OrderData('02/01/2024', 'DH002', 150.50),
    OrderData('03/01/2024', 'DH003', 300.00),
    OrderData('04/01/2024', 'DH004', 250.00),
    OrderData('05/01/2024', 'DH005', 180.00),
    OrderData('06/01/2024', 'DH006', 220.00),
    OrderData('07/01/2024', 'DH007', 190.00),
  ];

  // Dữ liệu sản phẩm bán chạy nhất
  final List<Map<String, dynamic>> _bestSellingProducts = [
    {'name': 'Sản phẩm A', 'quantity': 120},
    {'name': 'Sản phẩm B', 'quantity': 95},
    {'name': 'Sản phẩm C', 'quantity': 80},
    {'name': 'Sản phẩm D', 'quantity': 70},
    {'name': 'Sản phẩm E', 'quantity': 60},
  ];

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _updateChartData();
    _updateMonthlyChartData();
    _updateQuarterlyChartData();
    _updateYearlyChartData();
    _updateWeeklyChartData();
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
              '$_newUsers',
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
    return SizedBox(
      width: width,
      height: 180,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ), // Increased padding
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.blue), // Increased icon size
              const SizedBox(width: 20), // Increased spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14, // Increased font size
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20, // Increased font size
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
          ), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thời gian:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ), // Increased font size
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Từ: ${_formatDate(_startDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                      ), // Keep consistent font size
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, true),
                    child: const Text(
                      'Chọn',
                      style: TextStyle(
                        fontSize: 14,
                      ), // Keep consistent font size
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
              const SizedBox(height: 12), // Increased spacing
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

  // Xây dựng thẻ biểu đồ doanh thu
  Widget _buildRevenueChartCard({double? width}) {
    return SizedBox(
      width: width,
      height: 200, // Increased height for chart card
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getChartTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ), // Increased font size
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
                  fontSize: 16, // Increased font size in tooltip
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
          width: 20, // Increased bar width
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
      height: 200, // Increased height for order list card
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh sách đơn hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ), // Increased font size
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
                      ), // Increased vertical padding
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.date,
                            style: const TextStyle(
                              fontSize: 14,
                            ), // Consistent font size
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
      height: 300, // Increased height for monthly revenue card
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng doanh thu trong 12 tháng của năm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ), // Increased font size
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
                    width: 20, // Increased bar width
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
                  fontSize: 16, // Increased font size
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
        _updateChartData();
        _updateMonthlyChartData();
        _updateQuarterlyChartData();
        _updateYearlyChartData();
        _updateWeeklyChartData();
      });
    }
  }

  // Định dạng ngày để hiển thị
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'vi_VN').format(date);
  }

  void _updateChartData() {
    List<RevenueData> newData = [];
    if (_startDate.isBefore(_endDate) ||
        _startDate.isAtSameMomentAs(_endDate)) {
      for (
        DateTime date = _startDate;
        date.isBefore(_endDate) || date.isAtSameMomentAs(_endDate);
        date = date.add(const Duration(days: 1))
      ) {
        // Replace this with your actual data fetching logic
        double revenue = 100.0 + date.day * 5.0; // Example revenue calculation
        newData.add(RevenueData(_formatDate(date), revenue));
      }
    }
    setState(() {
      _chartData = newData;
    });
  }

  void _updateMonthlyChartData() {
    // Tính số tháng giữa ngày bắt đầu và ngày kết thúc
    int months =
        (_endDate.year - _startDate.year) * 12 +
        _endDate.month -
        _startDate.month +
        1;

    List<MonthlyRevenueData> newMonthlyData = [];
    for (int i = 0; i < months; i++) {
      DateTime monthDate = DateTime(_startDate.year, _startDate.month + i, 1);
      String monthName = DateFormat('MMMM', 'vi_VN').format(monthDate);
      // Tính toán doanh thu cho tháng này (cần logic thực tế)
      double monthlyRevenue = 150.0 + i * 25.0;
      newMonthlyData.add(MonthlyRevenueData(monthName, monthlyRevenue));
    }
    setState(() {
      _monthlyChartData = newMonthlyData;
    });
  }

  void _updateQuarterlyChartData() {
    List<QuarterlyRevenueData> newQuarterlyData = [];
    // Logic tính toán số quý và doanh thu cho mỗi quý
    int startQuarter = (_startDate.month / 3).ceil();
    int endQuarter = (_endDate.month / 3).ceil();
    int quarters =
        (_endDate.year - _startDate.year) * 4 + endQuarter - startQuarter + 1;

    for (int i = 0; i < quarters; i++) {
      int quarter = startQuarter + i;
      int year = _startDate.year + ((quarter - 1) ~/ 4);
      if (quarter > 4) {
        quarter -= 4;
      }
      // Tính toán doanh thu cho quý (cần logic thực tế)
      double quarterlyRevenue = 200.0 + i * 35.0;
      newQuarterlyData.add(
        QuarterlyRevenueData(year, quarter, quarterlyRevenue),
      );
    }
    setState(() {
      _quarterlyChartData = newQuarterlyData;
    });
  }

  void _updateYearlyChartData() {
    List<YearlyRevenueData> newYearlyData = [];
    // Logic tính toán số năm và doanh thu cho mỗi năm
    int startYear = _startDate.year;
    int endYear = _endDate.year;
    int years = endYear - startYear + 1;

    for (int i = 0; i < years; i++) {
      int year = startYear + i;
      // Tính toán doanh thu cho năm (cần logic thực tế)
      double yearlyRevenue = 300 + i * 50.0;
      newYearlyData.add(YearlyRevenueData(year, yearlyRevenue));
    }
    setState(() {
      _yearlyChartData = newYearlyData;
    });
  }

  void _updateWeeklyChartData() {
    List<WeeklyRevenueData> newWeeklyData = [];
    // Calculate the number of weeks between start and end date
    int weeks = (_endDate.difference(_startDate).inDays / 7).ceil();

    for (int i = 0; i < weeks; i++) {
      DateTime weekStartDate = _startDate.add(Duration(days: i * 7));
      // Calculate revenue for the week
      double weeklyRevenue = 120.0 + i * 20;
      newWeeklyData.add(WeeklyRevenueData(weekStartDate, weeklyRevenue));
    }
    setState(() {
      _weeklyChartData = newWeeklyData;
    });
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
              height: 250, // Increased height for best selling products card
              child: ListView.builder(
                itemCount: _bestSellingProducts.length,
                itemBuilder: (context, index) {
                  final product = _bestSellingProducts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                    ), // Increased vertical padding
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
                          ), // Increased font size
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
  final double revenue;

  RevenueData(this.day, this.revenue);
}

// Mô hình dữ liệu cho doanh thu hàng tháng
class MonthlyRevenueData {
  final String monthName;
  final double revenue;

  MonthlyRevenueData(this.monthName, this.revenue);
}

// Mô hình dữ liệu cho doanh thu theo quý
class QuarterlyRevenueData {
  final int year;
  final int quarter;
  final double revenue;

  QuarterlyRevenueData(this.year, this.quarter, this.revenue);
}

// Mô hình dữ liệu cho doanh thu theo năm
class YearlyRevenueData {
  final int year;
  final double revenue;

  YearlyRevenueData(this.year, this.revenue);
}

// Data model for weekly revenue
class WeeklyRevenueData {
  final DateTime weekStartDate;
  final double revenue;

  WeeklyRevenueData(this.weekStartDate, this.revenue);
}

// Mô hình dữ liệu cho đơn hàng
class OrderData {
  final String date;
  final String orderId;
  final double amount;

  OrderData(this.date, this.orderId, this.amount);
}
