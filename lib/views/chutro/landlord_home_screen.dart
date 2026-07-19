import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Thư viện gọi API
import 'dart:convert'; // Xử lý giải mã chuỗi JSON
import '../../../data/models/landlord_dashboard_model.dart';
import '../chutro/add_notification_screen.dart';
import '../chutro/landlord_service_request_screen.dart';

class LandlordHomeScreen extends StatefulWidget {
  final int userId; // Truyền id chủ trọ sau khi đăng nhập thành công vào đây

  const LandlordHomeScreen({super.key, this.userId = 2}); // Mặc định thử nghiệm bằng id = 2

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
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
    final String url = 'http://192.168.1.250/myapi/src/Controllers/GetLandlordDashboard.php?landlord_id=${widget.userId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return LandlordDashboardModel.fromJson(responseData['data']);
        } else if (responseData['status'] == 'no_house') {
          // Trả về model trống nếu chưa có nhà trọ
          return LandlordDashboardModel(
            tongPhong: 0, dangO: 0, conTrong: 0, daThu: 0, conNo: 0,
            yeuCauMoi: [], thongBaoDaGui: []
          );
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

  Future<void> _deleteNotification(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Xác nhận xóa"),
          ],
        ),
        content: const Text("Bạn có chắc muốn xóa thông báo này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Xóa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/DeleteNotification.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "id": id,
          "NguoiGuiId": widget.userId
        }),
      );
      final resData = json.decode(response.body);
      if (resData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa thông báo thành công!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        _handleRefresh();
      } else {
        throw Exception(resData['message'] ?? "Xóa thất bại");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _updateNotification(int id, String title, String content) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/UpdateNotification.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "id": id,
          "NguoiGuiId": widget.userId,
          "TieuDe": title,
          "NoiDung": content
        }),
      );
      final resData = json.decode(response.body);
      if (resData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thông báo thành công!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        _handleRefresh();
      } else {
        throw Exception(resData['message'] ?? "Cập nhật thất bại");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  void _showEditNotificationDialog(dynamic tb) {
    final titleCtrl = TextEditingController(text: tb.tieuDe);
    final contentCtrl = TextEditingController(text: tb.noiDung);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Sửa thông báo", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Tiêu đề")),
            const SizedBox(height: 12),
            TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: "Nội dung"), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              _updateNotification(int.parse(tb.id.toString()), titleCtrl.text.trim(), contentCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Xóa AppBar để dùng AppBar chung từ LandlordMainScreen
      body: SafeArea(
        child: FutureBuilder<LandlordDashboardModel>(
          future: _dashboardData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
            } else if (snapshot.hasError) {
              return Center(child: Text("${snapshot.error}".replaceAll("Exception: ", ""), style: const TextStyle(color: Colors.redAccent)));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("Không có dữ liệu hiển thị."));
            }

            final data = snapshot.data!;
            
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF10B981),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Trạng Thái Phòng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatCard("Tổng Số", "${data.tongPhong}", const Color(0xFF3B82F6), Icons.home_work_rounded),
                        const SizedBox(width: 10),
                        _buildStatCard("Đang Ở", "${data.dangO}", const Color(0xFF10B981), Icons.people_alt_rounded),
                        const SizedBox(width: 10),
                        _buildStatCard("Còn Trống", "${data.conTrong}", const Color(0xFFF59E0B), Icons.vpn_key_rounded),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text("Tài Chính Kỳ Này", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFinanceCard("Đã Thu Tháng Này", formatCurrency(data.daThu), const Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        _buildFinanceCard("Khách Thuê Còn Nợ", formatCurrency(data.conNo), const Color(0xFFEF4444)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Row(
                      children: [
                        Icon(Icons.build_circle_rounded, color: Colors.orange, size: 22),
                        SizedBox(width: 8),
                        Text("Sự cố & Yêu cầu từ khách thuê", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    data.yeuCauMoi.isEmpty
                        ? _buildEmptyWidget("Không có sự cố nào cần xử lý.")
                        : SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.yeuCauMoi.length,
                              itemBuilder: (context, index) {
                                final yc = data.yeuCauMoi[index];
                                return _buildServiceRequestCard(yc);
                              },
                            ),
                          ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.campaign_rounded, color: Color(0xFF10B981), size: 22),
                            SizedBox(width: 8),
                            Text("Thông báo chung đã gửi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981)),
                          onPressed: () => Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => AddNotificationScreen(userId: widget.userId)
                            )
                          ).then((_) => _handleRefresh()),
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
                              return _buildNotificationCard(tb);
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceCard(String title, String money, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Text(money, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRequestCard(dynamic yc) {
    final int status = int.tryParse(yc.trangThai?.toString() ?? '0') ?? 0;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LandlordServiceRequestScreen(landlordId: widget.userId))).then((_) => _handleRefresh()),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: status == 0 ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: status == 0 ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_rounded, color: status == 0 ? Colors.orange : const Color(0xFF94A3B8), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(yc.tieuDe, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 6),
            Text("Người gửi: ${yc.tenKhachHang ?? 'Khách thuê'}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Expanded(child: Text(yc.moTa, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic tb) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(tb.tieuDe, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)))),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 22),
                    onPressed: () => _showEditNotificationDialog(tb),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteNotification(int.parse(tb.id.toString())),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(tb.noiDung, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Khu vực: ${tb.tenNhaTro}", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              Text(tb.ngayTao, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text(message, style: const TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic, fontSize: 13))),
    );
  }
}
