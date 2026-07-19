import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tenant_invoice_screen.dart'; 

class TenantNotificationsScreen extends StatefulWidget {
  final int userId; 
  const TenantNotificationsScreen({super.key, required this.userId});

  @override
  State<TenantNotificationsScreen> createState() => _TenantNotificationsScreenState();
}

class _TenantNotificationsScreenState extends State<TenantNotificationsScreen> {
  List _notifications = [];
  bool _isLoading = true;
  String _errorMsg = '';
  bool _hasAnyReadChanged = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final String url = 'http://192.168.1.250/myapi/src/Controllers/GetTenantNotifications.php?user_id=${widget.userId}';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      final res = json.decode(response.body);
      
      if (res['status'] == 'success') {
        if (mounted) {
          setState(() {
            _notifications = res['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMsg = res['message'] ?? 'Lỗi tải thông báo';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Không thể kết nối đến máy chủ.';
          _isLoading = false;
        });
      }
    }
  }

  // 🌟 HÀM XỬ LÝ CHÍNH: Đánh dấu đã đọc ngầm lập tức để tắt chấm đỏ
    Future<void> _markAsRead(int notificationId, int index) async {
      // Nếu thông báo này vốn đã xem từ trước (trangThai == 1), bỏ qua không làm lại
      if (_notifications[index]['trangThai'] == 1) return;

      final String url = 'http://192.168.1.250/myapi/src/Controllers/UpdateNotificationStatus.php';
      
      // Bước 1: Cập nhật giao diện Local lập tức để xóa chấm đỏ trên dòng này
      setState(() {
        _notifications[index]['trangThai'] = 1;
        _hasAnyReadChanged = true; // Đánh dấu có thay đổi trạng thái đã xem
      });

      try {
        // Bước 2: Gọi API đồng bộ trạng thái lên bảng trung gian ThongBao_User của Laragon/XAMPP
        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "id": notificationId,       // Gửi ID thông báo lên trùng với $data['id'] ở PHP
            "user_id": widget.userId    // Gửi ID khách thuê trùng với $data['user_id'] ở PHP
          }),
        ).timeout(const Duration(seconds: 3));

        final res = json.decode(response.body);
        if (res['status'] != 'success') {
          // Nếu Server phản hồi thất bại, hoàn tác lại trạng thái chưa đọc để giao diện chính xác
          setState(() {
            _notifications[index]['trangThai'] = 0;
          });
        }
      } catch (e) {
        print("Lỗi đồng bộ trạng thái đã xem: $e");
      }
    }

  //Hàm phụ trợ hiển thị lỗi lên màn hình để dễ Debug
  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ $msg"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result){
        if(didPop) return;
        Navigator.pop(context, _hasAnyReadChanged); // Trả về true nếu có thông báo đã xem
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Thông Báo Từ Chủ Trọ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context, _hasAnyReadChanged), // Trả về true nếu có thông báo đã xem
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _errorMsg.isNotEmpty
              ? Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)))
              : _notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 60, color: Color(0xFF94A3B8)),
                          SizedBox(height: 12),
                          Text("Bạn không có thông báo nào mới.", style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: const Color(0xFF2563EB),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final int notiId = int.tryParse(item['id'].toString()) ?? 0;
                          final int isRead = int.tryParse(item['trangThai'].toString()) ?? 0; // 0: chưa xem, 1: đã xem
                          final String vaiTro = item['vaiTroNguoiGui'] ?? '';
                          final String tenNguoiGui = item['tenNguoiGui'] ?? 'Hệ thống';
                          final String title = item['tieuDe'] ?? "Thông báo chung";
                          final String content = item['noiDung'] ?? "";
                          String nhanNguoiGui = "Hệ thống tự động";
                            if (vaiTro == 'ChuTro' || vaiTro == 'Admin') {
                              nhanNguoiGui = "Từ chủ trọ: $tenNguoiGui";
                            } else if (item['tieuDe'].toString().contains("yêu cầu dịch vụ")) {
                              nhanNguoiGui = "Yêu cầu dịch vụ cá nhân";
                            }
                          final String timeStr = _formatDateTime(item['createdDate']);

                          final bool isInvoiceUrgent = title.toLowerCase().contains("hóa đơn") || 
                                                       title.toLowerCase().contains("tiền phòng") ||
                                                       content.toLowerCase().contains("thanh toán");

                          // Dùng InkWell bọc toàn bộ thẻ để bắt sự kiện người dùng chạm nhấn vào
                          return InkWell(
                            onTap: () => _markAsRead(notiId, index),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                // 🔥 ĐỔI MÀU NỀN THEO TRẠNG THÁI: Đã xem = Xanh lá nhạt, Chưa xem = Trắng tinh
                                color: isRead == 1 ? const Color(0xFFE8F5E9) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead == 1 
                                      ? const Color(0xFFC8E6C9) // Viền xanh lá mỏng nếu đã xem
                                      : (isInvoiceUrgent ? Colors.orange.shade200 : const Color(0xFFE2E8F0)), 
                                  width: 1
                                ),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                isInvoiceUrgent ? Icons.receipt_long_rounded : Icons.campaign_rounded, 
                                                color: isRead == 1 
                                                    ? const Color(0xFF2E7D32) // Đổi icon sang màu xanh lá đậm nếu đã xem
                                                    : (isInvoiceUrgent ? Colors.orange.shade800 : const Color(0xFF2563EB)), 
                                                size: 22
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontSize: 15, 
                                                    // Đã xem chữ vừa, chưa xem chữ in đậm (Bold) tương phản
                                                    fontWeight: isRead == 1 ? FontWeight.w500 : FontWeight.bold, 
                                                    color: isRead == 1 
                                                        ? const Color(0xFF1B5E20) // Màu xanh tiêu đề đã xem
                                                        : (isInvoiceUrgent ? Colors.orange.shade900 : const Color(0xFF0F172A))
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Hiển thị chấm tròn xanh dương thông báo mới khi chưa xem
                                        if (isRead == 0)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      content,
                                      style: TextStyle(
                                        fontSize: 14, 
                                        color: isRead == 1 ? const Color(0xFF388E3C) : const Color(0xFF334155), 
                                        height: 1.4
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          nhanNguoiGui, 
                                          style: TextStyle(
                                            fontSize: 12, 
                                            fontWeight: FontWeight.w600, 
                                            color: isRead == 1 ? const Color(0xFF4CAF50) : const Color(0xFF64748B)
                                          )
                                        ),
                                        const Spacer(),
                                        Text(                                        
                                          timeStr, 
                                          style: TextStyle(
                                            fontSize: 11, 
                                            color: isRead == 1 ? const Color(0xFF81C784) : const Color(0xFF94A3B8)
                                          )
                                        ),
                                      ],
                                    ),
                                    // if (isInvoiceUrgent) ...[
                                    //   const SizedBox(height: 12),
                                    //   SizedBox(
                                    //     width: double.infinity,
                                    //     height: 38,
                                    //     child: ElevatedButton.icon(
                                    //       onPressed: () {
                                    //         Navigator.push(
                                    //           context,
                                    //           MaterialPageRoute(
                                    //             builder: (context) => TenantInvoiceScreen(userId: widget.userId),
                                    //           ),
                                    //         );
                                    //       },
                                    //       icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white),
                                    //       label: const Text("Đóng tiền ngay", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                    //       style: ElevatedButton.styleFrom(
                                    //         backgroundColor: Colors.orange.shade700,
                                    //         elevation: 2,
                                    //         shadowColor: Colors.black.withOpacity(0.4),
                                    //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    //       ),
                                    //     ),
                                    //   )
                                    // ]
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      ),
    );
  }
}