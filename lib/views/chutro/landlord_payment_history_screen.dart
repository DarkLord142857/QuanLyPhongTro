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
  bool _isProcessing = false; // Trạng thái đợi gọi API duyệt thu tiền
  
  // 🛠️ ĐƯỜNG DẪN API LẤY DANH SÁCH LỊCH SỬ DÒNG TIỀN GỐC CỦA BẠN
  final String _apiUrl = "http://10.0.2.2/myapi/src/Controllers/GetPaymentHistoryLandlord.php";
  
  // 🛠️ ĐƯỜNG DẪN API PHÊ DUYỆT GẠCH NỢ CHỦ TRỌ
  final String _approveUrl = "http://10.0.2.2/myapi/src/Controllers/LandlordDirectPayment.php";

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  // Hàm lấy lịch sử dòng tiền từ API gốc của bạn
  Future<void> _fetchPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$_apiUrl?landlord_id=${widget.landlordId}"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _payments = data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải lịch sử dòng tiền: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Hàm gọi API duyệt tiền gửi lên server
  Future<void> _approveInvoicePayment(int hoaDonId, double soTienThu) async {
    if (hoaDonId <= 0 || soTienThu <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi: Mã hóa đơn hoặc số tiền không hợp lệ!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_approveUrl));
      request.fields['hoadon_id'] = hoaDonId.toString();
      request.fields['sotien_nhan'] = soTienThu.toString();

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? "Duyệt thu tiền thành công!"), backgroundColor: Colors.green),
          );
          _fetchPaymentHistory(); // Tải lại danh sách để cập nhật giao diện
        } else {
          throw Exception(responseData['message'] ?? "Lỗi xử lý duyệt tiền.");
        }
      } else {
        throw Exception("Không thể kết nối đến máy chủ.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Thất bại: ${e.toString().replaceAll('Exception:', '')}"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showApproveDialog(int hoaDonId, double soTienThu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận duyệt tiền", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Bạn có chắc chắn muốn duyệt hóa đơn này với số tiền ${soTienThu.toInt()}đ không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
            onPressed: () {
              Navigator.pop(context);
              _approveInvoicePayment(hoaDonId, soTienThu);
            },
            child: const Text("Đồng ý duyệt", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Hàm format tiền thành dạng 1 225 000đ như bạn mong muốn
  String formatMoney(num amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]} '
    ) + 'đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Lịch sử dòng tiền", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _fetchPaymentHistory,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? const Center(child: Text("Chưa ghi nhận dữ liệu lịch sử nào."))
              : Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final payment = _payments[index];

                        // Đọc dữ liệu ID, Số tiền đóng, Công nợ an toàn từ API trả về
                        final int hoaDonId = int.tryParse(payment['invoice_id']?.toString() ?? '') ?? 
                                             int.tryParse(payment['InvoiceId']?.toString() ?? '') ?? 0;
                        final double soTienKhachDong = double.tryParse(payment['amount_paid']?.toString() ?? '') ?? 0.0;
                        final double congNo = double.tryParse(payment['cong_no']?.toString() ?? 
                                              payment['CongNo']?.toString() ?? '') ?? 0.0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Phòng: ${payment['room_number'] ?? 'N/A'}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                    ),
                                    
                                    // 🛠️ LOGIC HIỂN THỊ BADGE TRẠNG THÁI DỰA VÀO CÔNG NỢ
                                    if (congNo == 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                                        child: const Text("Đã thanh toán", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          "Còn nợ: ${formatMoney(congNo)}", 
                                          style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold)
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("Khách thuê: ${payment['customer_name'] ?? 'N/A'}", style: const TextStyle(color: Colors.black, fontSize: 13)),
                                Text("Kỳ hóa đơn: ${payment['period'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Số tiền khách gửi đóng:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text(
                                          formatMoney(soTienKhachDong), 
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue)
                                        ),
                                      ],
                                    ),
                                    
                                    // 🛠️ LOGIC ẨN/HIỆN NÚT DUYỆT: Chỉ hiện nút khi công nợ lớn hơn 0
                                    if (congNo > 0 && hoaDonId > 0)
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: _isProcessing 
                                            ? null 
                                            : () => _showApproveDialog(hoaDonId, soTienKhachDong),
                                        child: const Text("Duyệt thu thêm", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black26,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
    );
  }
}