import 'package:flutter/material.dart';
import 'admin_payment_history_screen.dart';
import 'admin_tenant_screen.dart';
import 'admin_home_screen.dart';
import 'admin_invoice_screen.dart';
import '../../views/auth/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_service_request_screen.dart';
import 'admin_manage_catalog_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_revenue_statistics_screen.dart';

class AdminAccountScreen extends StatefulWidget {
  final int landlordId;
  final int? houseId; // Thêm houseId
  final VoidCallback? onLogout;
  final VoidCallback? onBackHome;

  const AdminAccountScreen({super.key, required this.landlordId, this.houseId, this.onLogout, this.onBackHome});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  String _adminName = "Đang tải..."; 
  bool _isLoading = true;
  final Color primaryColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _fetchAdminName(); 
  }

  Future<void> _fetchAdminName() async {
    try {
      final String url = 'http://192.168.1.250/myapi/src/Controllers/GetLandlordInfo.php?id=${widget.landlordId}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _adminName = responseData['data']['FullName'] ?? 'Chưa đặt tên'; 
            _isLoading = false;
          });
          return;
        }
      }
      _setFallbackName();
    } catch (e) {
      _setFallbackName();
    }
  }

  void _setFallbackName() {
    setState(() { _adminName = "Admin Hệ thống"; _isLoading = false; });
  }
    
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("Bạn có chắc chắn muốn thoát khỏi hệ thống quản trị?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Hủy bỏ")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(dialogContext); 
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
              child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
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
      // Bỏ AppBar vì AdminMainScreen đã có
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)),
                    child: const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.admin_panel_settings_rounded, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Quản trị viên hệ thống", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(_adminName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSection(
              "TÀI CHÍNH & HÓA ĐƠN",
              [
                _buildMenuItem(Icons.bar_chart_rounded, Colors.blue, "Thống kê doanh thu", "Báo cáo tài chính chi tiết", 
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminRevenueStatisticsScreen(adminId: widget.landlordId)))),
                _buildMenuItem(Icons.electric_bolt_rounded, Colors.amber, "Quản lý hóa đơn", "Ghi điện nước & Phát hành hóa đơn", 
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminInvoiceScreen(landlordId: widget.landlordId, houseId: widget.houseId)))),
                _buildMenuItem(Icons.paid_rounded, Colors.green, "Lịch sử thanh toán", "Theo dõi dòng tiền thu vào", 
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPaymentHistoryScreen(landlordId: widget.landlordId, houseId: widget.houseId)))),
              ]
            ),

            _buildSection(
              "VẬN HÀNH & HỆ THỐNG",
              [
                _buildMenuItem(Icons.manage_accounts_rounded, Colors.deepPurple, "Quản lý tài khoản", "Duyệt & Phân quyền người dùng", 
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUserManagementScreen(adminId: widget.landlordId)))),
                _buildMenuItem(Icons.supervised_user_circle_rounded, Colors.indigo, "Quản lý khách thuê", "Hồ sơ lưu trú & Hợp đồng", 
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminTenantScreen(landlordId: widget.landlordId)))),
                _buildMenuItem(Icons.build_circle_rounded, Colors.orange, "Yêu cầu dịch vụ", "Xử lý sự cố từ khách hàng", 
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminServiceRequestScreen(landlordId: widget.landlordId)))),
                _buildMenuItem(Icons.list_alt_rounded, Colors.teal, "Danh mục dịch vụ", "Cấu hình đơn giá dịch vụ mẫu", 
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminManageCatalogScreen(landlordId: widget.landlordId)))),
              ]
            ),

            _buildSection(
              "ỨNG DỤNG",
              [
                _buildMenuItem(Icons.home_rounded, Colors.blueGrey, "Về trang chủ", "Quay lại màn hình tổng quan", widget.onBackHome ?? () => Navigator.pop(context)),
                _buildMenuItem(Icons.logout_rounded, Colors.redAccent, "Đăng xuất", "Thoát khỏi phiên làm việc", () => _showLogoutDialog(context)),
              ]
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 12, top: 8),
          child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.2)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(children: items),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCBD5E1)),
      onTap: onTap,
    );
  }
}
