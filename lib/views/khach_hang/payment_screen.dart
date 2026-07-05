import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  final int userId;
  final int hoaDonId;
  final double tongTien;
  final double congNo;
  final int nguoiNhanId; // ID Chủ trọ để lưu vào lịch sử thanh toán

  const PaymentScreen({
    super.key,
    required this.userId,
    required this.hoaDonId,
    required this.tongTien,
    required this.congNo,
    required this.nguoiNhanId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  bool _isSubmitting = false;
  String _selectedMethod = 'ChuyenKhoanNH'; // Mặc định chuyển khoản

  @override
  void initState() {
    super.initState();
    // Gợi ý sẵn số tiền cần đóng bằng số tiền còn nợ hiện tại
    _amountController.text = widget.congNo.toInt().toString();
  }

// 🛠️ HÀM ĐÃ ĐƯỢC CẬP NHẬT: Chuyển tiền thành dạng "1 225 000đ" thay vì "1.225.000.0 đ"
  String formatMoney(num amount) {
    // Ép kiểu về số nguyên .toInt() để loại bỏ hoàn toàn phần thập phân .0 dư thừa
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]} ' // Thay dấu chấm bằng một khoảng trắng
    ) + 'đ'; // Viết liền chữ đ vào sau số
  }

  // 🛠️ HÀM KẾT NỐI API XỬ LÝ GỬI THÔNG TIN THANH TOÁN
  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // ⚡ LƯU Ý: Thay địa chỉ IP Localhost phù hợp với môi trường giả lập (10.0.2.2 cho Android Emulator)
    const String apiUrl = "http://10.0.2.2/myapi/src/Controllers/ProcessPayment.php";

    try {
      final double inputAmount = double.parse(_amountController.text.trim());

      // Đóng gói JSON truyền lên khớp 100% các biến tham số trong ProcessPayment.php
      final Map<String, dynamic> requestBody = {
        "hoadon_id": widget.hoaDonId,
        "so_tien_thanh_toan": inputAmount,
        "phuong_thuc": _selectedMethod,
        "ma_giao_dich": "GD_${DateTime.now().millisecondsSinceEpoch}", // Tự sinh mã giao dịch mẫu tránh trùng lặp
        "nguoi_nhan_id": widget.nguoiNhanId,
        "ghi_chu": _noteController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'success') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? "Gửi yêu cầu thành công!"), backgroundColor: Colors.green),
          );
          // Trả trạng thái về màn hình trước để cập nhật giao diện ngay lập tức
          Navigator.pop(context, true);
        } else {
          throw Exception(responseData['message'] ?? "Lỗi từ hệ thống xử lý.");
        }
      } else {
        throw Exception("Lỗi kết nối Server (Mã lỗi: ${response.statusCode})");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Thất bại: ${e.toString().replaceAll('Exception:', '')}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Thanh toán hóa đơn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thẻ hiển thị tóm tắt tiền nợ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tổng nợ cần thanh toán", style: TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(formatMoney(widget.congNo), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tổng tiền gốc hóa đơn:", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        Text(formatMoney(widget.tongTien), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("Số tiền muốn đóng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.monetization_on_outlined, color: Color(0xFF64748B)),
                  suffixText: "đ",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Vui lòng điền số tiền";
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return "Số tiền không hợp lệ";
                  if (numVal > widget.congNo) return "Không đóng vượt quá số tiền còn nợ";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text("Hình thức chuyển tiền", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: "ChuyenKhoanNH", child: Text("Chuyển khoản Ngân hàng")),
                  DropdownMenuItem(value: "TienMat", child: Text("Trả tiền mặt cầm tay")),
                ],
                onChanged: (val) => setState(() => _selectedMethod = val ?? 'ChuyenKhoanNH'),
              ),
              const SizedBox(height: 20),
              const Text("Lời nhắn / Ghi chú", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Nhập nội dung ghi chú kèm theo (nếu có)...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _isSubmitting
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: _submitPayment,
                        child: const Text("Xác nhận thanh toán", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}