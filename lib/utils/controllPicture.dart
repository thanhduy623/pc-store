import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';

class Base64ImageTool {
  // Chuyển ảnh (Uint8List) thành chuỗi base64 (dùng JPEG để tăng tốc)
  static Future<String> imageToBase64Async(Uint8List bytes) async {
    return await compute(_convertToBase64, bytes);
  }

  // Hàm chạy trên isolate để chuyển đổi ảnh sang Base64
  static String _convertToBase64(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception("Không thể decode ảnh.");
    // Resize ảnh nếu cần thiết (Ví dụ: 200x200)
    final resized = img.copyResize(image, width: 200);
    // Sử dụng JPEG thay vì PNG để tiết kiệm thời gian encode
    final encoded = img.encodeJpg(
      resized,
      quality: 80,
    ); // Giảm chất lượng 80 để giảm dung lượng
    return base64Encode(encoded);
  }

  // Chuyển chuỗi base64 về Uint8List để dùng cho Image.memory
  static Uint8List base64ToImage(String base64Str) {
    try {
      return base64Decode(base64Str);
    } catch (e) {
      throw Exception("Base64 không hợp lệ: $e");
    }
  }

  // Hàm chọn ảnh (Hỗ trợ cả web, Android, iOS)
  static Future<Uint8List?> pickImageUniversal() async {
    try {
      if (kIsWeb) {
        // Web: dùng image_picker_web
        final image = await ImagePickerWeb.getImageAsBytes();
        return image;
      } else {
        // Android/iOS: dùng image_picker
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          return await pickedFile.readAsBytes();
        }
      }
    } catch (e) {
      print("❌ Lỗi khi chọn ảnh: $e");
    }
    return null;
  }

  // Hàm chọn ảnh và chuyển sang base64 ngay lập tức
  static Future<String?> pickImageAndConvertToBase64() async {
    final bytes = await pickImageUniversal();
    if (bytes != null) {
      return await imageToBase64Async(bytes); // Chuyển ảnh sang Base64
    }
    return null;
  }
}
