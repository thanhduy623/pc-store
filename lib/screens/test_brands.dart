import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestBrands extends StatefulWidget {
  const TestBrands({super.key});

  @override
  _TestBrandsState createState() => _TestBrandsState();
}

class _TestBrandsState extends State<TestBrands> {
  Future<void> _addBrands() async {
    final brands = [
      {
        'name': 'Dell',
        'categoryId': 'pwDWaExp9dPw8gBX0Axo', // Máy tính
      },
      {
        'name': 'Lenovo',
        'categoryId': 'pwDWaExp9dPw8gBX0Axo', // Máy tính
      },
      {
        'name': 'Logitech',
        'categoryId': '5M61T1GxwnRSofXpcVx7', // Chuột
      },
      {
        'name': 'Razer',
        'categoryId': '5M61T1GxwnRSofXpcVx7', // Chuột
      },
      {
        'name': 'Corsair',
        'categoryId': '3rDThXC0GKoIczz7OEd9', // Bàn phím
      },
      {
        'name': 'Ducky',
        'categoryId': '3rDThXC0GKoIczz7OEd9', // Bàn phím
      },
      {
        'name': 'Kingston',
        'categoryId': '8WwT4NpCTONEUHj7f1kp', // Bộ nhớ
      },
      {
        'name': 'Samsung',
        'categoryId': '8WwT4NpCTONEUHj7f1kp', // Màn hình
      },
      {
        'name': 'Samsung',
        'categoryId': 'x0xDhxaQFzoqrp30dgD9', // Màn hình
      },
    ];

    for (var brand in brands) {
      await FirebaseFirestore.instance.collection('brands').add(brand);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thêm Thương Hiệu')),
      body: Center(
        child: ElevatedButton(
          onPressed: _addBrands,
          child: Text('Thêm Thương Hiệu'),
        ),
      ),
    );
  }
}
