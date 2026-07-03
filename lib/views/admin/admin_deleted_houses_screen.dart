import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/house_model.dart';

class AdminDeletedHousesScreen extends StatefulWidget {
  final int userId;
  const AdminDeletedHousesScreen({super.key, required this.userId});

  @override
  State<AdminDeletedHousesScreen> createState() => _AdminDeletedHousesScreenState();
}

class _AdminDeletedHousesScreenState extends State<AdminDeletedHousesScreen> {
  late Future<List<HouseModel>> _deletedHousesFuture;
  final String _baseUrl = "http://10.0.2.2/myapi/src/Controllers/Admin";

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _deletedHousesFuture = _fetchDeletedHouses();
    });
  }

  Future<List<HouseModel>> _fetchDeletedHouses() async {
    // Gọi API với flag include_deleted=1 và có thể lọc thêm logic ở đây nếu API hỗ trợ
    // Hoặc giả định API GetHouses.php trả về cả danh sách nếu ta truyền tham số phù hợp
    final String url = "$_baseUrl/GetHouses.php?user_id=${widget.userId}&include_deleted=1";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"X-User-Id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List list = data['data'] ?? [];
          // Chỉ lọc lấy những cái đã bị xóa (IsDeleted == 1)
          return list
              .map((e) => HouseModel.fromJson(e))
              .where((h) => h.isDeleted == 1)
              .toList();
        }
      }
      throw Exception("Lỗi tải danh sách lưu trữ");
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  Future<void> _restoreHouse(int id) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/RestoreHouse.php"),
        headers: {
          "Content-Type": "application/json",
          "X-User-Id": widget.userId.toString()
        },
        body: json.encode({"Id": id}),
      );
      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã khôi phục nhà trọ thành công!"), backgroundColor: Colors.green),
        );
        _refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Khôi phục thất bại"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi kết nối server"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Kho Lưu Trữ (Đã Xóa)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.grey[700],
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<HouseModel>>(
        future: _deletedHousesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Không có nhà trọ nào trong thùng rác.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final houses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: houses.length,
            itemBuilder: (context, index) {
              final house = houses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.home_work_rounded, color: Colors.grey),
                  ),
                  title: Text(
                    house.tenNha,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(house.diaChi),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _restoreHouse(house.id),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text("Khôi phục"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
