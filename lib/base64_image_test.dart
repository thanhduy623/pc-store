import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:my_store/utils/controllPicture.dart';

void main() {
  runApp(const MaterialApp(home: Base64TestScreen()));
}

class Base64TestScreen extends StatefulWidget {
  const Base64TestScreen({super.key});

  @override
  State<Base64TestScreen> createState() => _Base64TestScreenState();
}

class _Base64TestScreenState extends State<Base64TestScreen> {
  String base64Str = '';
  Uint8List? imageBytes;
  TextEditingController controller = TextEditingController();

  // Hàm chọn ảnh và chuyển đổi thành base64
  Future<void> _pickImage() async {
    Uint8List? bytes = await Base64ImageTool.pickImageUniversal();
    if (bytes != null) {
      String base64 = await Base64ImageTool.imageToBase64Async(
        bytes,
      ); // Await để chờ kết quả trả về
      setState(() {
        base64Str = base64;
        controller.text = base64;
      });
    }
  }

  // Hàm chuyển đổi Base64 thành ảnh
  void _convertBase64ToImage() {
    try {
      Uint8List image = Base64ImageTool.base64ToImage(controller.text);
      setState(() {
        imageBytes = image;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi giải mã: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Base64 ↔ Image")),
      body: Row(
        children: [
          // PHẢI: chọn ảnh → hiện chữ
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text("Chọn ảnh"),
                ),
                const SizedBox(height: 10),
                const Text("Base64 (auto fill):"),
                SelectableText(
                  base64Str.isNotEmpty
                      ? base64Str.substring(0, 100) + "..."
                      : "Chưa chọn ảnh",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          // TRÁI: dán chữ → hiện ảnh
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Dán chuỗi Base64 vào:"),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _convertBase64ToImage,
                  child: const Text("Hiển thị ảnh"),
                ),
                if (imageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.memory(imageBytes!, width: 300),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
