import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<void> addProductToCart(
  BuildContext context,
  String productId,
  String name,
  double price,
  String image,
) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> savedItems = prefs.getStringList('localCart') ?? [];

  bool productFound = false; // Đổi tên biến cho rõ ràng hơn
  int existingProductIndex = -1; // Thêm biến để lưu vị trí sản phẩm đã tồn tại

  // Lặp qua các sản phẩm trong giỏ hàng để kiểm tra sản phẩm đã tồn tại chưa
  for (int i = 0; i < savedItems.length; i++) {
    Map<String, dynamic> product = jsonDecode(savedItems[i]);
    if (product['productId'] == productId) {
      productFound = true;
      existingProductIndex = i; // Lưu lại index
      break;
    }
  }

  if (productFound) {
    // Nếu sản phẩm đã tồn tại, cập nhật số lượng
    Map<String, dynamic> existingProduct = jsonDecode(
      savedItems[existingProductIndex],
    );
    existingProduct['quantity'] = (existingProduct['quantity'] ?? 0) + 1;
    // Cập nhật các thông tin khác của sản phẩm
    existingProduct['name'] = name;
    existingProduct['price'] = price;
    existingProduct['image'] = image;
    savedItems[existingProductIndex] = jsonEncode(
      existingProduct,
    ); // Cập nhật lại vào savedItems
  } else {
    // Nếu sản phẩm chưa tồn tại, thêm mới vào giỏ hàng
    Map<String, dynamic> newProduct = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'selected': false,
      'name': name,
      'productId': productId,
      'quantity': 1,
      'price': price,
      'image': image,
    };
    savedItems.add(jsonEncode(newProduct));
  }

  // Lưu danh sách giỏ hàng đã cập nhật
  await prefs.setStringList('localCart', savedItems);

  // Thông báo cho người dùng
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("📦 Sản phẩm đã được thêm vào giỏ")),
  );
}
