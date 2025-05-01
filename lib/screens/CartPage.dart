import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_store/utils/moneyFormat.dart';
import 'package:my_store/screens/ConfirmOrderPage.dart';
import 'package:my_store/services/firebase/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_store/models/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final userId = FirebaseAuth.instance.currentUser?.email;
  FirestoreService fb = FirestoreService();
  List<CartItem> listItems = []; // Change to List<CartItem> type

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (userId != null) {
        // Logged in, fetch data from Firebase
        List<Map<String, dynamic>> data = await fb.getDataWithExactMatch(
          "carts",
          {"userId": userId},
        );

        setState(() {
          // Safely convert Map<String, dynamic> to CartItem
          listItems = data.map((item) => CartItem.fromMap(item)).toList();
        });
      } else {
        // Not logged in, fetch from local storage
        final prefs = await SharedPreferences.getInstance();
        String? cartListJson = prefs.getString('cartList');

        if (cartListJson != null) {
          List<dynamic> cartList = jsonDecode(cartListJson);
          setState(() {
            // Safely convert Map<String, dynamic> to CartItem
            listItems = cartList.map((item) => CartItem.fromMap(item)).toList();
          });
        }
      }
    } catch (e) {
      print("Error loading cart data: $e");
      setState(() {
        listItems = []; // In case of error, ensure we display an empty list
      });
    }
  }

  // Toggle the selection state of a product
  void _toggleSelection(int index) {
    setState(() {
      listItems[index].selected = !listItems[index].selected;
    });
  }

  // Remove the item from cart
  void _removeItem(int index) {
    setState(() {
      listItems.removeAt(index);
    });
  }

  // Calculate total products and subtotal
  int getTotalProducts() {
    return listItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double getSubtotal() {
    return listItems.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body:
          listItems.isEmpty
              ? const Center(child: Text('Giỏ hàng của bạn trống!'))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap:
                            true, // Prevents ListView from taking too much space
                        itemCount: listItems.length,
                        itemBuilder: (context, index) {
                          final item = listItems[index];
                          final price = item.price;
                          final quantity = item.quantity;
                          final name = item.name;
                          final image = item.image;
                          final selected = item.selected;

                          return Slidable(
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Column 1: Checkbox
                                  Checkbox(
                                    value: selected,
                                    onChanged: (bool? value) {
                                      _toggleSelection(index);
                                    },
                                  ),
                                  // Column 2: Image (100x100)
                                  image.isNotEmpty
                                      ? Image.memory(
                                        base64Decode(image),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                      : const Icon(
                                        Icons.image_not_supported,
                                        size: 100,
                                      ),
                                  // Column 3: Name, Price, Quantity
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Đơn giá: ${moneyFormat(price)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () {
                                                  if (quantity > 1) {
                                                    setState(() {
                                                      listItems[index]
                                                          .quantity--;
                                                    });
                                                  }
                                                },
                                              ),
                                              Text('$quantity'),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  setState(() {
                                                    listItems[index].quantity++;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Column 4: Total Price and Delete Button
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${moneyFormat(price * quantity)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          _removeItem(index);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Column 1: Total Products and Subtotal
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng sản phẩm: ${getTotalProducts()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    'Tạm tính: ${moneyFormat(getSubtotal())}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              // Column 2: Pay Now Button
              ElevatedButton(
                onPressed: () {
                  // Filter selected items (checkbox == true)
                  List<CartItem> selectedItems =
                      listItems.where((item) => item.selected).toList();

                  if (selectedItems.isNotEmpty) {
                    // Navigate to ConfirmOrderPage with selected items
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ConfirmOrderPage(selectedItems: selectedItems),
                      ),
                    );
                  } else {
                    // Show message if no items are selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chưa chọn sản phẩm!')),
                    );
                  }
                },
                child: const Text('Thanh toán ngay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
