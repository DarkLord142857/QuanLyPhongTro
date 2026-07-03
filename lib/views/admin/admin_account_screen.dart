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

class AdminAccountScreen extends StatefulWidget {
  final int landlordId;

  final VoidCallback? onLogout;
  final VoidCallback? onBackHome;

  const AdminAccountScreen({super.key, required this.landlordId, this.onLogout, this.onBackHome});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  String _adminName = "Đang tải..."; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminName(); 
  }

  Future<void> _fetchAdminName() async {
    try {
      final String url = 'http://10.0.2.2/myapi/src/Controllers/GetLandlordInfo.php?id=${widget.landlordId}'; 
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
    setState(() {
      _adminName = "Admin Hệ thống"; 
      _isLoading = false;
    });
  }
    
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Xác nhận đăng xuất"),
          content: const Text("Bạn có chắc chắn muốn đăng xuất tài khoản Admin?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text("Hủy bỏ"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(dialogContext); 
              
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()), 
                (route) => false, 
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã đăng xuất thành công!")),
              );
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
      appBar: AppBar(
        title: const Text("Tài khoản & Quản lý (Admin)"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tài khoản Admin", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_adminName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            _buildMenuHeader("TÀI CHÍNH HỆ THỐNG"),
            _buildMenuItem(
              context: context,
              icon: Icons.electric_bolt_rounded,
              iconColor: Colors.amber,
              title: "Quản lý hóa đơn (Admin)",
              subtitle: "Ghi nhận chỉ số điện nước toàn hệ thống",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminInvoiceScreen(landlordId: widget.landlordId)),
                );
              },
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.paid_rounded,
              iconColor: Colors.green,
              title: "Quản lý thanh toán (Admin)",
              subtitle: "Lịch sử nộp tiền trọ toàn khu",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPaymentHistoryScreen(landlordId: widget.landlordId)),
                );
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.plumbing_rounded, 
              iconColor: Colors.orange,
              title: "Quản lý yêu cầu dịch vụ (Admin)",
              subtitle: "Tiếp nhận sự cố hệ thống",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminServiceRequestScreen(landlordId: widget.landlordId),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.request_quote_rounded, 
              iconColor: Colors.yellow,
              title: "Bảng giá dịch vụ (Admin)",
              subtitle: "Cấu hình danh mục dịch vụ mẫu",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminManageCatalogScreen(landlordId: widget.landlordId),
                  ),
                );
              },
            ),
            
            _buildMenuHeader("VẬN HÀNH TOÀN CỤC"),
            _buildMenuItem(
              context: context,
              icon: Icons.supervised_user_circle_rounded,
              iconColor: Colors.blue,
              title: "Quản lý khách thuê (Admin)",
              subtitle: "Hồ sơ lưu trú & Hợp đồng toàn hệ thống",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminTenantScreen(landlordId: widget.landlordId)),
                );
              },
            ),

            _buildMenuHeader("HỆ THỐNG & HỖ TRỢ"),
            _buildMenuItem(
              context: context,
              icon: Icons.home_rounded,
              iconColor: Colors.indigo,
              title: "Quay lại trang chủ",
              subtitle: "Trở về màn hình chính",
              onTap: () {
                if(widget.onBackHome!=null){
                  widget.onBackHome!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.logout_rounded,
              iconColor: Colors.redAccent,
              title: "Đăng xuất Admin",
              subtitle: "Thoát khỏi hệ thống quản trị",
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
