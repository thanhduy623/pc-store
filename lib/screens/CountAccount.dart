import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key});

  @override
  _AmountScreenState createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.refFromURL(
    'https://my-store-fb27a-default-rtdb.firebaseio.com/',
  ); // Đặt URL Firebase Realtime Database

  int _amount = 0; // Biến lưu giá trị amount

  @override
  void initState() {
    super.initState();
    // Gọi hàm lắng nghe sự thay đổi của dữ liệu khi màn hình được tạo
    listenForChanges();
  }

  // Lắng nghe sự thay đổi của dữ liệu và cập nhật UI
  void listenForChanges() {
    _databaseRef.child('users').onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _amount =
              data['amount'] ??
              0; // Cập nhật giá trị _amount khi dữ liệu thay đổi
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Số Lượng Người Dùng Đã Đăng Ký')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'SỐ LƯỢNG NGƯỜI DÙNG ĐÃ ĐĂNG KÝ LÀ:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '$_amount', // Hiển thị giá trị amount
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
