import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestServiceScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onSuccessRedirect; // Hàm callback để nhảy về Tab Trang chủ
  const RequestServiceScreen({super.key, required this.userId, required this.onSuccessRedirect});

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  // Danh mục sự cố phổ biến gợi ý nhanh
  String _selectedCategory = 'Điện & Ánh sáng';
  final List<String> _categories = [
    'Điện & Ánh sáng',
    'Nước & Thiết bị vệ sinh',
    'Nội thất & Cửa',
    'Thiết bị điện tử (Điều hòa, Máy giặt)',
    'An ninh & Khóa cửa',
    'Sự cố khác'
  ];

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    final String url = 'http://192.168.1.250/myapi/src/Controllers/CreateIncident.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "NguoiGuiId": widget.userId,
          "DichVuId": 1, 
          "TieuDe": "[${_selectedCategory}] ${_titleController.text.trim()}", 
          "MoTa": _descriptionController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10)); // Tự động ngắt nếu mạng quá 10 giây không phản hồi

      // Kiểm tra trạng thái HTTP trước để tránh phân tích bừa bãi
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Kiểm tra xem phản hồi có rỗng không
        if (response.body.isNotEmpty) {
          final Map<String, dynamic> result = json.decode(response.body);

          // Nếu API trả về cấu trúc { status: 'success', ... }
          if (result['status'] == 'success') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Gửi yêu cầu dịch vụ thành công!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _titleController.clear();
              _descriptionController.clear();
              // Quay về Tab chính nếu callback được cung cấp
             // try { widget.onSuccessRedirect(); } catch (_) {}
            }
          } else {
            final String message = result['message']?.toString() ?? 'Server phản hồi không thành công.';
            throw Exception(message);
          }
        } else {
          throw Exception('Phản hồi rỗng từ server.');
        }
      } else {
        // Nếu API lỗi (Ví dụ 500 hoặc 404), thông báo lỗi nhẹ nhàng thay vì làm đen màn hình
        throw Exception('Server trả về mã lỗi: ${response.statusCode}');
      }

    } catch (e) {
      // Bắt mọi loại lỗi mạng, lỗi parse dữ liệu để hiển thị lên SnackBar, bảo vệ màn hình không bị đen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Không thể gửi yêu cầu: ${e.toString()}'), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Yêu Cầu Dịch Vụ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => widget.onSuccessRedirect(),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Phân loại danh mục dịch vụ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          items: _categories.map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).map((item) => item).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Tiêu đề ngắn gọn", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: "Ví dụ: Điều hòa không mát, vòi sen bị gãy...",
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                      ),
                      validator: (v) => v!.trim().isEmpty ? "Vui lòng nhập tiêu đề dịch vụ" : null,
                    ),
                    const SizedBox(height: 20),
                    const Text("Nội dung mô tả chi tiết hư hỏng", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Mô tả trạng thái hư hại hiện tại (ví dụ: Bật điều hòa lên quạt vẫn quay nhưng không có hơi lạnh phả ra, có hiện tượng rỉ nước ở cục lạnh...)",
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.4),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                      ),
                      validator: (v) => v!.trim().isEmpty ? "Vui lòng nhập nội dung mô tả chi tiết để chủ nhà nắm bắt" : null,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _submitIncident,
                        icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        label: const Text("Gửi Yêu Cầu", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}