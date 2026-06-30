import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LandlordInvoiceScreen extends StatefulWidget {
  final int landlordId;
  const LandlordInvoiceScreen({super.key, required this.landlordId});

  @override
  State<LandlordInvoiceScreen> createState() => _LandlordInvoiceScreenState();
}

class _LandlordInvoiceScreenState extends State<LandlordInvoiceScreen> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;
  final String _baseUrl = "http://10.0.2.2/myapi/src/Controllers"; // 🛠️ Thay URL của bạn

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

// 🟢 HÀM ĐỊNH DẠNG TIỀN TỆ SỬ DỤNG INTL (Định dạng chính xác: 3.000.000 đ)
  String _formatCurrency(dynamic amount) {
    if (amount == null) return "0 đ";
    final double value = double.tryParse(amount.toString()) ?? 0.0;
    final formatter = NumberFormat("#,##0", "vi_VN");
    return "${formatter.format(value).replaceAll(',', '.')} đ";
  }

  // 1. API: Lấy danh sách hóa đơn
  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$_baseUrl/GetLandlordInvoices.php?user_id=${widget.landlordId}"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _invoices = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối máy chủ: $e", Colors.red);
    }
  }

  // 2. API: Xóa hóa đơn (Soft Delete)
  Future<void> _deleteInvoice(int invoiceId) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/DeleteInvoice.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "hoa_don_id": invoiceId,
          "nguoi_xoa_id": widget.landlordId,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        _showSnackBar("Đã xóa hóa đơn thành công!", Colors.green);
        _fetchInvoices();
      } else {
        _showSnackBar(data['message'] ?? "Xóa thất bại.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống: $e", Colors.red);
    }
  }

  // 3. API: Tạo hoặc Cập nhật hóa đơn
  Future<void> _saveInvoice({int? invoiceId, required Map<String, dynamic> payload}) async {
    final isUpdate = invoiceId != null;
    final url = isUpdate ? "$_baseUrl/UpdateInvoice.php" : "$_baseUrl/CreateInvoice.php";
    
    if (isUpdate) payload["hoa_don_id"] = invoiceId;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        _showSnackBar(data['message'], Colors.green);
        Navigator.pop(context);
        _fetchInvoices();
      } else {
        _showSnackBar(data['message'], Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi thực thi dữ liệu: $e", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }



  // Dialog nhập form chốt số điện nước mới hoặc sửa đổi
  void _openInvoiceFormDialog(dynamic invoice) {
    final isEdit = invoice != null;
    final periodCtrl = TextEditingController(text: isEdit ? invoice['Period'] : '');
    final roomCtrl = TextEditingController(text: isEdit ? invoice['RoomNumber'] : '');
    final roomPriceCtrl = TextEditingController(text: isEdit ? invoice['TotalPrice'].toString() : '3500000');
    final dCuCtrl = TextEditingController(text: '1200');
    final dMoiCtrl = TextEditingController(text: '1350');
    final nCuCtrl = TextEditingController(text: '300');
    final nMoiCtrl = TextEditingController(text: '312');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Cập nhật hóa đơn" : "Tạo hóa đơn điện nước"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEdit) TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: "Mã số phòng (ID)")),
              TextField(controller: periodCtrl, decoration: const InputDecoration(labelText: "Kỳ hóa đơn (Ví dụ: 07/2026)")),
              TextField(controller: roomPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Tiền thuê phòng")),
              const Divider(),
              Row(
                children: [
                  Expanded(child: TextField(controller: dCuCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Điện cũ"))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: dMoiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Điện mới"))),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: nCuCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Nước cũ"))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: nMoiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Nước mới"))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              final payload = {
                "nguoi_lap_id": widget.landlordId,
                "phong_tro_id": int.tryParse(roomCtrl.text) ?? 1,
                "ky_hoa_don": periodCtrl.text,
                "tien_phong": double.tryParse(roomPriceCtrl.text) ?? 0,
                "dien": {"cu": double.tryParse(dCuCtrl.text) ?? 0, "moi": double.tryParse(dMoiCtrl.text) ?? 0, "don_gia": 3500},
                "nuoc": {"cu": double.tryParse(nCuCtrl.text) ?? 0, "moi": double.tryParse(nMoiCtrl.text) ?? 0, "don_gia": 25000},
                "internet": 100000
              };
              _saveInvoice(invoiceId: isEdit ? invoice['InvoiceId'] : null, payload: payload);
            },
            child: const Text("Xác nhận lưu"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý hóa đơn phòng trọ"),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        backgroundColor: const Color(0xFF10B981),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () => _openInvoiceFormDialog(null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _invoices.isEmpty
              ? const Center(child: Text("Chưa có hóa đơn nào được lập."))
              : ListView.builder(
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final item = _invoices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item['Status'] == 'DaThanhToan' ? Colors.green.shade100 : Colors.orange.shade100,
                          child: Icon(Icons.receipt_long, color: item['Status'] == 'DaThanhToan' ? Colors.green : Colors.orange),
                        ),
                        title: Text("Phòng ${item['RoomNumber']} - Kỳ ${item['Period']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        // 🛠️ ĐÃ CẬP NHẬT: Thay đổi hiển thị số tiền qua hàm _formatCurrency để tạo định dạng 3.000.000 đ
                        subtitle: Text(
                          "Tổng: ${_formatCurrency(item['TotalPrice'])}\n"
                          "Còn nợ: ${_formatCurrency(item['Debt'])}\n"
                          "Khách: ${item['CustomerName'] ?? 'Chưa xác định'}"
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openInvoiceFormDialog(item)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteInvoice(item['InvoiceId']),
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