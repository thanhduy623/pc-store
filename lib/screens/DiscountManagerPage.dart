import 'package:flutter/material.dart';
import 'AddDiscountPage.dart';

class DiscountManagerPage extends StatefulWidget {
  const DiscountManagerPage({super.key});

  @override
  State<DiscountManagerPage> createState() => _DiscountManagerPageState();
}

class _DiscountManagerPageState extends State<DiscountManagerPage> {
  List<Map<String, dynamic>> discounts = [
    {
      'code': 'GIAM20',
      'type': 'Phần trăm',
      'value': 20,
      'expiry': '2025-06-01',
    },
    {
      'code': 'SALE50K',
      'type': 'Cụ thể',
      'value': 50000,
      'expiry': '2025-05-10',
    },
  ];

  void _deleteDiscount(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Xác nhận xóa"),
          content: const Text("Bạn có chắc chắn muốn xóa mã giảm giá này?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Hủy"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  discounts.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: const Text("Xóa"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAdd() async {
    final newDiscount = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDiscountPage()),
    );

    if (newDiscount != null) {
      setState(() {
        discounts.add(newDiscount);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý mã giảm giá')),
      body: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Mã')),
            DataColumn(label: Text('Loại')),
            DataColumn(label: Text('Giá trị')),
            DataColumn(label: Text('Ngày hết hạn')),
            DataColumn(label: Text('Hành động')),
          ],
          rows: List.generate(discounts.length, (index) {
            final item = discounts[index];
            return DataRow(
              cells: [
                DataCell(Text(item['code'])),
                DataCell(Text(item['type'])),
                DataCell(
                  Text(
                    item['type'] == 'Phần trăm'
                        ? '${item['value']}%'
                        : '${item['value']}đ',
                  ),
                ),
                DataCell(Text(item['expiry'])),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDiscount(index),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
        tooltip: 'Thêm mã mới',
      ),
    );
  }
}
