// lib/models/product.dart
class Product {
  String id;
  String productId;
  String name;
  int quantity;
  double price;
  String image;
  bool selected;

  Product({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
    required this.selected,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'image': image,
      'selected': selected,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] ?? '',
      selected: json['selected'] ?? false,
    );
  }
}
