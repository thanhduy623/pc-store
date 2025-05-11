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

  // Retrieve the current cart from SharedPreferences
  List<String> currentList = prefs.getStringList('localCart') ?? [];

  // Check if the current list is empty
  if (currentList.isEmpty) {
    // If empty, initialize it with an empty list or proceed with adding new product
    currentList = [];
  }

  // Check if the product already exists in the cart
  bool productFound = false;

  for (int i = 0; i < currentList.length; i++) {
    Map<String, dynamic> product = jsonDecode(currentList[i]);
    if (product['productId'] == productId) {
      // Update the existing product
      product['name'] = name;
      product['price'] = price;
      product['image'] = image;
      product['quantity'] += 1; // Increment quantity

      // Update the product in the list
      currentList[i] = jsonEncode(product);
      productFound = true;
      break;
    }
  }

  // If the product is not found, add a new one
  if (!productFound) {
    Map<String, dynamic> newProduct = {
      'id':
          DateTime.now().millisecondsSinceEpoch.toString(), // Generate a new ID
      'selected': false,
      'name': name,
      'productId': productId,
      'quantity': 1,
      'price': price,
      'image': image,
    };

    // Add the new product to the cart
    currentList.add(jsonEncode(newProduct));
  }

  // Save the updated cart to SharedPreferences
  await prefs.setStringList('localCart', currentList);

  // Show a snackbar to notify the user
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("📦 Sản phẩm đã được thêm vào giỏ")),
  );
}
