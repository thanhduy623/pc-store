import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendEmailViaEmailJS(
  String customerEmail,
  String customerName,
  Map<String, dynamic> order,
) async {
  const serviceId = 'flutter-final';
  const templateId = 'flutter-final';
  const userId = 'sGRJhpxs3KrGCaYEQ';

  String orderItems = '';
  for (var item in order['items']) {
    orderItems += '''
      Sản phẩm: ${item['productName']} - Số lượng: ${item['quantity']} - Đơn giá: ${item['unitPrice']} đ - Thành tiền: ${item['totalPrice']} đ\n
    ''';
  }

  final data = {
    'service_id': serviceId,
    'template_id': templateId,
    'user_id': userId,
    'template_params': {
      'to_email': customerEmail,
      'to_name': customerName,
      'shipping_address': order['shippingAddress'],
      'order_date': order['orderDate'].toString(),
      'order_items':
          orderItems, // Thêm thông tin chi tiết đơn hàng ở dạng văn bản
      'subtotal': order['subtotal'].toString(),
      'discount':
          (order['discountFromPoints'] + order['discountFromCode']).toString(),
      'shipping_fee': order['shippingFee'].toString(),
      'total': order['total'].toString(),
    },
  };

  try {
    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      print('✅ Email sent successfully');
    } else {
      print('❌ Email send failed: ${response.body}');
    }
  } catch (e) {
    print('❌ Email exception: $e');
  }
}
