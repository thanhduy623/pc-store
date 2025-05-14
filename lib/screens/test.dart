import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

class OrderGenerator extends StatefulWidget {
  const OrderGenerator({super.key});

  @override
  State<OrderGenerator> createState() => _OrderGeneratorState();
}

class _OrderGeneratorState extends State<OrderGenerator> {
  String _generationStatus = 'Chưa tạo đơn hàng';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Danh sách ID người dùng bạn cung cấp
  final List<String> _userIds = [
    'vBDWwTR2uneOINj0SsLyEUad8uA3',
    'eprpnQtNuvh4WiOTLnisi6dpKAz2',
    'vBDWwTR2uneOINj0SsLyEUad8uA3',
    '3rUgJV80r2XHAdhNoqxEPxhNPEs2',
    '3zn4Pjx2zUXMRj59u7tqCXWesAc2',
    '5Jtmua7bd2hgP0hd5STtRJ75stX2',
    'DRdNS4wN0KRGAX19zIbIJdlvzfP2',
    'DgTZLKB0MAdYS09AefAzDIwyh6x1',
    'DvKt94fvkZeZxPLwB9zfLKszsq83',
    'DyvdtWiNyDXXGeDTJlV6Q2awjHK2',
    'GYqSkHGeRobqw6lzLHfmZWFmKt32',
    'IZnWg6BIKFc9TsZGA0Paqy73lgN2',
    'LmRu6u6wqKgMq3D7hI8YYvxpnCk2',
    'Pp6iz0pmrfbA7tWM1uUmeUm14ke2',
    'VPOEPxjZMSW7WnNCwBZCigtIjvg1',
    'WhmY4JUNqQSdFM0GNw3McGfzrcR2',
    'ZVSUWaK0KTebq42vChsRIKqEWDv2',
    'Zsd2ZIVqNBgC4AaqBVtwXAfrE302',
    'a6H2EKcb0cXb6BveGvmNKpxEK7B2',
  ];

  // Danh sách sản phẩm bạn cung cấp (chỉ lấy ID để random)
  final List<String> _productIds = [
    '1fgFk08X9UBnzeVuqfAo',
    '1tLaNSVyPmNoZYv51d6C',
    '2Oah1GnHlA3uEaZN6qat',
    '3jRmyCUCygqjcbvLoJ6j',
    '50008tbk3w9DxtlLyUaea0tp',
    '60009z6LcfowXTV1XbwKVGcG',
    '9z6LcfowXTV1XbwKVGcG',
    'ELyH87W0eEmu6MYpmoWU',
    'EueSSQSR6qWphlkdleSP',
    'GqoZWFLTxkvxUOTSv5Kn',
    'K9ViIqXVh7WdPRnoxQCA',
    'OvJnScaDVTStfJhTeDeV',
    'TT0NcK6LGBgy2V8uE0A3',
    'TjW2Kta7XRZ6SJgmGmoi',
    'WN6tdbD6Qmo6mD0PDdpP',
    'X636bhT02YvLTIF2yefr',
    'Xl4imFLzxLfFjkmb5fCp',
    'Ybka3tnFQvC5Jop1vr1M',
    'fcLQhql9y1M0aqyz5t9I',
    'ffLHyCJABrWH71soVQzf',
    'guWBvsOfqxzbGyiBTfIE',
    'hKLha9vcw7kvDrJOo72k',
    'i7VxQw6rDcBWx9cCW6XF',
    'iLpyLJVXC9uDUuwacZZE',
    'k36i4JKjHnvYD2MCejSR',
    'ljCqz1D5O3t68ZkdFu6E',
    'nvV4jfXvQax8tiIDNebN',
    'skvE7gs4Pop5kwV1u2de',
    'td9wbIV8KICaCbqnh25C',
    'uOvg6EHiAliNL4yw82rd',
    'w1L3BcgXbJeC4V8p5CmH',
    'xwtlqb1VJPbQKcOF1UTs',
  ];

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

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> _getProductData(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return {'name': 'Unknown', 'price': 0.0};
  }

  Future<void> _createFakeOrders() async {
    setState(() {
      _generationStatus = 'Đang tạo 100 đơn hàng...';
    });
    print('Bắt đầu tạo 100 đơn hàng...');

    for (int i = 0; i < 100; i++) {
      // Lấy ngẫu nhiên một user ID
      final randomUserIdIndex = _random.nextInt(_userIds.length);
      final userId = _userIds[randomUserIdIndex];
      final userData = await _getUserData(userId) ?? {};

      if (userData.isEmpty) {
        print(
          'Không tìm thấy thông tin người dùng cho ID: $userId, bỏ qua đơn hàng $i.',
        );
        continue;
      }

      final fullName = userData['fullName'] ?? 'Khách hàng ngẫu nhiên';
      final phoneNumber = userData['phoneNumber'] ?? '0123456789';
      final email = userData['email'] ?? 'guest@example.com';
      final shippingAddress =
          userData['shippingAddress'] ?? 'Địa chỉ ngẫu nhiên';

      // Tạo ngẫu nhiên số lượng sản phẩm trong đơn hàng
      final numberOfItems = _random.nextInt(3) + 1;
      List<Map<String, dynamic>> items = [];
      double subtotal = 0;

      for (int j = 0; j < numberOfItems; j++) {
        final randomProductIdIndex = _random.nextInt(_productIds.length);
        final productId = _productIds[randomProductIdIndex];
        final productData =
            await _getProductData(productId) ??
            {'name': 'Unknown', 'price': 0.0};
        final productName = productData['name'] as String? ?? 'Sản phẩm';
        final unitPrice = (productData['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = _random.nextInt(3) + 1;
        final totalPrice = unitPrice * quantity;
        subtotal += totalPrice;
        items.add({
          'productId': productId,
          'productName': productName,
          'quantity': quantity,
          'unitPrice': unitPrice,
          'totalPrice': totalPrice,
        });
      }

      final discountFromPoints =
          _random.nextDouble() * 20000; // Giảm giá từ điểm ngẫu nhiên
      final discountFromCode =
          _random.nextBool() ? 10000.0 : 0.0; // Thỉnh thoảng có mã giảm giá
      final shippingFee = _random.nextInt(5) * 10000.0; // Phí ship ngẫu nhiên
      final vat = subtotal * 0.08;
      final total =
          subtotal - discountFromPoints - discountFromCode + shippingFee + vat;

      // Tạo orderDate ngẫu nhiên từ tháng 5/2024 đến nay
      final startDate = DateTime(2024, 5, 1);
      final endDate = DateTime.now();
      final durationInMillis = endDate.difference(startDate).inMilliseconds;
      final randomOffset = _random.nextDouble() * durationInMillis;
      final randomTimestamp =
          startDate.millisecondsSinceEpoch + randomOffset.toInt();
      final orderDate = DateTime.fromMillisecondsSinceEpoch(randomTimestamp);

      // Tạo lịch sử trạng thái đơn hàng ngẫu nhiên
      Map<String, Timestamp> statusHistory = {
        'Chờ xử lý': Timestamp.fromDate(orderDate),
      };
      String currentStatus = 'Chờ xử lý';
      for (int s = 0; s < _random.nextInt(4); s++) {
        final nextStatus = _getNextStatus(currentStatus);
        if (nextStatus != null) {
          final lastTime = statusHistory.values.last.toDate();
          final nextTime = lastTime.add(
            Duration(hours: _random.nextInt(24) + 1),
          );
          statusHistory[nextStatus] = Timestamp.fromDate(nextTime);
          currentStatus = nextStatus;
        } else {
          break;
        }
      }

      final orderData = {
        'userId': userId,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'shippingAddress': shippingAddress,
        'subtotal': subtotal,
        'discountFromPoints': discountFromPoints,
        'discountFromCode': discountFromCode,
        'shippingFee': shippingFee,
        'vat': vat,
        'total': total < 0 ? 0 : total, // Đảm bảo total không âm
        'orderDate': Timestamp.fromDate(orderDate),
        'status': statusHistory,
        'items': items,
      };

      await _firestore.collection('orders').add(orderData);
      print('Đã tạo đơn hàng thứ ${i + 1} cho người dùng: $fullName');
    }

    setState(() {
      _generationStatus = 'Đã tạo 100 đơn hàng.';
    });
    print('Hoàn tất tạo 100 đơn hàng.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo 100 đơn hàng ngẫu nhiên.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Đơn Hàng Hàng Loạt')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Trạng thái: $_generationStatus',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createFakeOrders,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tạo 100 Đơn Hàng Ngẫu Nhiên',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: OrderGenerator());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
