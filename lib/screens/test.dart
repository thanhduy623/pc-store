import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddToCartScreen extends StatelessWidget {
  const AddToCartScreen({super.key});

  String? get userId => FirebaseAuth.instance.currentUser?.email;

  // ✅ Tạo sản phẩm demo đúng định dạng CartItem
  Map<String, dynamic> createSampleProduct() {
    const sampleImage = ''; // base64 nếu cần
    return {
      'id': 'sp001',
      'selected': false,
      'name': 'Sản phẩm demo',
      'productCode': 'CODE123',
      'quantity': 1,
      'price': 199000.0,
      'image': sampleImage,
    };
  }

  // ✅ Thêm sản phẩm vào Firestore
  Future<void> addToFirestoreCart(BuildContext context) async {
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Chưa đăng nhập")));
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection('carts');
    final newItem = createSampleProduct();

    try {
      final snapshot = await cartRef.where('userId', isEqualTo: userId).get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final existingItems = List<Map<String, dynamic>>.from(doc['cartItems']);

        // Kiểm tra trùng ID sản phẩm
        final index = existingItems.indexWhere(
          (item) => item['id'] == newItem['id'],
        );
        if (index != -1) {
          // Nếu đã tồn tại thì tăng số lượng
          existingItems[index]['quantity'] += 1;
        } else {
          existingItems.add(newItem);
        }

        await cartRef.doc(doc.id).update({'cartItems': existingItems});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã thêm vào giỏ hàng hiện tại")),
        );
      } else {
        await cartRef.add({
          'userId': userId,
          'cartItems': [newItem],
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🛒 Đã tạo giỏ hàng mới và thêm sản phẩm"),
          ),
        );
      }
    } catch (e) {
      print("Lỗi khi thêm sản phẩm: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Lỗi: $e")));
    }
  }

  // ✅ Lưu sản phẩm vào local (SharedPreferences)
  Future<void> saveProductToLocal(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final product = createSampleProduct();

    List<String> currentList = prefs.getStringList('localCart') ?? [];
    currentList.add(jsonEncode(product));

    await prefs.setStringList('localCart', currentList);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("📦 Sản phẩm đã lưu cục bộ")));
  }

  // ❌ Xoá toàn bộ sản phẩm local
  Future<void> clearLocalCart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('localCart');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ Đã xoá toàn bộ sản phẩm local")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm vào giỏ hàng")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => addToFirestoreCart(context),
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Thêm sản phẩm vào Firestore"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => saveProductToLocal(context),
              icon: const Icon(Icons.save_alt),
              label: const Text("Lưu sản phẩm vào local"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => clearLocalCart(context),
              icon: const Icon(Icons.delete_forever),
              label: const Text("Xoá toàn bộ sản phẩm local"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
