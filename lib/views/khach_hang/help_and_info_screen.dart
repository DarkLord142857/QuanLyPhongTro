import 'package:flutter/material.dart';

class HelpAndInfoScreen extends StatelessWidget {
  final VoidCallback onBackHome;
  const HelpAndInfoScreen({super.key, required this.onBackHome});

  // Hàm tiện ích để hiển thị nội dung chi tiết dạng Bottom Sheet (Cuộn lên từ dưới)
  void _showPolicyDetail(BuildContext context, String title, List<Map<String, String>> sections) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Thanh kéo nhỏ phía trên cùng thanh tiêu đề
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFF1E293B)
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              // Nội dung điều khoản chi tiết
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sections[index]['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 15, 
                              fontWeight: FontWeight.bold, 
                              color: Color(0xFF2563EB)
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sections[index]['content'] ?? '',
                            style: const TextStyle(
                              fontSize: 14, 
                              color: Color(0xFF475569), 
                              height: 1.5
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dữ liệu nội dung: Điều khoản cam kết
    final List<Map<String, String>> commitmentTerms = [
      {
        "title": "1. Cam kết nghĩa vụ thanh toán",
        "content": "Người thuê trọ có trách nhiệm thanh toán đầy đủ tiền phòng, tiền điện, nước và các chi phí dịch vụ đi kèm trước ngày 05 hàng tháng thông qua hóa đơn hiển thị trên ứng dụng."
      },
      {
        "title": "2. Quy định giữ gìn tài sản",
        "content": "Cam kết bảo quản các trang thiết bị nội thất, thiết bị điện và hạ tầng phòng trọ được bàn giao. Mọi hành vi làm hư hỏng do lỗi chủ quan phải bồi thường theo giá trị thị trường."
      },
      {
        "title": "3. An toàn phòng cháy chữa cháy (PCCC)",
        "content": "Tuyệt đối không lưu trữ chất dễ cháy nổ, không tự ý câu móc hệ thống điện trái phép. Tắt toàn bộ thiết bị điện công suất lớn khi ra khỏi phòng."
      },
      {
        "title": "4. Quy định an ninh trật tự công cộng",
        "content": "Không gây ồn ào, mở nhạc lớn ảnh hưởng tới các phòng xung quanh sau 23h00. Tuân thủ việc đăng ký tạm trú tạm vắng theo đúng quy định của pháp luật hiện hành."
      }
    ];

    // Dữ liệu nội dung: Chính sách bảo mật thông tin
    final List<Map<String, String>> privacyPolicies = [
      {
        "title": "1. Thu thập thông tin cá nhân",
        "content": "Hệ thống quản lý chỉ thu thập các thông tin cơ bản phục vụ cho việc lập hợp đồng và quản lý cư trú bao gồm: Họ tên, Số điện thoại, Email, Hình ảnh CCCD/Chứng minh nhân dân."
      },
      {
        "title": "2. Mục đích sử dụng thông tin",
        "content": "Thông tin của bạn được dùng để xác thực tài khoản, thông báo hóa đơn, cập nhật trạng thái sửa chữa dịch vụ khẩn cấp và gửi các thông báo quan trọng từ chủ trọ."
      },
      {
        "title": "3. Cam kết bảo mật an toàn dữ liệu",
        "content": "Mọi dữ liệu cá nhân và lịch sử giao dịch thanh toán đều được mã hóa trên máy chủ trung tâm. Chúng tôi cam kết không bán, không chia sẻ thông tin của người thuê cho bất kỳ bên thứ ba nào khi chưa có sự đồng ý."
      },
      {
        "title": "4. Quyền chỉnh sửa của người dùng",
        "content": "Người thuê có toàn quyền cập nhật lại thông tin cá nhân hoặc yêu cầu khóa/xóa tài khoản khi chấm dứt hợp đồng thuê trọ thông qua ban quản lý tòa nhà."
      }
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        // 🔥 Thêm nút mũi tên quay lại kích hoạt callback nhảy về Trang chủ
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: onBackHome, 
        ),
        title: const Text(
          "Trợ giúp & Thông tin", 
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner tổng đài hỗ trợ 24/7
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tổng đài hỗ trợ 24/7",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Nếu bạn gặp bất kỳ sự cố nào về phòng trọ hoặc ứng dụng, vui lòng liên hệ ngay với chúng tôi.",
                    style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // CARD 1: HOTLINE LIÊN HỆ GỌI KHẨN CẤP
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFEF4444)),
                ),
                title: const Text("Hotline", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                subtitle: const Text(
                  "0987.654.321",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đang kết nối tới tổng đài hỗ trợ...")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Gọi ngay", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // PHẦN PHÁP LÝ: ĐIỀU KHOẢN VÀ CHÍNH SÁCH
            const Text(
              "Chính sách & Quy định",
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Nút bấm mở Điều khoản cam kết
                  ListTile(
                    leading: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF10B981)),
                    title: const Text(
                      "Điều khoản cam kết của khách thuê", 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => _showPolicyDetail(context, "Điều khoản cam kết", commitmentTerms),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  
                  // Nút bấm mở Chính sách bảo mật
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6)),
                    title: const Text(
                      "Chính sách bảo mật thông tin", 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => _showPolicyDetail(context, "Chính sách bảo mật ứng dụng", privacyPolicies),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARD: GIỜ GIẤC HOẠT ĐỘNG PHỤ TRỢ Phía dưới
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time_rounded, color: Colors.orange, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Thời gian xử lý kỹ thuật khẩn cấp", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        SizedBox(height: 2),
                        Text("07:00 - 22:00 (Hàng ngày kể cả CN)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}