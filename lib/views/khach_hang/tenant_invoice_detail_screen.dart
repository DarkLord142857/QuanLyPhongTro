import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TenantInvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  const TenantInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<TenantInvoiceDetailScreen> createState() => _TenantInvoiceDetailScreenState();
}

class _TenantInvoiceDetailScreenState extends State<TenantInvoiceDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _detailData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchInvoiceDetail();
  }

  Future<void> _fetchInvoiceDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Gọi đến API GetInvoiceDetail.php của bạn
      final url = Uri.parse('http://10.0.2.2/myapi/src/Controllers/GetInvoiceDetail.php?InvoiceId=${widget.invoiceId}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _detailData = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Không thể tải chi tiết hóa đơn.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối máy chủ. Vui lòng kiểm tra lại!';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Chi tiết hóa đơn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Khối tổng quan trạng thái
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Kỳ: ${_detailData?['KyHoaDon']}",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  _buildStatusChip(_detailData?['TrangThai'] ?? ''),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow("Nhà trọ:", "${_detailData?['ThongTinPhong']['TenNha']}"),
                              _buildInfoRow("Địa chỉ:", "${_detailData?['ThongTinPhong']['DiaChi']}"),
                              _buildInfoRow("Số phòng:", "Phòng ${_detailData?['ThongTinPhong']['SoPhong']}"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Tiêu đề dịch vụ sử dụng
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: Text("CHI TIẾT DỊCH VỤ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),

                      // 3. Khối danh sách dịch vụ chi tiết
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (_detailData?['DanhSachDichVu'] as List).length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final service = _detailData?['DanhSachDichVu'][index];
                            final double donGia = (service['DonGia'] as num).toDouble();
                            final double thanhTien = (service['ThanhTien'] as num).toDouble();
                            final double chiSoCu = (service['ChiSoCu'] as num).toDouble();
                            final double chiSoMoi = (service['ChiSoMoi'] as num).toDouble();

                            // Kiểm tra dịch vụ có đồng hồ điện/nước không
                            bool hasMeter = chiSoMoi > 0 || chiSoCu > 0;

                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        service['TenDichVu'],
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                      ),
                                      Text(
                                        _formatCurrency(thanhTien),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (hasMeter)
                                    Text(
                                      "Chỉ số: ${chiSoCu.toStringAsFixed(0)} ➔ ${chiSoMoi.toStringAsFixed(0)} (${(chiSoMoi - chiSoCu).toStringAsFixed(0)} ${service['DonVi']})",
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    )
                                  else
                                    Text(
                                      "Số lượng: ${service['SoLuong']} x ${_formatCurrency(donGia)}",
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Khối tổng tiền
                      Card(
                        color: const Color(0xFFEFF6FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildTotalRow("Tổng tiền thanh toán:", _formatCurrency((_detailData?['TongTienPhaiTra'] as num).toDouble()), isBold: true),
                              const SizedBox(height: 8),
                              _buildTotalRow("Cần thanh toán còn lại:", _formatCurrency((_detailData?['CongNoConLai'] as num).toDouble()), isRed: true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false, bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isRed ? Colors.red : (isBold ? const Color(0xFF2563EB) : Colors.black),
          ),
        ),
      ],
    );
  }
}