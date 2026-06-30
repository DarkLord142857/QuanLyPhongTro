import 'package:flutter/material.dart';
import '../chutro/landlord_tenant_screen.dart'; // Màn hình quản lý thông tin khách trọ đã làm từ trước
import '../chutro/landlord_home_screen.dart';
import '../chutro/landlord_invoice_screen.dart';
import '../../views/auth/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LandlordAccountScreen extends StatelessWidget {
  final int landlordId;

  final VoidCallback? onLogout;
  final VoidCallback? onBackHome;

  const LandlordAccountScreen({super.key, required this.landlordId, this.onLogout, this.onBackHome});

// 🔥 HÀM HIỂN THỊ HỘP THOẠI XÁC NHẬN ĐĂNG XUẤT
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Ép người dùng phải chọn chứ không ấn ra ngoài để hủy
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("Xác nhận đăng xuất", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text("Bạn có chắc chắn muốn đăng xuất tài khoản chủ trọ này không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Đóng hộp thoại
              child: const Text("Hủy bỏ", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext); // 1. Đóng hộp thoại xác nhận trước
              
              // 🔥 2. CHẠY QUA FILE LOGIN_SCREEN VÀ XÓA SẠCH BOTTOM NAVIGATOR CŨ
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()), // Gọi class từ file login_screen.dart
                (route) => false, // Xóa hoàn toàn lịch sử các màn hình cũ, ngăn bấm nút back quay lại
              );

              // 3. Hiển thị thông báo nhanh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Đã đăng xuất tài khoản thành công!"), 
                  backgroundColor: Colors.black87,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              },
              child: const Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Tài khoản & Quản trị", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // KHỐI 1: THÔNG TIN TÓM TẮT CHỦ TRỌ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person_pin_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tài khoản Quản trị", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(height: 4),
                      Text("Chủ trọ Hệ thống", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // KHỐI 2: MỤC QUẢN LÝ HÓA ĐƠN ĐIỆN NƯỚC (Liên kết trực tiếp với bảng HoaDon trong DB của bạn)
            _buildMenuHeader("TÀI CHÍNH KHU TRỌ"),
            _buildMenuItem(
              context: context,
              icon: Icons.electric_bolt_rounded,
              iconColor: Colors.amber,
              title: "Quản lý hóa đơn điện nước",
              subtitle: "Ghi nhận chỉ số điện nước, tính tiền phòng hàng tháng",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => _ManageInvoiceSubScreen(landlordId: landlordId)),
                );
              },
            ),

            // KHỐI 3: MỤC QUẢN LÝ THANH TOÁN TIỀN TRỌ (Liên kết trực tiếp với bảng ThanhToan trong DB của bạn)
            _buildMenuItem(
              context: context,
              icon: Icons.paid_rounded,
              iconColor: Colors.green,
              title: "Quản lý thanh toán tiền trọ",
              subtitle: "Cập nhật phiếu thu, lịch sử nộp tiền trọ của khách",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => _ManagePaymentSubScreen(landlordId: landlordId)),
                );
              },
            ),

            const SizedBox(height: 12),

            // KHỐI 4: QUẢN LÝ THÔNG TIN KHÁCH TRỌ (Liên kết bảng Users có Role = 'KhachHang' và bảng HopDongThue)
            _buildMenuHeader("VẬN HÀNH & NHÂN SỰ"),
            _buildMenuItem(
              context: context,
              icon: Icons.supervised_user_circle_rounded,
              iconColor: Colors.blue,
              title: "Quản lý thông tin khách trọ",
              subtitle: "Hồ sơ lưu trú, hợp đồng thuê phòng, cấp tài khoản mới",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LandlordTenantScreen(landlordId: landlordId)),
                );
              },
            ),

            const SizedBox(height: 12),

            // KHỐI 5: QUẢN LÝ TÀI KHOẢN CHỦ TRỌ (Cập nhật thông tin chính bảng Users tại dòng id = landlordId)
            _buildMenuHeader("CẤU HÌNH HỆ THỐNG"),
            _buildMenuItem(
              context: context,
              icon: Icons.manage_accounts_rounded,
              iconColor: Colors.purple,
              title: "Quản lý tài khoản chủ trọ",
              subtitle: "Thay đổi thông tin liên hệ",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => _ProfileEditSubScreen(landlordId: landlordId)),
                );
              },
            ),

            const SizedBox(height: 12),
            _buildMenuHeader("HỆ THỐNG & HỖ TRỢ"),
            
            // 🔥 ĐÃ SỬA: NÚT QUAY LẠI TRANG CHỦ THEO YÊU CẦU
            _buildMenuItem(
              context: context,
              icon: Icons.home_rounded, // Đổi sang icon Ngôi nhà
              iconColor: Colors.indigo,
              title: "Quay lại trang chủ", // Đổi tiêu đề trực quan
              subtitle: "Trở về màn hình chính của ứng dụng",
              onTap: () {
                if(onBackHome!=null){
                  onBackHome!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),

            // NÚT ĐĂNG XUẤT
            _buildMenuItem(
              context: context,
              icon: Icons.logout_rounded,
              iconColor: Colors.redAccent,
              title: "Đăng xuất tài khoản",
              subtitle: "Thoát khỏi hệ thống quản trị và bảo mật dữ liệu",
              onTap: () => _showLogoutDialog(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 12, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1E293B))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}

//Quản lý hóa đơn
class _ManageInvoiceSubScreen extends StatelessWidget {
  final int landlordId;
  const _ManageInvoiceSubScreen({required this.landlordId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Hóa đơn Tiền trọ & Điện nước"), backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Danh sách hóa đơn hàng tháng",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            // Giả lập giao diện hiển thị danh sách hóa đơn đọc từ bảng HoaDon của bạn
            Expanded(
              child: ListView.builder(
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(index == 0 ? "Phòng 101" : "Phòng 102", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: index == 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                index == 0 ? "Chưa thanh toán" : "Đã thanh toán",
                                style: TextStyle(color: index == 0 ? Colors.red : Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 20),
                        Text("Kỳ hóa đơn: Tháng 06/2026", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("Số điện: ${index == 0 ? '420 kWh -> 550 kWh' : '310 kWh -> 412 kWh'}", style: const TextStyle(fontSize: 13)),
                        Text("Số nước: ${index == 0 ? '25 m3 -> 32 m3' : '18 m3 -> 24 m3'}", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Tổng cộng cần thu:", style: TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              index == 0 ? "3.450.000 đ" : "2.980.000 đ",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        child: const Icon(Icons.post_add_rounded),
        onPressed: () {
          // Tại đây chủ trọ sẽ mở Form nhập các thông số:
          // PhongTroId, ThangNam, TienPhong, SoDienCu, SoDienMoi, SoNuocCu, SoNuocMoi để ghi nhận hóa đơn mới.
        },
      ),
    );
  }
}

// Quản lý thanh toán
class _ManagePaymentSubScreen extends StatelessWidget {
  final int landlordId;
  const _ManagePaymentSubScreen({required this.landlordId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Lịch sử Thanh toán Tiền trọ"), backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.check_circle_rounded, color: Colors.green),
              ),
              title: Text(index == 0 ? "Phòng 102 nộp tiền trọ" : "Phòng 105 nộp tiền trọ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text("Ngày thu: 25/06/2026\nPhương thức: Chuyển khoản ngân hàng", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: Text(
                index == 0 ? "+2.980.000đ" : "+3.100.000đ",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

class _ProfileEditSubScreen extends StatefulWidget {
  final int landlordId;
  const _ProfileEditSubScreen({required this.landlordId});

  @override
  State<_ProfileEditSubScreen> createState() => _ProfileEditSubScreenState();
}

class _ProfileEditSubScreenState extends State<_ProfileEditSubScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState(){
    super.initState();
    _fetchLandlordData();
  }

// 🌐 HÀM GỌI API LẤY THÔNG TIN CHỦ TRỌ TỪ BACKEND
      Future<void> _fetchLandlordData() async {
        try {
          // Địa chỉ API kết nối tới Laragon (Sử dụng IP 10.0.2.2 cho máy ảo Android)
          final String url = 'http://10.0.2.2/myapi/src/Controllers/GetLandlordInfo.php?id=${widget.landlordId}';
          
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = json.decode(response.body);

            if (responseData['success'] == true && responseData['data'] != null) {
              final data = responseData['data'];
              
              // Đổ dữ liệu từ API nhận được vào các ô nhập liệu TextFields
              setState(() {
                _nameCtrl.text = data['FullName'] ?? '';
                _phoneCtrl.text = data['PhoneNumber'] ?? '';
                _emailCtrl.text = data['Email'] ?? '';
                _idCardCtrl.text = data['IdentityCard'] ?? '';
                _isLoading = false; // Tải dữ liệu thành công, tắt hiệu ứng xoay tròn
              });
            } else {
              _handleFetchError(responseData['message'] ?? "Không thể tải thông tin chủ trọ.");
            }
          } else {
            _handleFetchError("Lỗi kết nối máy chủ: Mã lỗi ${response.statusCode}");
          }
        } catch (e) {
          _handleFetchError("Đã xảy ra lỗi hệ thống: $e");
        }
      }

      // 2. 🌐 ĐÃ THÊM: Bắn thuộc tính IdentityCard lên API Update
        Future<void> _updateLandlordData() async {
          if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
            _showSnackBar("Vui lòng không để trống Họ tên và Số điện thoại!", Colors.orange);
            return;
          }

          setState(() => _isSaving = true); 

          try {
            final String url = 'http://10.0.2.2/myapi/src/Controllers/UpdateLandlordInfo.php';
            
            final Map<String, dynamic> updateData = {
              "id": widget.landlordId,
              "FullName": _nameCtrl.text.trim(),
              "PhoneNumber": _phoneCtrl.text.trim(),
              "Email": _emailCtrl.text.trim(),
              "IdentityCard": _idCardCtrl.text.trim(), // 🔥 ĐÃ ĐỒNG BỘ GỬI CCCD LÊN BACKEND
            };

            final response = await http.post(
              Uri.parse(url),
              headers: {"Content-Type": "application/json; charset=UTF-8"},
              body: json.encode(updateData),
            );

            final Map<String, dynamic> responseData = json.decode(response.body);

            if (response.statusCode == 200 && responseData['success'] == true) {
              _showSnackBar(responseData['message'] ?? "Cập nhật thành công!", Colors.green);
              Navigator.pop(context); 
            } else {
              _showSnackBar(responseData['message'] ?? "Cập nhật thất bại.", Colors.redAccent);
            }
          } catch (e) {
            _showSnackBar("Lỗi kết nối mạng: $e", Colors.redAccent);
          } finally {
            setState(() => _isSaving = false); 
          }
        }

      // Hàm xử lý hiển thị thông báo lỗi nhanh
      void _handleFetchError(String errorMessage) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }

      void _showSnackBar(String message, Color color) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
        );
      }

      @override
      void dispose() {
        // Giải phóng bộ nhớ giải phóng RAM khi thoát màn hình
        _nameCtrl.dispose();
        _phoneCtrl.dispose();
        _emailCtrl.dispose();
        _idCardCtrl.dispose();
        super.dispose();
      }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Hồ sơ Cá nhân Chủ trọ"), 
        backgroundColor: const Color(0xFF10B981), 
        foregroundColor: Colors.white
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Thông tin định danh quản trị", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF10B981))),
                  const SizedBox(height: 12),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Họ và tên chủ trọ *", prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 12),
                  
                  // 🔥 Ô NHẬP LIỆU ĐÃ ĐƯỢC KÍCH HOẠT HOÀN TOÀN:
                  TextField(
                    controller: _idCardCtrl, 
                    keyboardType: TextInputType.number, // Chỉ hiện bàn phím số cho số CCCD
                    decoration: const InputDecoration(labelText: "Số CCCD / CMND chủ trọ", prefixIcon: Icon(Icons.badge))
                  ),
                  
                  const SizedBox(height: 12),
                  TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Số điện thoại liên hệ *", prefixIcon: Icon(Icons.phone))),
                  const SizedBox(height: 12),
                  TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: "Địa chỉ Email", prefixIcon: Icon(Icons.email))),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _updateLandlordData, 
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text("Lưu cấu hình tài khoản", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
    );
  }
}
