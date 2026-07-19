import 'package:flutter/material.dart';
import 'admin_home_screen.dart'; 
import 'admin_room_screen.dart'; 
import 'admin_tenant_screen.dart';
import 'admin_account_screen.dart';


class AdminMainScreen extends StatefulWidget {
  final int userId;
  final String houseName;
  final int houseId;

  const AdminMainScreen({
    super.key,
    required this.userId,
    this.houseName = "Nhà trọ hệ thống",
    this.houseId = 1,
  });

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Danh sách các màn hình con
    final List<Widget> screens = [
      AdminHomeScreen(userId: widget.userId, houseName: widget.houseName, houseId: widget.houseId),
      AdminRoomsScreen(adminId: widget.userId, houseId: widget.houseId, onBackHome: () => setState(() => _selectedIndex = 0)),
      AdminTenantScreen(landlordId: widget.userId, houseId: widget.houseId, onBackHome: () => setState(() => _selectedIndex = 0)),
      AdminAccountScreen(landlordId: widget.userId, houseId: widget.houseId, onBackHome: () => setState(() => _selectedIndex = 0)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? widget.houseName : 
          (_selectedIndex == 1 ? "Quản Lý Phòng" : 
          (_selectedIndex == 2 ? "Quản Lý Khách" : "Tài Khoản Admin")),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF10B981),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Quay lại danh sách nhà",
        ),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        iconSize: 26,
        elevation: 15,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.home_work_rounded), label: 'Phòng trọ'), 
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Hợp đồng'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_rounded), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
