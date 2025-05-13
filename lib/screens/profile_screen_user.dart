import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProfileScreenUser extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreenUser({Key? key, this.userData}) : super(key: key);

  @override
  State<ProfileScreenUser> createState() => _ProfileScreenUserState();
}

class _ProfileScreenUserState extends State<ProfileScreenUser> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isBlocked = false;
  int _userPoints = 0;
  String? _userId; // Store the user ID

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.userData != null) {
      // Safely access data using the null-aware operator and provide defaults
      _userId = widget.userData!['id']; // Get the user ID
      final userDataFields =
          widget.userData!['data'] ?? {}; // Get the nested data

      _fullNameController.text = userDataFields['fullName'] ?? '';
      _addressController.text = userDataFields['shippingAddress'] ?? '';
      _phoneController.text =
          userDataFields['phone'] ?? userDataFields['phoneNumber'] ?? '';
      _isBlocked = userDataFields['isBlocked'] ?? false;
      _userPoints = userDataFields['points'] ?? 0; // Load điểm
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId) // Use the stored user ID
              .update({
                'fullName': _fullNameController.text.trim(),
                'shippingAddress': _addressController.text.trim(),
                'phone': _phoneController.text.trim(),
              });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hồ sơ đã được cập nhật')),
          );
          setState(() {
            _isEditing = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lưu: Không có ID người dùng'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
      }
    }
  }

  Future<void> _toggleBlockStatus() async {
    try {
      if (_userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId) // Use the stored user ID
            .update({'isBlocked': !_isBlocked});
        setState(() {
          _isBlocked = !_isBlocked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBlocked ? 'Tài khoản đã bị khóa' : 'Tài khoản đã được mở khóa',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể thay đổi trạng thái: Không có ID người dùng',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin người dùng')),
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
                      child: CircleAvatar(
                        radius: 70,
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.grey.shade400,
                        // You can add backgroundImage if you have an avatar URL
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    if (_userPoints != null)
                      Text(
                        'Điểm: $_userPoints',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                        ElevatedButton(
                          onPressed: _toggleBlockStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isBlocked ? Colors.red : Colors.green,
                          ),
                          child: Text(
                            _isBlocked ? 'Mở tài khoản' : 'Khóa tài khoản',
                            style: const TextStyle(color: Colors.white),
                          ),
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
