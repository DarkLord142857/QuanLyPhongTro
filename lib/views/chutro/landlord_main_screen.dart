import 'package:flutter/material.dart';
import 'landlord_home_screen.dart'; 
import 'landlord_room_screen.dart'; 
import 'landlord_tenant_screen.dart';
import 'landlord_account_screen.dart';
import '../auth/login_screen.dart';

class LandlordMainScreen extends StatefulWidget {
  final int userId;
  const LandlordMainScreen({super.key, required this.userId});

  @override
  State<LandlordMainScreen> createState() => _LandlordMainScreenState();
}

class _LandlordMainScreenState extends State<LandlordMainScreen> {
  int _selectedIndex = 0;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text("Bạn có chắc chắn muốn đăng xuất tài khoản chủ trọ này không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Hủy bỏ", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
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
    // Danh sách các màn hình con - Đảm bảo truyền đúng ID để ngăn vách dữ liệu
    final List<Widget> screens = [
      LandlordHomeScreen(userId: widget.userId), 
      LandlordRoomsScreen(landlordId: widget.userId, onBackHome: () => setState(() => _selectedIndex = 0)), 
      LandlordTenantScreen(landlordId: widget.userId, onBackHome: () => setState(() => _selectedIndex = 0)),
      LandlordAccountScreen(landlordId: widget.userId, onBackHome: () => setState(() => _selectedIndex = 0)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? "Tổng Quan Chủ Trọ" : 
          (_selectedIndex == 1 ? "Quản Lý Phòng" : 
          (_selectedIndex == 2 ? "Quản Lý Hợp Đồng" : "Tài Khoản")),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF10B981),
        centerTitle: true,
        elevation: 0,
        // Chủ trọ không cần nút quay lại nhà trọ vì họ thường chỉ quản lý 1 nhà cố định
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
            tooltip: "Đăng xuất",
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.05),
              blurRadius: 25,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF10B981),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            iconSize: 26,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Tổng quan'),
              BottomNavigationBarItem(icon: Icon(Icons.home_work_rounded), label: 'Phòng trọ'), 
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Hợp đồng'),
              BottomNavigationBarItem(icon: Icon(Icons.account_circle_rounded), label: 'Tài khoản'),
            ],
          ),
        ),
      ),
    );
  }
}
