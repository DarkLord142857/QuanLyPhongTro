import 'package:flutter/material.dart';
import '../khach_hang/home_screen.dart'; 
import '../khach_hang/room_discovery_screen.dart'; 
import '../khach_hang/request_service_screen.dart'; 
import '../khach_hang/help_and_info_screen.dart';

class TenantMainScreen extends StatefulWidget {
  final int userId;
  const TenantMainScreen({super.key, required this.userId});

  @override
  State<TenantMainScreen> createState() => _TenantMainScreenState();
}

class _TenantMainScreenState extends State<TenantMainScreen> {
  int _selectedIndex = 0; 
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách màn hình
    _screens = [
      KhachHangHomeScreen(userId: widget.userId), // Tab 0: Trang chủ
      RoomDiscoveryScreen(onBackHome: () {
        _onItemTapped(0);
      }),                // Tab 1
      // 🔥 TRUYỀN HÀM CALLBACK: Khi cần nhảy Tab, gọi hàm chuyển về Tab 0
      RequestServiceScreen(
        userId: widget.userId,
        onSuccessRedirect: () {
          _onItemTapped(0); // Nhảy lập tức về Tab Trang chủ
        },
      ), 
      HelpAndInfoScreen(onBackHome: () {
        _onItemTapped(0);
      }),      // Tab 3
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped, // Gọi hàm đổi index Tab công khai
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF2563EB),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            iconSize: 22,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
              BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Tìm kiếm'),
              BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), label: 'Dịch vụ'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Trợ giúp'),
            ],
          ),
        ),
      ),
    );
  }
}

// Giữ nguyên PlaceholderScreen phía dưới của bạn...

// MÀN HÌNH TẠM THỜI CHO CÁC TAB CHƯA PHÁT TRIỂN Code
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              "Giao diện $title đang được phát triển",
              style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}