import 'package:flutter/material.dart';

class PriceRangeFilter extends StatelessWidget {
  final double? minPrice;
  final double? maxPrice;
  final Function(double?) onMinPriceChanged;
  final Function(double?) onMaxPriceChanged;

  const PriceRangeFilter({
    Key? key,
    required this.minPrice,
    required this.maxPrice,
    required this.onMinPriceChanged,
    required this.onMaxPriceChanged,
  }) : super(key: key);

  String formatPrice(double price) {
    return '${price.toInt()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<double>(
          value: minPrice,
          hint: const Text("Giá thấp nhất"),
          items: [
            const DropdownMenuItem<double>(
              value: null,
              child: Text('Tất cả'),
            ),
            for (var price in [0, 1000000, 5000000, 10000000, 20000000, 50000000])
              DropdownMenuItem(
                value: price.toDouble(),
                child: Text(formatPrice(price.toDouble())),
              ),
          ],
          onChanged: onMinPriceChanged,
        ),
        const SizedBox(width: 8),
        DropdownButton<double>(
          value: maxPrice,
          hint: const Text("Giá cao nhất"),
          items: [
            const DropdownMenuItem<double>(
              value: null,
              child: Text('Tất cả'),
            ),
            for (var price in [1000000, 5000000, 10000000, 20000000, 50000000, 100000000])
              DropdownMenuItem(
                value: price.toDouble(),
                child: Text(formatPrice(price.toDouble())),
              ),
          ],
          onChanged: onMaxPriceChanged,
        ),
      ],
    );
  }
} 