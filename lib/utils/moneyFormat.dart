import 'package:intl/intl.dart';

String moneyFormat(double amount) {
  final formatter = NumberFormat("#,###", "vi_VN");
  return "${formatter.format(amount)} đ";
}
