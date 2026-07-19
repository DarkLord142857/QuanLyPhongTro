import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TenantPaymentHistoryScreen extends StatefulWidget {
  final int userId;
  const TenantPaymentHistoryScreen({super.key, required this.userId});

  @override
  State<TenantPaymentHistoryScreen> createState() => _TenantPaymentHistoryScreenState();
}

class _TenantPaymentHistoryScreenState extends State<TenantPaymentHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _historyList = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Kết nối đến API GetPaymentHistory.php trên Laragon của bạn
      final url = Uri.parse(
          'http://192.168.1.250/myapi/src/Controllers/GetPaymentHistory.php?UserId=${widget.userId}');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _historyList = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Không thể tải lịch sử thanh toán';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối máy chủ Laragon: $e';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    if (amount == null) return '0đ';
    final double parsedAmount = amount is int ? amount.toDouble() : (amount as double);
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatCurrency.format(parsedAmount);
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Lịch sử thanh toán",
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchPaymentHistory,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                          child: const Text("Tải lại", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                )
              : _historyList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            "Bạn chưa có giao dịch thanh toán nào.",
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPaymentHistory,
                      color: const Color(0xFF2563EB),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _historyList.length,
                        itemBuilder: (context, index) {
                          final tx = _historyList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Kỳ: ${tx['KyHoaDon']}",
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency((tx['SoTienDaDong'] ?? 0).toDouble()),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  ),
                                  _buildDetailRow("Phương thức:", tx['PhuongThuc'] ?? "Tiền mặt"),
                                  const SizedBox(height: 6),
                                  _buildDetailRow("Mã giao dịch:", tx['MaGiaoDich'] ?? "N/A"),
                                  const SizedBox(height: 6),
                                  _buildDetailRow("Ngày đóng:", _formatDate(tx['NgayGiaoDich'])),
                                  if (tx['GhiChu'] != null && tx['GhiChu'].toString().trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    _buildDetailRow("Ghi chú:", tx['GhiChu']),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}