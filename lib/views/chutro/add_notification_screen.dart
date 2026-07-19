import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddNotificationScreen extends StatefulWidget {
  final int userId; 
  final int? initialHouseId; 
  const AddNotificationScreen({super.key, required this.userId, this.initialHouseId});

  @override
  State<AddNotificationScreen> createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSending = false;

  List<dynamic> _houses = [];
  int? _selectedHouseId; 
  bool _isLoadingHouses = true;

  @override
  void initState() {
    super.initState();
    _selectedHouseId = widget.initialHouseId;
    _fetchHouses();
  }

  Future<void> _fetchHouses() async {
    setState(() => _isLoadingHouses = true);
    try {
      // Dùng GetHouses.php (phiên bản tổng quát cho cả Landlord)
      final response = await http.get(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/GetHouses.php?user_id=${widget.userId}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _houses = data['data'] ?? [];
            
            // Nếu chưa chọn nhà, mặc định chọn nhà đầu tiên (hoặc All nếu muốn)
            if (_selectedHouseId == null && _houses.isNotEmpty) {
              _selectedHouseId = int.tryParse(_houses[0]['Id'].toString());
            }
            _isLoadingHouses = false;
          });
          return;
        }
      }
    } catch (e) {
      print("Error: $e");
    }
    setState(() => _isLoadingHouses = false);
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHouseId == null && _houses.isNotEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn khu nhà để thông báo"), backgroundColor: Colors.orange));
       return;
    }
    
    setState(() => _isSending = true);

    final String url = 'http://192.168.1.250/myapi/src/Controllers/CreateNotification.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "NguoiGuiId": widget.userId,
          "NhaTroId": _selectedHouseId, 
          "TieuDe": _titleController.text.trim(),
          "NoiDung": _contentController.text.trim(),
        }),
      );
      
      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã phát hành thông báo thành công!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        throw Exception(res['message'] ?? "Lỗi từ máy chủ");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tạo Thông Báo Mới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
        backgroundColor: primaryColor, 
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingHouses 
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("GỬI ĐẾN KHU NHÀ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      value: _selectedHouseId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.business_rounded, color: primaryColor),
                      ),
                      items: [
                        // Cho phép chủ trọ gửi cho tất cả nhà họ quản lý nếu có nhiều nhà
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("Tất cả các khu nhà quản lý", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                        ..._houses.map((h) => DropdownMenuItem<int?>(
                          value: int.tryParse(h['Id'].toString()),
                          child: Text(h['TenNha'] ?? "Khu trọ"),
                        )),
                      ],
                      onChanged: (val) => setState(() => _selectedHouseId = val),
                    ),
                    const SizedBox(height: 24),
                    const Text("NỘI DUNG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Tiêu đề",
                        prefixIcon: const Icon(Icons.title_rounded, color: primaryColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Vui lòng nhập tiêu đề" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: "Nội dung chi tiết",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Vui lòng nhập nội dung" : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isSending 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("PHÁT HÀNH THÔNG BÁO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
