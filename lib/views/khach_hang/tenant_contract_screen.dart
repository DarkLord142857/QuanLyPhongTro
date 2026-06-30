import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TenantContractScreen extends StatefulWidget {
  final int userId; // Nhận userId từ Home truyền sang
  const TenantContractScreen({super.key, required this.userId});

  @override
  State<TenantContractScreen> createState() => _TenantContractScreenState();
}

class _TenantContractScreenState extends State<TenantContractScreen> {
  bool _isLoading = true;
  List<dynamic> _contracts = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchContracts();
  }

  // Kết nối API tổng hợp hợp đồng từ máy chủ Laragon
  Future<void> _fetchContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // 🌟 Kết nối đến đúng file API xử lý thuộc tính isActive của bạn
      final url = Uri.parse('http://10.0.2.2/myapi/src/Controllers/GetContractController.php?user_id=${widget.userId}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _contracts = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Không thể tải danh sách hợp đồng.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối máy chủ Laragon. Vui lòng thử lại!';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return dateStr;
    }
  }

  // Xử lý hiển thị nhãn dựa trên giá trị của cột isActive (chuỗi hoặc số)
  Widget _buildStatusChip(dynamic status) {
    String text = 'Hết hạn / Đã hủy';
    Color color = Colors.red;
    
    // Nếu database lưu số 1 hoặc chuỗi '1' hoặc chữ 'ConHan' nghĩa là hợp đồng hợp lệ
    if (status == 1 || status == '1' || status == 'ConHan') {
      text = 'Còn thời hạn';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Hợp đồng thuê phòng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _errorMessage.isNotEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ))
              : _contracts.isEmpty
                  ? const Center(child: Text("Bạn chưa có hợp đồng thuê nhà nào trên hệ thống."))
                  : RefreshIndicator(
                      onRefresh: _fetchContracts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20.0),
                        itemCount: _contracts.length,
                        itemBuilder: (context, index) {
                          final contract = _contracts[index];
                          final double price = (contract['RoomPrice'] as num).toDouble();
                          final double deposit = (contract['Deposit'] as num).toDouble();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${contract['HouseName']} - Phòng ${contract['RoomNumber']}",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                      _buildStatusChip(contract['Status']),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(contract['Address'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildFinancialInfo("Giá thuê phòng", _formatCurrency(price), Colors.red),
                                      _buildFinancialInfo("Tiền đặt cọc", _formatCurrency(deposit), Colors.blueAccent),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.date_range_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Chu kỳ: ${_formatDate(contract['StartDate'])} - ${_formatDate(contract['EndDate'])}",
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                  if (contract['Terms'] != null && contract['Terms'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("📌 Điều khoản ký kết:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.yellow)),
                                          const SizedBox(height: 4),
                                          Text(contract['Terms'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
                                        ],
                                      ),
                                    )
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildFinancialInfo(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}