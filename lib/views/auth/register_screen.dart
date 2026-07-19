import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Các Bộ điều khiển lấy dữ liệu nhập vào
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController(); // Nếu bạn muốn thêm trường username riêng biệt
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Đường dẫn API xử lý đăng ký (Laragon)
      final url = Uri.parse('http://192.168.1.250/myapi/src/Controllers/RegisterController.php');

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "FullName": _fullNameController.text.trim(),
            "Username": _usernameController.text.trim(),
            "Email": _emailController.text.trim(),
            "PhoneNumber": _phoneController.text.trim(),
            "Password": _passwordController.text.trim(),
            "Role": "KhachHang", // Tự động gắn mặc định là khách thuê khi đẩy lên PHP
          }),
        ).timeout(const Duration(seconds: 10));

        final responseData = jsonDecode(response.body);

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 201 && responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký tài khoản thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Đăng ký xong, tự động quay về màn hình Login
        } else {
          _showErrorDialog(responseData['message'] ?? 'Đăng ký thất bại');
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog("Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại cấu hình mạng!");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 8), Text('Lỗi')],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Tạo tài khoản mới",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  const Text("Vui lòng điền đầy đủ các thông tin dưới đây", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

                  // 1. Ô nhập Họ và tên
                  TextFormField(
                    controller: _fullNameController,
                    decoration: _buildInputDecoration("Họ và tên", Icons.person_outline_rounded),
                    validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập họ và tên' : null,
                  ),
                  const SizedBox(height: 16),
                // 0. Ô nhập Tên đăng nhập (Username)
                  TextFormField(
                    controller: _usernameController,
                    decoration: _buildInputDecoration("Tên đăng nhập (Username)", Icons.account_box_rounded),
                    validator: (value) {
                      if (value!.trim().isEmpty) return 'Vui lòng nhập tên đăng nhập';
                      if (value.trim().contains(' ')) return 'Tên đăng nhập không được chứa khoảng trắng';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // 2. Ô nhập Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration("Địa chỉ Gmail", Icons.mail_outline_rounded),
                    validator: (value) {
                      if (value!.trim().isEmpty) return 'Vui lòng nhập Email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Định dạng Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Ô nhập Số điện thoại
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDecoration("Số điện thoại", Icons.phone_android_rounded),
                    validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Ô nhập Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: _buildPasswordInputDecoration("Mật khẩu"),
                    validator: (value) => value!.length < 6 ? 'Mật khẩu phải có ít nhất 6 ký tự' : null,
                  ),
                  const SizedBox(height: 16),

                  // 5. Ô nhập Lại Mật khẩu
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isPasswordVisible,
                    decoration: _buildPasswordInputDecoration("Nhập lại mật khẩu"),
                    validator: (value) {
                      if (value != _passwordController.text) return 'Mật khẩu xác nhận không trùng khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: 35),

                  // Nút Đăng ký kích hoạt
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("ĐĂNG KÝ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: Colors.white,
    );
  }

  InputDecoration _buildPasswordInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: Colors.white,
    );
  }
}