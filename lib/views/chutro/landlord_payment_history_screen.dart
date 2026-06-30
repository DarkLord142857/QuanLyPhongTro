import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LandlordPaymentHistoryScreen extends StatefulWidget {
  final int landlordId;
  const LandlordPaymentHistoryScreen({super.key, required this.landlordId});

  @override
  State<LandlordPaymentHistoryScreen> createState() => _LandlordPaymentHistoryScreenState();
}

class _LandlordPaymentHistoryScreenState extends State<LandlordPaymentHistoryScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;
  
  // 🛠️ THAY ĐỔI ĐƯỜNG DẪN URL API THỰC TẾ CỦA BẠN TẠI ĐÂY (10.0.2.2 dùng cho giả lập Android)
  final String _apiUrl = "http://10.0.2.2/myapi/src/Controllers/GetPaymentHistoryLandlord.php";

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  // Hàm kết nối API lấy lịch sử dòng tiền từ khách thuê
  Future<void> _fetchPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$_apiUrl?landlord_id=${widget.landlordId}"));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _payments = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() => _isLoading = false);
      _showSnackBar("Lỗi hệ thống: Không thể tải lịch sử giao dịch.", Colors.red);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Lỗi kết nối máy chủ: $e", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

// 🟢 HÀM ĐỊNH DẠNG TIỀN TỆ SỬ DỤNG DẤU CHẤM CHUẨN (Ví dụ: 3.000.000 đ)
  String _formatCurrency(double amount) {
    int value = amount.toInt();
    if (value == 0) return "0 đ";
    
    String result = "";
    while (value > 0) {
      int remainder = value % 1000;
      value = value ~/ 1000;
      
      if (value > 0) {
        // Nếu còn chữ số phía trước, bù đủ 3 chữ số kèm dấu chấm ngăn cách
        result = ".${remainder.toString().padLeft(3, '0')}$result";
      } else {
        // Cụm chữ số đầu tiên bên trái không cần bù số 0
        result = "$remainder$result";
      }
    }
    return "$result đ";
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử Khách thanh toán", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10B981),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPaymentHistory,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _payments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("Chưa ghi nhận giao dịch đóng tiền nào.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Phòng ${payment['room_number']}\n(${payment['house_name']})",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    payment['payment_method'] ?? 'Tiền mặt',
                                    style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Text("Khách thuê: ${payment['customer_name']}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text("Kỳ hóa đơn: ${payment['period']}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text("Ngày đóng: ${payment['payment_date']}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            if (payment['transaction_code'] != "Không có") ...[
                              const SizedBox(height: 4),
                              Text("Mã giao dịch: ${payment['transaction_code']}", style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                            ],
                            if (payment['note'] != null && payment['note'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text("Ghi chú: ${payment['note']}", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.orange)),
                            ],
                            const Divider(height: 20),
                            
                            // 🛠️ ĐÃ SỬA: Thay đổi sang spaceBetween và ép kiểu .toDouble() an toàn cho CẢ 2 trường số tiền
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Tổng tiền hóa đơn: ${_formatCurrency(double.tryParse(payment['total_invoice_amount'].toString()) ?? 0.0)}", 
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "+ ${_formatCurrency(double.tryParse(payment['amount_paid'].toString()) ?? 0.0)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}