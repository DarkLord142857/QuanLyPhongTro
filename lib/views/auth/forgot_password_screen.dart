import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Các Bộ điều khiển dữ liệu
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1; // Bước hiện tại: 1 -> Nhập Email/SĐT, 2 -> Nhập OTP, 3 -> Mật khẩu mới
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // 🛠️ 2. KHAI BÁO BIẾN ĐẾM NGƯỢC
  Timer? _timer;
  int _secondsRemaining = 90; // Thời gian 90 giây theo PHP cấu hình

  // Đường dẫn API Laragon trên máy ảo Android
  final String _apiUrl = 'http://10.0.2.2/myapi/src/Controllers/ForgotPasswordController.php';

// 🛠️ 3. HÀM KHỞI ĐỘNG ĐỒNG HỒ ĐẾM NGƯỢC
  void _startTimer() {
    _timer?.cancel(); // Hủy timer cũ nếu đang chạy ngầm
    setState(() {
      _secondsRemaining = 90; // Đặt lại 90 giây
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel(); // Dừng đếm khi về 0
        }
      });
    });
  }

// 🛠️ 4. HÀM ĐỊNH DẠNG THỜI GIAN THÀNH PHÚT:GIÂY (Ví dụ: 01:30)
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  // 🛠️ HÀM HIỂN THỊ THÔNG BÁO QUICK SNACKBAR
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // =============================================================================
  // BƯỚC 1: GỬI YÊU CẦU LẤY MÃ OTP (send_otp)
  // =============================================================================
  void _sendOtp() async {
    if (_identifierController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập Email hoặc Số điện thoại", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "send_otp",
          "Identifier": _identifierController.text.trim(), // Khớp với PHP
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showSnackBar(data['message'] ?? "Mã OTP đã được tạo!", Colors.green);
        
        // 💡 Mẹo nhỏ: In mã OTP ra màn hình console của Flutter để bạn dễ test máy ảo không cần check mail
        print("MÃ OTP CỦA BẠN LÀ: ${data['otp']}");

        _startTimer();

        setState(() {
          _currentStep = 2; // Chuyển sang giao diện nhập OTP
        });
      } else {
        _showSnackBar(data['message'] ?? "Tài khoản không tồn tại trên hệ thống.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối server: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =============================================================================
  // BƯỚC 2: XÁC THỰC MÃ OTP (verify_otp)
  // =============================================================================
  void _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập mã OTP gồm 6 chữ số", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "verify_otp",
          "Identifier": _identifierController.text.trim(),
          "otp": _otpController.text.trim(), // Khớp chữ 'otp' viết thường với PHP
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _timer?.cancel();
        _showSnackBar(data['message'] ?? "Xác thực thành công!", Colors.green);
        setState(() {
          _currentStep = 3; // Chuyển sang giao diện đặt mật khẩu mới
        });
      } else {
        _showSnackBar(data['message'] ?? "Mã OTP không chính xác hoặc hết hạn.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =============================================================================
  // BƯỚC 3: TIẾN HÀNH THAY ĐỔI MẬT KHẨU MỚI (reset_password)
  // =============================================================================
  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "reset_password",
          "Identifier": _identifierController.text.trim(),
          "NewPassword": _passwordController.text.trim(), // 🛠️ ĐÃ SỬA: Thay từ 'password' thành 'NewPassword' để khớp PHP
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showSnackBar("Đổi mật khẩu thành công! Vui lòng đăng nhập lại.", Colors.green);
        
        // Trở về màn hình đăng nhập sau khi hoàn tất thành công
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      } else {
        _showSnackBar(data['message'] ?? "Đổi mật khẩu thất bại.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối máy chủ: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Quên mật khẩu", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Biểu tượng động theo từng bước để giao diện sinh động hơn
                Icon(
                  _currentStep == 1 
                      ? Icons.lock_reset_rounded 
                      : _currentStep == 2 
                          ? Icons.mark_email_read_outlined 
                          : Icons.shield_outlined,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  _currentStep == 1 
                      ? "Khôi phục tài khoản" 
                      : _currentStep == 2 
                          ? "Xác thực mã số OTP" 
                          : "Thiết lập mật khẩu mới",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 30),

                // GIAO DIỆN BƯỚC 1: NHẬP SỐ ĐIỆN THOẠI HOẶC EMAIL
                if (_currentStep == 1) ...[
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email hoặc Số điện thoại",
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildButton("GỬI MÃ XÁC THỰC OTP", _sendOtp),
                ],

                // GIAO DIỆN BƯỚC 2: NHẬP MÃ SỐ OTP ĐƯỢC CẤP
                if (_currentStep == 2) ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
                    decoration: InputDecoration(
                      labelText: "Mã số OTP",
                      counterText: "",
                      prefixIcon: const Icon(Icons.pin_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  //_buildButton("XÁC MINH MÃ OTP", _verifyOtp),
                  TextButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: const Text("Tôi chưa nhận được mã? Gửi lại mã mới"),
                  ),
                  // 🔥 8. THÊM WIDGET HIỂN THỊ ĐỒNG HỒ ĐẾM NGƯỢC
                  const SizedBox(height: 12),
                  Text(
                    _secondsRemaining > 0
                        ? "Mã hiệu lực còn lại: ${_formatTime(_secondsRemaining)}"
                        : "Mã OTP của bạn đã hết hạn!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _secondsRemaining > 0 ? Colors.blueGrey : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔥 9. CHỈ CHO PHÉP NHẤN XÁC MINH KHI CÒN THỜI GIAN
                  _buildButton(
                    "XÁC MINH MÃ OTP",
                    _secondsRemaining > 0 ? _verifyOtp : () {
                      _showSnackBar("Mã OTP đã hết hạn, vui lòng bấm gửi lại mã mới!", Colors.red);
                    },
                  ),
                  
                  // 🔥 10. CHỈ BẬT NÚT GỬI LẠI KHI ĐỒNG HỒ VỀ 0
                  TextButton(
                    onPressed: (_isLoading || _secondsRemaining > 0) ? null : _sendOtp,
                    child: Text(
                      _secondsRemaining > 0 
                          ? "Gửi lại mã mới (Đợi sau ${_secondsRemaining}s)" 
                          : "Tôi chưa nhận được mã? Gửi lại mã mới",
                      style: TextStyle(
                        color: _secondsRemaining > 0 ? Colors.grey : Colors.blueAccent,
                      ),
                    ),
                  ),
                ],

                // GIAO DIỆN BƯỚC 3: ĐẶT LẠI MẬT KHẨU MỚI
                if (_currentStep == 3) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: _buildPasswordDecoration("Mật khẩu mới"),
                    validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu phải từ 6 ký tự trở lên' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isPasswordVisible,
                    decoration: _buildPasswordDecoration("Xác nhận mật khẩu mới"),
                    validator: (v) => v != _passwordController.text ? 'Mật khẩu xác nhận không khớp' : null,
                  ),
                  const SizedBox(height: 30),
                  _buildButton("XÁC NHẬN ĐỔI MẬT KHẨU", _resetPassword),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  InputDecoration _buildPasswordDecoration(String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}