import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../khach_hang/tenant_invoice_detail_screen.dart';

class TenantInvoiceScreen extends StatefulWidget {
  final int userId;
  const TenantInvoiceScreen({super.key, required this.userId});

  @override
  State<TenantInvoiceScreen> createState() => _TenantInvoiceScreenState();
}

class _TenantInvoiceScreenState extends State<TenantInvoiceScreen> {
  bool _isLoading = true;
  List<dynamic> _invoices = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse('http://10.0.2.2/myapi/src/Controllers/GetInvoiceController.php?user_id=${widget.userId}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _invoices = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Không thể tải danh sách hóa đơn.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối máy chủ Laragon. Vui lòng kiểm tra lại!';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  Widget _buildStatusChip(String status) {
    String text = 'Chưa thanh toán';
    Color color = Colors.red;

    if (status == 'DaThanhToan') {
      text = 'Đã thanh toán';
      color = Colors.green;
    } else if (status == 'ThanhToanMotPhan') {
      text = 'Đóng một phần';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
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
        title: const Text("Hóa đơn tiền nhà", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _invoices.isEmpty
                  ? const Center(child: Text("Hệ thống chưa ghi nhận hóa đơn nào của bạn."))
                  : RefreshIndicator(
                      onRefresh: _fetchInvoices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _invoices[index];
                          final double totalPrice = (invoice['TotalPrice'] as num).toDouble();
                          final double debt = (invoice['Debt'] as num).toDouble();
                          final int invoiceId = invoice['InvoiceId'] ?? 0;
                          return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (invoiceId > 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TenantInvoiceDetailScreen(invoiceId: invoiceId),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Không tìm thấy mã hóa đơn hợp lệ!")),
                                  );
                                }
                              },
                          child: Card(
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
                                      Text(
                                        "Kỳ hóa đơn: ${invoice['Period']}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      _buildStatusChip(invoice['Status']),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text("${invoice['HouseName']} - ${invoice['RoomNumber']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Tổng tiền hóa đơn", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(_formatCurrency(totalPrice), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text("Còn nợ lại", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatCurrency(debt), 
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: debt > 0 ? Colors.red : Colors.green)
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          );
                        },
                      ),
                    ),
    );
  }
}