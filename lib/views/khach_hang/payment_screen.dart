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

String formatMoney(num amount) {
  // RegExp tìm mỗi vị trí có 3 chữ số để chèn dấu cách
  RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return amount.toInt().toString().replaceAllMapped(reg, (Match match) => '${match[1]} ');
}

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Tạo một mã giao dịch giả lập
    String mockTransactionId = "TXN${DateTime.now().millisecondsSinceEpoch}";

    final String url = 'http://10.0.2.2/myapi/src/Controllers/ProcessPayment.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        // 🌟 Đồng bộ viết hoa viết thường chuẩn xác theo file ProcessPayment.php của bạn
        body: json.encode({
          "hoadon_id": widget.hoaDonId,
          "so_tien_thanh_toan": double.parse(_amountController.text),
          "phuong_thuc": _selectedMethod,
          "ma_giao_dich": mockTransactionId,
          "nguoi_nhan_id": widget.nguoiNhanId,
          "ghiChu": _noteController.text.trim().isEmpty 
              ? "Khách thuê thanh toán hóa đơn" 
              : _noteController.text.trim()
        }),
      ).timeout(const Duration(seconds: 10));

      final res = json.decode(response.body);

      if (res['status'] == 'success') {
        // Hiển thị hộp thoại thông báo trạng thái "Chờ xử lý / Đã ghi nhận" thành công
        _showSuccessDialog();
      } else {
        _showSnackBar("❌ Lỗi: ${res['message']}", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("❌ Không thể kết nối đến máy chủ: $e", Colors.redAccent);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // 🌟 Đã bổ sung đầy đủ hàm hiển thị Dialog thành công
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 60),
              const SizedBox(height: 18),
              const Text(
                "Gửi yêu cầu thành công!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              const Text(
                "Giao dịch của bạn đã được ghi nhận. Hệ thống đang chuyển trạng thái chờ xử lý, chủ trọ sẽ duyệt sớm nhất có thể.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Đóng Dialog
                    Navigator.pop(context, true); // Quay về và reload dữ liệu ở màn trước
                  },
                  child: const Text("Đồng ý", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🌟 Đã bổ sung đầy đủ hàm hiển thị thông báo SnackBar nhanh
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: color, 
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Thanh Toán Hóa Đơn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- KHỐI THÔNG TIN HÓA ĐƠN ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Mã hóa đơn: #${widget.hoaDonId}", style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Tổng tiền hóa đơn:", style: TextStyle(color: Color(0xFF1E293B), fontSize: 15)),
                              Text("${formatMoney(widget.tongTien.toInt())} đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Số tiền còn nợ:", style: TextStyle(color: Color(0xFF1E293B), fontSize: 15)),
                              Text("${formatMoney(widget.congNo.toInt())} đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- NHẬP SỐ TIỀN MUỐN ĐÓNG ---
                    const Text("Nhập số tiền muốn thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2563EB)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        suffixText: "đ",
                        hintText: "Ví dụ: 2000000",
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Vui lòng nhập số tiền";
                        double? amount = double.tryParse(val);
                        if (amount == null || amount <= 0) return "Số tiền không hợp lệ";
                        if (amount > widget.congNo) return "Số tiền vượt quá số nợ hiện tại (${widget.congNo.toInt()} đ)";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- PHƯƠNG THỨC THANH TOÁN ---
                    const Text("Phương thức thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMethod,
                      items: const [
                        DropdownMenuItem(value: 'ChuyenKhoanNH', child: Text('Chuyển khoản ngân hàng')),
                        DropdownMenuItem(value: 'Tiền mặt', child: Text('Tiền mặt')),
                      ],
                      onChanged: (val) => setState(() => _selectedMethod = val!),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- GHI CHÚ ---
                    const Text("Ghi chú (Nếu có)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Nội dung lời nhắn gửi chủ nhà...",
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- NÚT XÁC NHẬN ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
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

