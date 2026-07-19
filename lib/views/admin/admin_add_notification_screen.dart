import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAddNotificationScreen extends StatefulWidget {
  final int userId;
  final int? initialHouseId; 
  const AdminAddNotificationScreen({super.key, required this.userId, this.initialHouseId});

  @override
  State<AdminAddNotificationScreen> createState() => _AdminAddNotificationScreenState();
}

class _AdminAddNotificationScreenState extends State<AdminAddNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSending = false;
  
  List<dynamic> _houses = [];
  int? _selectedHouseId; // null có nghĩa là "Tất cả nhà trọ"
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
      final response = await http.get(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/Admin/GetHouses.php?user_id=${widget.userId}'),
        headers: {"X-User-Id": widget.userId.toString()},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _houses = data['data'] ?? [];
            _isLoadingHouses = false;
          });
          return;
        }
      }
    } catch (e) {
      print("Error fetching houses: $e");
    }
    setState(() => _isLoadingHouses = false);
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/CreateNotification.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "NguoiGuiId": widget.userId,
          "NhaTroId": _selectedHouseId, // Nếu là null, API sẽ xử lý gửi cho tất cả (hoặc tùy logic DB)
          "TieuDe": _titleController.text.trim(),
          "NoiDung": _contentController.text.trim(),
        }),
      );
      
      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phát hành thông báo thành công!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(res['message'] ?? "Lỗi từ máy chủ");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red)
      );
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
        title: const Text("Tạo Thông Báo Hệ Thống", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                    const Text("PHẠM VI THÔNG BÁO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
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
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("Toàn bộ các nhà trọ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                        labelText: "Tiêu đề thông báo",
                        prefixIcon: const Icon(Icons.title_rounded, color: primaryColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Vui lòng nhập tiêu đề" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 8,
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
                          elevation: 2,
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
