import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminManageCatalogScreen extends StatefulWidget {
  final int landlordId;
  const AdminManageCatalogScreen({super.key, required this.landlordId});

  @override
  State<AdminManageCatalogScreen> createState() => _AdminManageCatalogScreenState();
}

class _AdminManageCatalogScreenState extends State<AdminManageCatalogScreen> {
  List<dynamic> _services = [];
  bool _isLoading = true;
  final String _apiUrl = "http://10.0.2.2/myapi/src/Controllers/ManageService.php";

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(_apiUrl));
      final data = json.decode(res.body);
      if (data['success'] == true) _services = data['data'] ?? [];
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _saveService(int? id, String name, double cost, String desc) async {
    try {
      final bodyData = json.encode({"id": id, "TenDichVu": name, "ChiPhi": cost, "MoTa": desc});
      http.Response res;
      if (id == null) {
        res = await http.post(Uri.parse(_apiUrl), headers: {"Content-Type": "application/json"}, body: bodyData);
      } else {
        res = await http.put(Uri.parse(_apiUrl), headers: {"Content-Type": "application/json"}, body: bodyData);
      }
      if (json.decode(res.body)['success']) {
        _fetchCatalog();
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {}
  }

  Future<void> _deleteService(int id) async {
    try {
      final res = await http.delete(Uri.parse("$_apiUrl?id=$id&nguoi_xoa_id=${widget.landlordId}"));
      if (json.decode(res.body)['success']) _fetchCatalog();
    } catch (_) {}
  }

  void _showFormDialog(Map<String, dynamic>? item) {
    final nameCtrl = TextEditingController(text: item?['TenDichVu'] ?? '');
    final costCtrl = TextEditingController(text: item?['ChiPhi']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item?['MoTa'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? "Thêm dịch vụ (Admin)" : "Cập nhật dịch vụ (Admin)"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Tên dịch vụ *")),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Đơn giá *")),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Mô tả")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && costCtrl.text.isNotEmpty) {
                _saveService(item != null ? int.parse(item['id'].toString()) : null, nameCtrl.text, double.tryParse(costCtrl.text) ?? 0.0, descCtrl.text);
              }
            },
            child: const Text("Lưu lại", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Scaffold(
      appBar: AppBar(title: const Text("Bảng giá Admin"), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _services.length,
              itemBuilder: (context, i) {
                final item = _services[i];
                double chiPhi = double.tryParse(item['ChiPhi']?.toString() ?? '0') ?? 0.0;
                return Card(
                  child: ListTile(
                    title: Text(item['TenDichVu'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${fmt.format(chiPhi)}\n${item['MoTa'] ?? ''}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showFormDialog(item)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(int.parse(item['id'].toString()))),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showFormDialog(null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
