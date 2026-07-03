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
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminHomeScreen(userId: widget.userId, houseName: widget.houseName, houseId: widget.houseId),
      AdminRoomsScreen(onBackHome: () => setState(() => _selectedIndex = 0)),
      AdminTenantScreen(landlordId: widget.userId, onBackHome: () => setState(() => _selectedIndex = 0)),
      AdminAccountScreen(landlordId: widget.userId, onBackHome: () => setState(() => _selectedIndex = 0)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
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
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue, // Màu xanh dương cho Admin
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            iconSize: 24,
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
