import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Thêm thư viện http để gọi API
import 'dart:convert'; // Thêm thư viện convert để xử lý JSON
// Import màn hình chính người thuê trọ
import '../auth/register_screen.dart'; // Import màn hình đăng ký để điều hướng từ đây sang đó
import '../auth/forgot_password_screen.dart';
import '../khach_hang/tenant_main_screen.dart'; // Đảm bảo import đúng file TenantMainScreen của bạn
import '../chutro/landlord_main_screen.dart'; // Đảm bảo import đúng file LandlordMainScreen của bạn
import '../admin/admin_house_list_screen.dart'; // Import màn hình danh sách nhà trọ Admin

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Hàm xử lý khi bấm nút Đăng nhập
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // CẤU HÌNH ĐƯỜNG DẪN API (Thay IP máy tính của bạn nếu chạy máy thật)
      final url = Uri.parse('http://192.168.1.250/myapi/src/Controllers/AuthController.php');

      try {
        // Gửi request POST lên PHP API dưới dạng JSON body
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "Identifier": _usernameController.text.trim(),
            "Password": _passwordController.text.trim(),
          }),
        ).timeout(const Duration(seconds: 10)); // Tự động ngắt nếu quá 10 giây không phản hồi

        // Giải mã dữ liệu JSON trả về từ PHP
        final responseData = jsonDecode(response.body);

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 && responseData['status'] == 'success') {
          // Lấy thông tin vai trò (Role) từ database trả về
          String role = responseData['user']['role'];
          String fullName = responseData['user']['fullname'];
          int loggedInUserId = int.parse(responseData['user']['id'].toString());

          // Phân quyền điều hướng dựa vào cột Role trong Database của bạn
          if (role == 'KhachHang') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Chào mừng $fullName đã quay trở lại!'), backgroundColor: Colors.green),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TenantMainScreen(userId: loggedInUserId),
              ),
            );
          } else if (role == 'ChuTro') {
            // Kiểm tra quyền quản lý nhà trọ (Sẽ hiện snackbar sau nếu thành công)
            _checkLandlordAccess(loggedInUserId, fullName);
          } else if (role == 'Admin') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Chào mừng Admin $fullName!'), backgroundColor: Colors.green),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminHouseListScreen(userId: loggedInUserId),
              ),
            );
          }
        } else if (responseData['status'] == 'locked') {
          // HIỂN THỊ THÔNG BÁO KHÓA NGAY KHI ĐĂNG NHẬP
          _showLockedDialog(responseData['message'] ?? "Tài khoản tạm thời không thể truy cập.");
        } else {
          // Trường hợp API trả về lỗi sai mật khẩu hoặc tài khoản chưa duyệt
          String errorMessage = responseData['message'] ?? 'Đăng nhập thất bại';
          _showErrorDialog(errorMessage);
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        // Báo lỗi nếu không kết nối được tới server PHP
        _showErrorDialog("Không thể kết nối đến máy chủ API. Vui lòng kiểm tra mạng hoặc cấu hình IP!");
      }
    }
  }

  // HÀM KIỂM TRA QUYỀN TRUY CẬP NHÀ TRỌ CỦA CHỦ TRỌ
  void _checkLandlordAccess(int userId, String fullName) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/GetLandlordDashboard.php?landlord_id=$userId'),
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (data['status'] == 'no_house' || data['status'] == 'house_deleted') {
        _showNoAccessDialog(data['message'] ?? "Bạn không có quyền truy cập hệ thống.");
      } else {
        // Có nhà trọ quản lý -> Hiện thông báo chào mừng và cho phép vào
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chào mừng $fullName đã quay trở lại!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LandlordMainScreen(userId: userId)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Lỗi hệ thống khi kiểm tra quyền quản lý nhà trọ.");
    }
  }

  // HÀM HIỂN THỊ DIALOG KHI CHỦ TRỌ CHƯA CÓ NHÀ QUẢN LÝ
  void _showNoAccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.house_siding_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Thông báo truy cập", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text("Đã hiểu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Hàm phụ trợ hiển thị hộp thoại cảnh báo lỗi bằng tiếng Việt
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Thông báo lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }

  // HÀM HIỂN THỊ DIALOG KHI TÀI KHOẢN BỊ KHÓA
  void _showLockedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_person_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Thông báo hệ thống", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Đã hiểu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.home_work_rounded,
                    size: 80,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "TÌM PHÒNG TRỌ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Text(
                    "Đăng nhập hệ thống điều hành",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Tên tài khoản (Email hoặc SĐT)",
                      hintText: "Tên tài khoản (Email hoặc SĐT)",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập thông tin tài khoản của bạn';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text("Quên mật khẩu?", style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "ĐĂNG NHẬP",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Chưa có tài khoản? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Đăng ký ngay",
                          style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
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
    );
  }
}
