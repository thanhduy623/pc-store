import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:my_store/utils/controllPicture.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController =
      TextEditingController(); // Thêm controller cho số điện thoại

  User? user = FirebaseAuth.instance.currentUser;
  String email = '';
  String? _avatarBase64;
  Uint8List? _displayAvatarBytes; // Để hiển thị ảnh
  int _userPoints = 0; // Điểm của người dùng

  bool _isEditing = false; // Trạng thái chỉnh sửa
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Gọi hàm tải dữ liệu ban đầu
    if (user != null) {
      email = user!.email!;
    }
  }

  Future<void> _loadInitialData() async {
    if (user != null) {
      await _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData =
            userDoc.data() as Map<String, dynamic>; // Cast the data
        _fullNameController.text = userData['fullName'] ?? '';
        _addressController.text = userData['shippingAddress'] ?? '';
        _phoneController.text = userData['phone'] ?? ''; // Load số điện thoại
        _avatarBase64 = userData['avatar'];
        _userPoints = userData['points'] ?? 0; // Load điểm

        // Chuyển đổi base64 thành Uint8List để hiển thị ảnh
        if (_avatarBase64 != null) {
          try {
            _displayAvatarBytes = Base64ImageTool.base64ToImage(_avatarBase64!);
          } catch (e) {
            print('Lỗi Base64: $e');
            _avatarBase64 = null; // Đặt lại nếu lỗi chuyển đổi
            _displayAvatarBytes = null;
          }
        } else {
          _displayAvatarBytes =
              null; // Đảm bảo _displayAvatarBytes là null nếu không có avatar
        }
        if (mounted) {
          setState(() {});
        }
      } else {
        // Nếu không có dữ liệu người dùng, tạo mới
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
          {
            'fullName': '',
            'shippingAddress': '',
            'phone': '', // Khởi tạo số điện thoại
            'avatar': null,
            'points': 0, // Khởi tạo điểm
          },
        );
        _loadUserData(); //load lại để hiển thị
      }
    } catch (e) {
      print("Lỗi khi tải dữ liệu người dùng: $e"); // Log lỗi
      // Hiển thị thông báo lỗi cho người dùng (tùy chọn)
      if (mounted) {
        // Kiểm tra nếu widget vẫn còn trong cây
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
              'fullName': _fullNameController.text.trim(),
              'shippingAddress': _addressController.text.trim(),
              'phone': _phoneController.text.trim(), // Lưu số điện thoại
              'avatar': _avatarBase64,
            });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hồ sơ đã được cập nhật')));
        setState(() {
          _isEditing = false; // Chuyển về trạng thái xem sau khi lưu
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
      }
    }
  }

  Future<void> _changePassword() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_newPasswordController.text.trim().isEmpty) {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Lỗi'),
                          content: const Text('Vui lòng nhập mật khẩu mới.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                  return;
                }
                if (_newPasswordController.text.trim() !=
                    _confirmPasswordController.text.trim()) {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Lỗi'),
                          content: const Text('Mật khẩu không khớp.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                  return;
                }
                _changePasswordAction();
              },
              child: const Text('Xác nhận'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePasswordAction() async {
    try {
      await user!.updatePassword(_newPasswordController.text.trim());
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Thành công'),
              content: const Text('Đã đổi mật khẩu thành công.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Lỗi'),
              content: Text('Lỗi: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _changeAvatar() async {
    if (_isEditing) {
      final pickedImage = await Base64ImageTool.pickImageUniversal();
      if (pickedImage != null) {
        // Hiển thị ngay ảnh vừa chọn (chưa chuyển sang base64)
        setState(() {
          _displayAvatarBytes = pickedImage;
        });

        // Chuyển đổi sang base64 ở background
        Base64ImageTool.imageToBase64Async(pickedImage)
            .then((base64String) {
              setState(() {
                _avatarBase64 = base64String;
              });
            })
            .catchError((error) {
              print("Lỗi chuyển đổi Base64: $error");
              // Xử lý lỗi nếu cần
            });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose(); // Dispose phone controller
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý hồ sơ')),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _changeAvatar,
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage:
                              _displayAvatarBytes != null
                                  ? MemoryImage(_displayAvatarBytes!)
                                      as ImageProvider
                                  : null, // Hiển thị ảnh từ Firebase
                          child:
                              _displayAvatarBytes == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      readOnly: true,
                      initialValue: email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextFormField(
                      controller: _fullNameController,
                      readOnly: !_isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Họ tên đầy đủ',
                      ),
                      validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _addressController,
                      readOnly: !_isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ giao hàng',
                      ),
                      validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) {
                          return 'Vui lòng nhập địa chỉ';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _phoneController,
                      readOnly: !_isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                      validator: (value) {
                        if (_isEditing) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
                            return 'Số điện thoại không hợp lệ';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Điểm của bạn: $_userPoints',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nút Sửa/Lưu
                        _isEditing
                            ? ElevatedButton(
                              onPressed: _saveProfile,
                              child: const Text('Lưu'),
                            )
                            : OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              child: const Text('Sửa'),
                            ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _changePassword,
                          child: const Text('Đổi mật khẩu'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            FirebaseAuth.instance.signOut();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
