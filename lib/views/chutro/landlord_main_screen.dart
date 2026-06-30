import 'package:flutter/material.dart';
import '../../views/chutro/landlord_home_screen.dart'; 
import '../../views/chutro/landlord_room_screen.dart'; 
import '../../views/chutro/landlord_tenant_screen.dart';
import '../../views/chutro/landlord_account_screen.dart';


class LandlordMainScreen extends StatefulWidget {
  final int userId;
  const LandlordMainScreen({super.key, required this.userId});

  @override
  State<LandlordMainScreen> createState() => _LandlordMainScreenState();
}

class _LandlordMainScreenState extends State<LandlordMainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
    LandlordHomeScreen(userId: widget.userId), 
    LandlordRoomsScreen(onBackHome: () => setState(() => _selectedIndex = 0)), 
    LandlordTenantScreen(landlordId: widget.userId, onBackHome: () => setState(() => _selectedIndex = 0)),
    LandlordAccountScreen(landlordId: widget.userId, onBackHome: () => setState(() => _selectedIndex = 0),), // 🌟 Tab Tài khoản & Quản trị gom tại đây
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
            selectedItemColor: const Color(0xFF10B981), // Đồng bộ xanh lá cây Modern chủ trọ
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