class CartItem {
  bool selected;
  final String imageUrl;
  final String name;
  final String productCode;
  int quantity;
  final double price;
  String image;

  CartItem({
    required this.selected,
    required this.imageUrl,
    required this.name,
    required this.productCode,
    required this.quantity,
    required this.price,
    required this.image,
  });
}
