import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class PriceUpdateScreen extends StatefulWidget {
  const PriceUpdateScreen({super.key});

  @override
  State<PriceUpdateScreen> createState() => _PriceUpdateScreenState();
}

class _PriceUpdateScreenState extends State<PriceUpdateScreen> {
  String _updateStatus = 'Chưa cập nhật';

  Future<void> updateProductPrices() async {
    setState(() {
      _updateStatus = 'Đang cập nhật giá...';
    });
    print('Bắt đầu cập nhật giá sản phẩm...');

    try {
      final QuerySnapshot<Map<String, dynamic>> productsSnapshot =
          await FirebaseFirestore.instance.collection('products').get();

      int updatedCount = 0;
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in productsSnapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        if (data.containsKey('price') && data['price'] != null) {
          final num currentPrice = data['price'];
          final double newPrice = currentPrice.toDouble() * 1000;

          await FirebaseFirestore.instance
              .collection('products')
              .doc(doc.id)
              .update({'price': newPrice});
          updatedCount++;
          print(
            'Đã cập nhật giá sản phẩm có ID: ${doc.id} từ ${currentPrice} lên ${newPrice}',
          );
        } else {
          print('Sản phẩm có ID: ${doc.id} không có trường "price", bỏ qua.');
        }
      }

      setState(() {
        _updateStatus = 'Đã cập nhật $updatedCount sản phẩm.';
      });
      print('Hoàn tất cập nhật giá tất cả sản phẩm.');
    } catch (e) {
      setState(() {
        _updateStatus = 'Lỗi cập nhật giá: $e';
      });
      print('Đã xảy ra lỗi khi cập nhật giá: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật giá sản phẩm')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Trạng thái: $_updateStatus',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProductPrices,
              child: const Text('Cập nhật giá x1000'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PriceUpdateScreen());
  }
}
