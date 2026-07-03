import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../data/models/landlord_dashboard_model.dart';
import 'admin_add_notification_screen.dart'; 
import 'admin_service_request_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final int userId;
  final String houseName;
  final int houseId;

  const AdminHomeScreen({
    super.key,
    required this.userId,
    this.houseName = "Tổng Quan Admin",
    this.houseId = 1,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<LandlordDashboardModel> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = fetchDashboardData();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _dashboardData = fetchDashboardData();
    });
  }

  Future<LandlordDashboardModel> fetchDashboardData() async {
    // Truyền thêm MaQL (houseId) để lấy đúng dữ liệu của nhà trọ được chọn
    final String url = 'http://10.0.2.2/myapi/src/Controllers/GetLandlordDashboard.php?landlord_id=${widget.userId}&MaQL=${widget.houseId}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "X-User-Id": widget.userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return LandlordDashboardModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Lỗi không xác định từ máy chủ.');
        }
      } else {
        throw Exception('Mất kết nối tới máy chủ (Mã lỗi: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Không thể tải dữ liệu tổng quan: $e');
    }
  }

  String formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.houseName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminAddNotificationScreen(userId: widget.userId),
                ),
              ).then((value) {
                _handleRefresh();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _handleRefresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
      top: true,
      bottom: false,
      child: FutureBuilder<LandlordDashboardModel>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "${snapshot.error}".replaceAll("Exception: ", ""),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Không có dữ liệu hiển thị.", style: TextStyle(color: Color(0xFF64748B))));
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.blue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Trạng Thái Hệ Thống", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCard("Tổng Số Phòng", "${data.tongPhong}", const Color(0xFF3B82F6), Icons.home_work_rounded),
                      const SizedBox(width: 10),
                      _buildStatCard("Đang Ở", "${data.dangO}", const Color(0xFF10B981), Icons.people_alt_rounded),
                      const SizedBox(width: 10),
                      _buildStatCard("Còn Trống", "${data.conTrong}", const Color(0xFFF59E0B), Icons.vpn_key_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text("Tài Chính Admin", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFinanceCard("Tổng Đã Thu", formatCurrency(data.daThu), const Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      _buildFinanceCard("Tổng Còn Nợ", formatCurrency(data.conNo), const Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Yêu Cầu Dịch Vụ Mới", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          "${data.yeuCauMoi.where((element) => (element as dynamic).trangThai == 0).length} Dịch vụ",
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.build_circle_rounded, color: Colors.orange, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Sự cố & Yêu cầu từ khách thuê",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              data.yeuCauMoi.isEmpty
                  ? _buildEmptyWidget("Không có sự cố hay yêu cầu dịch vụ nào cần xử lý.")
                  : SizedBox(
                      height: 150,
                      child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.yeuCauMoi.length,
                      itemBuilder: (context, index) {
                        final yc = data.yeuCauMoi[index];
                        final int status = int.tryParse((yc as dynamic).trangThai?.toString() ?? '0') ?? 0;
                        final bool isNotProcessed = status == 0;
                        return InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminServiceRequestScreen(landlordId: widget.userId),
                            ),
                          );
                          if (result == true) {
                            _handleRefresh();
                          }
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8, 
                          margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: status == 0 
                                ? const Color(0xFFFFF7ED) 
                                : (status == 1 ? const Color(0xFFFEFCE8) : Colors.white), 
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: status == 0 
                                  ? const Color(0xFFFFEDD5) 
                                  : (status == 1 ? const Color(0xFFFEF08A) : const Color(0xFFF1F5F9)),
                              width: status == 2 ? 1.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.build_rounded, color: isNotProcessed ? Colors.orange : const Color(0xFF94A3B8), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      yc.tieuDe,
                                      maxLines: 1,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                    ),
                                  ),
                                  if (!isNotProcessed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
                                      child: const Text("Đã xong", style: TextStyle(color: Color(0xFF065F46), fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                ],
                              ),
                              const SizedBox(height: 6),

                              Text("Người gửi: ${(yc as dynamic).tenKhachHang ?? 'Khách thuê'}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Expanded(
                                    child: Text(
                                      yc.moTa,
                                      maxLines: 2, 
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.campaign_rounded, color: Colors.blue, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Thông báo Admin đã gửi",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blue),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminAddNotificationScreen(userId: widget.userId)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              data.thongBaoDaGui.isEmpty
                  ? _buildEmptyWidget("Chưa phát đi thông báo nào.")
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.thongBaoDaGui.length,
                      itemBuilder: (context, index) {
                        final tb = data.thongBaoDaGui[index];

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tb.tieuDe,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tb.noiDung,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Khu vực: ${tb.tenNhaTro}",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    tb.ngayTao,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceCard(String title, String money, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(money, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(child: Text(message, style: const TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic, fontSize: 13))),
    );
  }
}
