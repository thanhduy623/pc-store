import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // Tải danh sách tỉnh/thành
  static Future<List<Map<String, dynamic>>> fetchProvinces() async {
    final response = await http.get(
      Uri.parse('https://provinces.open-api.vn/api/?depth=1'),
    );
    if (response.statusCode == 200) {
      final responseString = utf8.decode(response.bodyBytes);
      List<dynamic> provinces = json.decode(responseString);
      return provinces.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Không thể tải danh sách tỉnh/thành');
    }
  }

  // Tải danh sách quận/huyện theo mã tỉnh
  static Future<List<Map<String, dynamic>>> fetchDistricts(
    int provinceCode,
  ) async {
    final response = await http.get(
      Uri.parse('https://provinces.open-api.vn/api/p/$provinceCode?depth=2'),
    );
    if (response.statusCode == 200) {
      final responseString = utf8.decode(response.bodyBytes);
      Map<String, dynamic> data = json.decode(responseString);
      return (data['districts'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Không thể tải danh sách quận/huyện');
    }
  }

  // Tải danh sách xã/phường theo mã huyện
  static Future<List<Map<String, dynamic>>> fetchWards(int districtCode) async {
    final response = await http.get(
      Uri.parse('https://provinces.open-api.vn/api/d/$districtCode?depth=2'),
    );
    if (response.statusCode == 200) {
      final responseString = utf8.decode(response.bodyBytes);
      Map<String, dynamic> data = json.decode(responseString);
      return (data['wards'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Không thể tải danh sách xã/phường');
    }
  }
}
