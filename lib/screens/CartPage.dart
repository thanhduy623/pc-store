import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_store/models/product.dart';
import 'package:my_store/screens/ConfirmOrderPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_store/screens/LoginDialog.dart';
import 'package:my_store/utils/moneyFormat.dart' as utils;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Product> listItems = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedItems = prefs.getStringList('localCart') ?? [];

    setState(() {
      listItems =
          savedItems.map((item) => Product.fromJson(jsonDecode(item))).toList();
    });
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encodedItems =
        listItems.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('localCart', encodedItems);
  }

  int getTotalProducts() {
    return listItems.where((item) => item.selected).length;
  }

  double getSubtotal() {
    return listItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      listItems[index].selected = !listItems[index].selected;
    });
    _saveCart();
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      listItems[index].quantity = newQuantity;
    });
    _saveCart();
  }

  void _removeItem(int index) {
    setState(() {
      listItems.removeAt(index);
    });
    _saveCart();
  }

  void _handleCheckout() async {
    User? user = FirebaseAuth.instance.currentUser;
    List<Product> selectedProducts = getSelectedProducts();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ít nhất một sản phẩm")),
      );
      return;
    }

    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ConfirmPage(
                selectedProducts: selectedProducts,
                userEmail: user.email,
              ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Đăng nhập để tích điểm?'),
            content: const Text(
              'Bạn có muốn đăng nhập để tích điểm cho đơn hàng này không?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ConfirmPage(
                            selectedProducts: selectedProducts,
                            userEmail: null,
                          ),
                    ),
                  );
                },
                child: const Text('Không'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showLoginDialog(
                    selectedProducts,
                  ); // Truyền danh sách sản phẩm đã chọn
                },
                child: const Text('Có'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showLoginDialog(List<Product> selectedProducts) {
    // Nhận danh sách sản phẩm
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LoginDialog(
          selectedProducts: selectedProducts,
        ); // Truyền danh sách sản phẩm vào dialog
      },
    );
  }

  List<Product> getSelectedProducts() {
    return listItems.where((item) => item.selected).toList();
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
                        shrinkWrap: true,
                        itemCount: listItems.length,
                        itemBuilder: (context, index) {
                          final item = listItems[index];
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
                                  Checkbox(
                                    value: item.selected,
                                    onChanged:
                                        (value) => _toggleSelection(index),
                                  ),
                                  item.image.isNotEmpty
                                      ? Image.memory(
                                        base64Decode(item.image),
                                        width: 100,
                                        height: 100,
                                      )
                                      : const Icon(
                                        Icons.image_not_supported,
                                        size: 100,
                                      ),
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
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Đơn giá: ${utils.moneyFormat(item.price)}',
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () {
                                                  if (item.quantity > 0) {
                                                    _updateQuantity(
                                                      index,
                                                      item.quantity - 1,
                                                    );
                                                  }
                                                },
                                              ),
                                              Text('${item.quantity}'),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed:
                                                    () => _updateQuantity(
                                                      index,
                                                      item.quantity + 1,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        utils.moneyFormat(
                                          item.price * item.quantity,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _removeItem(index),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng sản phẩm: ${getTotalProducts()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    'Tạm tính: ${utils.moneyFormat(getSubtotal())}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _handleCheckout,
                child: const Text('Thanh toán ngay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
