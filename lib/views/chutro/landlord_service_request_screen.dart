import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class LandlordServiceRequestScreen extends StatefulWidget {
  final int landlordId;
  const LandlordServiceRequestScreen({super.key, required this.landlordId});

  @override
  State<LandlordServiceRequestScreen> createState() => _LandlordServiceRequestScreenState();
}

class _LandlordServiceRequestScreenState extends State<LandlordServiceRequestScreen> {
  List<dynamic> _requests = [];
  List<dynamic> _catalog = [];
  bool _isLoading = true;
  final String _urlBase = "http://192.168.1.250/myapi/src/Controllers";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _fetchRequest();
    await _fetchCatalog();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchRequest() async {
    try {
      // API này lấy danh sách yêu cầu dịch vụ của hệ thống dựa trên landlord_id
      final res = await http.get(Uri.parse("$_urlBase/GetServiceRequest.php?landlord_id=${widget.landlordId}"));
      final data = json.decode(res.body);
      if (data['success'] == true) _requests = data['data'] ?? [];
    } catch (_) {}
  }

  Future<void> _fetchCatalog() async {
    try {
      final res = await http.get(Uri.parse("$_urlBase/ManageService.php"));
      final data = json.decode(res.body);
      if (data['success'] == true) _catalog = data['data'] ?? [];
    } catch (_) {}
  }

  Future<void> _updateStatus(int id, int serviceId) async {
    try {
      final res = await http.post(
        Uri.parse("$_urlBase/ProcessServiceRequest.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"id": id, "TrangThai": 1, "DichVuId": serviceId, "landlord_id": widget.landlordId}),
      );
      if (json.decode(res.body)['success']) {
        _loadAllData();
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {}
  }

  Future<void> _createInvoice(int id, double price) async {
    try {
      final res = await http.post(
        Uri.parse("$_urlBase/CreateServiceInvoice.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"request_id": id, "don_gia": price, "landlord_id": widget.landlordId}),
      );
      final data = json.decode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: data['success'] ? Colors.green : Colors.red));
      }
      if (data['success']) {
        _loadAllData();
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {}
  }

  void _openAcceptDialog(int reqId) {
    int? selectedId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tiếp nhận & Chọn nhóm dịch vụ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: DropdownButtonFormField<int>(
          hint: const Text("Chọn dịch vụ mẫu"),
          items: _catalog.map<DropdownMenuItem<int>>((s) => DropdownMenuItem<int>(value: int.parse(s['id'].toString()), child: Text(s['TenDichVu']))).toList(),
          onChanged: (v) => selectedId = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => selectedId != null ? _updateStatus(reqId, selectedId!) : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)), child: const Text("Bắt đầu xử lý", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  void _openInvoiceDialog(int reqId, double defaultPrice) {
    final ctrl = TextEditingController(text: defaultPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hoàn thành & Gửi hóa đơn thu tiền", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Đơn giá thu thực tế (VNĐ)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng")),
          ElevatedButton(onPressed: () => _createInvoice(reqId, double.tryParse(ctrl.text) ?? 0.0), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text("Xuất hóa đơn", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Scaffold(
      appBar: AppBar(title: const Text("Yêu cầu dịch vụ từ khách"), backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _requests.length,
              itemBuilder: (context, i) {
                final item = _requests[i];
                int status = int.tryParse(item['TrangThai'].toString()) ?? 0;
                double cost = double.tryParse(item['ChiPhi']?.toString() ?? '0') ?? 0.0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Phòng: ${item['RoomNumber'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(status == 0 ? "Chờ xử lý" : (status == 1 ? "Đang sửa" : "Đã xong/Lập HĐ"), style: TextStyle(color: status == 0 ? Colors.red : (status == 1 ? Colors.orange : Colors.green), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(),
                        Text("Tiêu đề: ${item['TieuDe'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text("Mô tả: ${item['MoTa'] ?? 'Không có mô tả'}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 0) ElevatedButton(onPressed: () => _openAcceptDialog(int.parse(item['Id'].toString())), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)), child: const Text("Tiếp nhận", style: TextStyle(color: Colors.white))),
                            if (status == 1) ElevatedButton(onPressed: () => _openInvoiceDialog(int.parse(item['Id'].toString()), cost), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text("Bàn giao & Lập HĐ", style: TextStyle(color: Colors.white))),
                            if (status == 2) const Text("🔒 Mục yêu cầu đã đóng tài chính", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13))
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}