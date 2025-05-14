import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceRangeFilter extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final Function(double?) onMinPriceChanged;
  final Function(double?) onMaxPriceChanged;

  const PriceRangeFilter({
    Key? key,
    this.minPrice,
    this.maxPrice,
    required this.onMinPriceChanged,
    required this.onMaxPriceChanged,
  }) : super(key: key);

  @override
  State<PriceRangeFilter> createState() => _PriceRangeFilterState();
}

class _PriceRangeFilterState extends State<PriceRangeFilter> {
  RangeValues _currentRangeValues = const RangeValues(0, 100000000);
  final double _min = 0;
  final double _max = 100000000;

  @override
  void initState() {
    super.initState();
    _currentRangeValues = RangeValues(
      widget.minPrice ?? _min,
      widget.maxPrice ?? _max,
    );
  }

  String _formatPrice(double value) {
    final format = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                alignment: Alignment.centerLeft,
                child: Text(_formatPrice(_currentRangeValues.start)),
              ),
              Container(
                width: 120,
                alignment: Alignment.centerRight,
                child: Text(_formatPrice(_currentRangeValues.end)),
              ),
            ],
          ),
        ),
        RangeSlider(
          values: _currentRangeValues,
          min: _min,
          max: _max,
          divisions: 100,
          onChanged: (RangeValues values) {
            // Kiểm tra khoảng cách tối thiểu (5% của tổng khoảng)
            final minDistance = (_max - _min) / 20;
            if (values.end - values.start >= minDistance) {
              setState(() {
                _currentRangeValues = values;
              });
              widget.onMinPriceChanged(values.start);
              widget.onMaxPriceChanged(values.end);
            }
          },
        ),
      ],
    );
  }
}
