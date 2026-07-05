import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';
import '../khach_hang/tenant_contract_screen.dart';
import '../khach_hang/tenant_invoice_screen.dart';
import '../khach_hang/tenant_utility_screen.dart';
import '../khach_hang/tenant_notifications_screen.dart';
import '../khach_hang/tenant_payment_history_screen.dart';
import '../khach_hang/payment_screen.dart';
import 'dart:convert';

class KhachHangHomeScreen extends StatefulWidget {
  // 🔑 ĐÓN NHẬN: Lưu trữ ID tài khoản do màn hình Đăng nhập bàn giao sang
  final int userId; 
  const KhachHangHomeScreen({super.key, required this.userId});

  @override
  State<KhachHangHomeScreen> createState() => _KhachHangHomeScreenState();
}

class _KhachHangHomeScreenState extends State<KhachHangHomeScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  int _unreadCount = 0;
  
  
  // Các biến lưu thông tin thực tế đồng bộ từ Database
  String _fullName = "Người thuê trọ";
  String _roomNumber = "Chưa xếp phòng";
  String _houseName = "Hệ thống phòng trọ";
  double _roomPrice = 0;
  bool _hasRoom = false;
  Map<String, dynamic>? _latestInvoice;

  @override
  void initState() {
    super.initState();
    _fetchHomeData(); // Tự động kéo dữ liệu từ PHP về ngay khi vừa đăng nhập xong
    _checkUnreadNotifications(); // Kiểm tra số lượng thông báo chưa
  }

      // 🌟 1. SỬA LẠI HÀM CHECK THÔNG BÁO: Đếm trực tiếp từ trangThai (0 = Chưa đọc) của database
        Future<void> _checkUnreadNotifications() async {
          final String url = 'http://10.0.2.2/myapi/src/Controllers/GetTenantNotifications.php?user_id=${widget.userId}';
          try {
            // Thêm timeout 3 giây để tránh treo main thread
            final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
            if (response.statusCode == 200) {
              final res = json.decode(response.body);
              if (res['status'] == 'success') {
                List notifications = res['data'] ?? [];
                
                // Đếm số lượng thông báo có trangThai == 0 (Chưa xem) theo cấu hình SQL của bạn
                int unread = notifications.where((item) => item['trangThai'] == 0).length;

                if (mounted) {
                  setState(() {
                    _unreadCount = unread;
                  });
                }
              } else {
                if (mounted) {
                  setState(() {
                    _unreadCount = 0;
                  });
                }
              }
            }
          } catch (e) {
            print("Lỗi check thông báo: $e");
          }
        }
  // Hàm kết nối và gọi API tổng hợp từ máy chủ Laragon
  Future<void> _fetchHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // widget.userId chính là mã ID chúng ta truyền xuyên màn hình từ trang Login sang
      final url = Uri.parse(
        'http://10.0.2.2/myapi/src/Controllers/TenantHomeController.php?user_id=${widget.userId}'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final homeData = data['data'];

        setState(() {
          _fullName = homeData['user']['FullName'] ?? "Người dùng";

          if (homeData['room_status']['has_room'] == true) {
            _hasRoom = true;
            _roomNumber = "Phòng ${homeData['room_status']['RoomNumber']}";
            _houseName = homeData['room_status']['HouseName'];
            _roomPrice = double.tryParse(homeData['room_status']['GiaPhong']?.toString() ?? '0') ?? 0.0;
          } else {
            _hasRoom = false;
            _roomNumber = "Chưa xếp phòng";
            _houseName = "Hệ thống phòng trọ";
          }

          _latestInvoice = homeData['latest_invoice'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? "Không thể lấy thông tin phòng.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi kết nối máy chủ Laragon. Vui lòng thử lại!";
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(_errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _fetchHomeData, child: const Text("Thử lại")),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _fetchHomeData, // Vuốt màn hình từ trên xuống để làm mới dữ liệu
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumHeader(context),
              const SizedBox(height: 30),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Tiện ích dành cho bạn",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              _buildPremiumGridMenu(),
              const SizedBox(height: 32),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Hóa đơn cần thanh toán",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              _buildPremiumInvoiceCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32),topRight: Radius.circular(32),bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 35),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Xin chào 👋", style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      _fullName, // ĐỔ TÊN THỰC TẾ CỦA TÀI KHOẢN ĐANG ĐĂNG NHẬP
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none, 
                children: [
                  _buildHeaderButton(Icons.notifications_none_rounded, () async {
                    // 🛠️ ĐÃ SỬA: Thêm biến 'hasChanged' để hứng kết quả 'true/false' từ màn hình thông báo trả về
                    final hasChanged = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TenantNotificationsScreen(userId: widget.userId),
                      ),
                    );
                    
                    // 🛠️ ĐÃ SỬA: Cho dù 'hasChanged' bằng true hay người dùng dùng cử chỉ vuốt, 
                    // ta chủ động gọi cả hai hàm load lại dữ liệu tổng và đếm thông báo để đồng bộ tuyệt đối.
                    if (mounted) {
                      _checkUnreadNotifications(); // Hàm đếm thông báo riêng của bạn
                      if (hasChanged == true) {
                        _fetchHomeData(); // Tải lại toàn bộ dữ liệu trang chủ (nếu có hàm này) để cập nhật lại UI
                      }
                    }
                  }),
                  
                  // Chỉ hiển thị nếu thực sự có thông báo mới hơn ID đã đọc gần nhất
                  if (_unreadCount > 0)
                    Positioned(
                      right: 4,  
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              // 🔥 ĐOẠN ĐƯỢC CẬP NHẬT CHỨC NĂNG ĐĂNG XUẤT CHUẨN:
              _buildHeaderButton(
                Icons.logout_rounded, 
                () {
                  // Hiển thị hộp thoại xác nhận trước khi thoát tài khoản
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Bắt buộc người dùng phải chọn Có hoặc Không
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Đăng xuất'),
                          ],
                        ),
                        content: const Text('Bạn có chắc chắn muốn thoát khỏi tài khoản này không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext), // Đóng hộp thoại nếu Hủy
                            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext); // Đóng hộp thoại xác nhận
                              
                              // Sử dụng rootNavigator: true để tắt toàn bộ cấu trúc Bottom Navigation hiện tại
                              // và đẩy thẳng người dùng ra ngoài màn hình LoginScreen gốc
                              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (Route<dynamic> route) => false, // Xóa sạch lịch sử ngăn xếp các màn hình trước đó
                              );
                            },
                            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildFloatingRoomCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildFloatingRoomCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 15))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.nightlight_round_rounded, color: Color(0xFF2563EB), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_houseName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(_roomNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          if (_hasRoom) 
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Giá thuê tháng", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 4),
                Text(_formatCurrency(_roomPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildPremiumGridMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.25,
        children: [
          // 🌟 CẬP NHẬT THẺ HỢP ĐỒNG: Thay đổi cách gọi hàm _buildPremiumMenuCard
        _buildPremiumMenuCard(
          Icons.assignment_rounded, 
          const Color(0xFFF59E0B), 
          "Hợp đồng", 
          _hasRoom ? "Xem thời hạn" : "Chưa có",
          onTap: () {
            // Điều hướng sang màn hình hợp đồng thuê trọ và truyền ID người dùng qua
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TenantContractScreen(userId: widget.userId),
              ),
            );
          },
        ),
          // Các thẻ khác giữ nguyên (thêm onTap trống tạm thời)
        // 🛠️ TÌM ĐẾN THẺ "HÓA ĐƠN" TRONG FILE HOME_SCREEN.DART VÀ CẬP NHẬT:
        _buildPremiumMenuCard(
          Icons.receipt_rounded, 
          const Color(0xFF10B981), 
          "Hóa đơn", 
          "Xem lịch sử đóng",
          onTap: () {
            // Điều hướng sang màn hình Lịch sử hóa đơn và truyền theo userId hiện tại
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TenantInvoiceScreen(userId: widget.userId),
              ),
            );
          },
        ),
        _buildPremiumMenuCard(
              Icons.credit_card, 
              const Color(0xFF8B5CF6), 
              "Lịch sử thanh toán", 
              "Xem lịch sử thanh toán", // Thay đổi nhãn mô tả cho rõ nghĩa
              onTap: () {
                //🔑 TRUYỀN CHÍNH XÁC USER_ID của tài khoản đang đăng nhập qua màn hình hiển thị[cite: 1]
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TenantPaymentHistoryScreen(userId: widget.userId),
                  ),
                );
              },
            ),
        _buildPremiumMenuCard(
          Icons.bolt_rounded, 
          const Color(0xFF06B6D4), 
          "Điện / Nước", 
          "Xem chỉ số số", 
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TenantUtilityScreen(userId: widget.userId),
              ),
            );
          },
        ),
        ],
      ),
    );
  }

  // 🌟 ĐỒNG THỜI SỬA LẠI THAM SỐ CỦA HÀM _buildPremiumMenuCard ĐỂ NHẬN SỰ KIỆN ONTAP:
Widget _buildPremiumMenuCard(IconData icon, Color color, String title, String subtitle, {required VoidCallback onTap}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // 🌟 Nhận sự kiện nhấn từ đây
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPremiumInvoiceCard() {
    if (_latestInvoice == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.shade100, width: 1),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text("Tuyệt vời! Không có hóa đơn nợ.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // 1. Lấy tổng tiền gốc của hóa đơn kỳ này
    final double totalAmount = double.tryParse(_latestInvoice!['Total']?.toString() ?? '0') ?? 0.0;
    // 💡 LẤY SỐ TIỀN CHƯA THANH TOÁN (CÒN NỢ) TRỰC TIẾP TỪ BACKEND TRẢ VỀ
    final double remainingDebt = double.tryParse(_latestInvoice!['Debt']?.toString() ?? '0') ?? 0.0;
    final String period = _latestInvoice!['Period'] ?? "";
    final String status = _latestInvoice!['Status'] ?? "Chưa thanh toán";
    final bool isPaid = status == "Đã thanh toán";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPaid ? Colors.green.shade100 : const Color(0xFFFEF2F2), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: isPaid ? Colors.green[50] : const Color(0xFFFEF2F2), shape: BoxShape.circle),
                  child: Icon(
                    isPaid ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded, 
                    color: isPaid ? Colors.green : const Color(0xFFEF4444), 
                    size: 24
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tiền nhà Kỳ tháng $period", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 3),
                      Text(
                        "Trạng thái: $status", 
                        style: TextStyle(color: isPaid ? Colors.green : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tổng tiền cần thanh toán", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(_formatCurrency(remainingDebt), style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: remainingDebt > 0 ? const Color(0xFFEF4444) : const Color(0xFF1E293B))),
                  ],
                ),
                if (!isPaid) 
                  ElevatedButton(
                    onPressed: () async {
                      //     // Lấy invoiceId từ API trả về (tùy thuộc vào tên key id hóa đơn của bạn trong SQL, ví dụ 'InvoiceID' hoặc 'id')
                      // final String invoiceId = _latestInvoice!['InvoiceID']?.toString() ?? '0';

                      // // Chuyển sang màn hình thanh toán MoMo và đợi kết quả trả về khi back lại
                      // final isSuccess = await Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => PaymentScreen(
                      //       userId: widget.userId,
                      //       amount: remainingDebt, // Số tiền nợ thực tế cần đóng
                      //       invoiceId: invoiceId,
                      //       period: period,
                      //     ),
                      //   ),
                      // );

                      // // Nếu thanh toán thành công và quay lại, tự động refresh lại data trang chủ để cập nhật giao diện
                      // if (isSuccess == true) {
                      //   _fetchHomeData();
                      // }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Thanh toán", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}