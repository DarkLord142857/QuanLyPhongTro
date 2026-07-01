import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddNotificationScreen extends StatefulWidget {
  final int userId; // ID chủ trọ
  const AddNotificationScreen({super.key, required this.userId});

  @override
  State<AddNotificationScreen> createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    // Sử dụng IP trỏ từ máy ảo về server Laragon
    final String url = 'http://10.0.2.2/myapi/src/Controllers/CreateNotification.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "NguoiGuiId": widget.userId,
          "NhaTroId": 1, // Đơn giản hóa: Mặc định gửi thông báo chung cho toàn khu
          "TieuDe": _titleController.text.trim(),
          "NoiDung": _contentController.text.trim(),
        }),
      );
      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã phát hành thông báo!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo Thông Báo Mới"), backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
      body: _isSending 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Tiêu đề thông báo", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Không được để trống" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: "Nội dung chi tiết", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Không được để trống" : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _sendNotification,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        child: const Text("Gửi Cho Khách Thuê", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}