class CartItem {
  final String id;
  bool selected;
  final String name;
  final String productCode;
  int quantity;
  final double price;
  String image;

  CartItem({
    required this.id,
    required this.selected,
    required this.name,
    required this.productCode,
    required this.quantity,
    required this.price,
    required this.image,
  });

  // Phương thức từ Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '', // Nếu 'id' là null, sử dụng chuỗi rỗng
      selected:
          map['selected'] ?? false, // Mặc định là false nếu 'selected' là null
      name: map['name'] ?? 'Unnamed', // Mặc định 'Unnamed' nếu 'name' là null
      productCode:
          map['productCode'] ??
          '', // Mặc định chuỗi rỗng nếu 'productCode' là null
      quantity:
          map['quantity'] != null
              ? map['quantity'] as int
              : 0, // Kiểm tra null và ép kiểu an toàn
      price:
          map['price'] != null
              ? (map['price'] as num).toDouble()
              : 0.0, // Kiểm tra null và chuyển đổi an toàn
      image: map['image'] ?? '', // Mặc định chuỗi rỗng nếu 'image' là null
    );
  }
}
