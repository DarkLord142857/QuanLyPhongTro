import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/house_model.dart';
import '../../data/models/user_admin_model.dart';
import 'admin_main_screen.dart';
import 'admin_deleted_houses_screen.dart'; // Thêm import màn hình đã xóa
import 'admin_user_management_screen.dart'; // Thêm import màn hình quản lý user
import 'admin_revenue_statistics_screen.dart'; // Thêm import màn hình thống kê
import '../auth/login_screen.dart';

class AdminHouseListScreen extends StatefulWidget {
  final int userId;
  const AdminHouseListScreen({super.key, required this.userId});

  @override
  State<AdminHouseListScreen> createState() => _AdminHouseListScreenState();
}

class _AdminHouseListScreenState extends State<AdminHouseListScreen> {
  late Future<List<HouseModel>> _housesFuture;
  final String _baseUrl = "http://192.168.1.250/myapi/src/Controllers/Admin";
  List<UserAdminModel> _landlords = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
    _fetchLandlords();
  }

  Future<void> _fetchLandlords() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/Admin/get_users.php'),
        headers: {"X-User-Id": widget.userId.toString()},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List list = data['data'];
          setState(() {
            _landlords = list
                .map((e) => UserAdminModel.fromJson(e))
                .where((u) => u.role == 'ChuTro' && u.isDeleted == 0)
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  void _refreshData() {
    setState(() {
      _housesFuture = _fetchHouses();
    });
  }

  // 1. API Lấy danh sách
  Future<List<HouseModel>> _fetchHouses() async {
    // Gọi API để lấy danh sách nhà trọ đang hoạt động (IsDeleted = 0)
    final String url = "$_baseUrl/GetHouses.php?user_id=${widget.userId}";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"X-User-Id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List list = data['data'] ?? [];
          return list.map((e) => HouseModel.fromJson(e)).toList();
        }
      }
      throw Exception("Lỗi tải danh sách nhà trọ");
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  // 2. API Tạo mới
  Future<void> _createHouse(String name, String address, int managerId) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/CreateHouse.php"),
        headers: {
          "Content-Type": "application/json",
          "X-User-Id": widget.userId.toString()
        },
        body: json.encode({
          "TenNha": name,
          "DiaChi": address,
          "MaQL": managerId,
          "IsApproved": 1
        }),
      );
      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        _showSnackBar("Đã thêm nhà trọ mới thành công!", Colors.green);
        _refreshData();
      } else {
        _showSnackBar(res['message'] ?? "Thêm thất bại", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối server", Colors.red);
    }
  }

  // 3. API Cập nhật
  Future<void> _updateHouse(int id, String name, String address) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/UpdateHouse.php"),
        headers: {
          "Content-Type": "application/json",
          "X-User-Id": widget.userId.toString()
        },
        body: json.encode({
          "Id": id,
          "TenNha": name,
          "DiaChi": address
        }),
      );
      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        _showSnackBar("Cập nhật thông tin thành công!", const Color(0xFF10B981));
        _refreshData();
      }
    } catch (e) {
      _showSnackBar("Lỗi cập nhật", Colors.red);
    }
  }

  // 4. API Xóa (Soft Delete)
  Future<void> _deleteHouse(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/DeleteHouse.php"),
        headers: {
          "Content-Type": "application/json",
          "X-User-Id": widget.userId.toString()
        },
        body: json.encode({"Id": id}),
      );
      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        _showSnackBar("Đã xóa nhà trọ khỏi hệ thống", Colors.orange);
        _refreshData();
      }
    } catch (e) {
      _showSnackBar("Lỗi khi xóa", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // Form Dialog Thêm/Sửa
  void _openHouseForm({HouseModel? house}) {
    final isEdit = house != null;
    final nameCtrl = TextEditingController(text: isEdit ? house.tenNha : "");
    final addrCtrl = TextEditingController(text: isEdit ? house.diaChi : "");
    int? selectedLandlordId = isEdit ? house.maQL : (_landlords.isNotEmpty ? _landlords[0].id : null);
    String? dialogError; // Biến lưu lỗi hiển thị trong dialog

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? "Chỉnh sửa nhà trọ" : "Thêm nhà trọ mới"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Tên nhà trọ *")),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: "Địa chỉ *")),
              const SizedBox(height: 10),
              if (!isEdit)
                DropdownButtonFormField<int>(
                  value: selectedLandlordId,
                  decoration: const InputDecoration(labelText: "Chọn chủ quản (ChuTro) *"),
                  items: _landlords.map((u) {
                    return DropdownMenuItem<int>(
                      value: u.id,
                      child: Text(u.fullName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedLandlordId = val;
                      dialogError = null; // Xóa lỗi khi thay đổi người
                    });
                  },
                ),
              if (dialogError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    dialogError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || addrCtrl.text.isEmpty || (!isEdit && selectedLandlordId == null)) return;
                
                // KIỂM TRA XEM CHỦ TRỌ ĐÃ CÓ NHÀ QUẢN LÝ CHƯA (Chỉ kiểm tra khi thêm mới)
                if (!isEdit) {
                  try {
                    final houses = await _housesFuture;
                    bool exists = houses.any((h) => h.maQL == selectedLandlordId);
                    if (exists) {
                      setDialogState(() {
                        dialogError = "Người này đã có nhà trọ quản lý rồi!";
                      });
                      return; 
                    }
                  } catch (_) {}
                }

                Navigator.pop(ctx);
                if (isEdit) {
                  _updateHouse(house.id, nameCtrl.text, addrCtrl.text);
                } else {
                  _createHouse(nameCtrl.text, addrCtrl.text, selectedLandlordId!);
                }
              },
              child: const Text("Xác nhận"),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(HouseModel house) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa nhà trọ '${house.tenNha}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteHouse(house.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Hệ Thống Nhà Trọ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF10B981),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
            tooltip: "Thống kê doanh thu",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminRevenueStatisticsScreen(adminId: widget.userId)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.group_rounded, color: Colors.white),
            tooltip: "Quản lý tài khoản",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminUserManagementScreen(adminId: widget.userId)),
            ).then((_) => _refreshData()),
          ),
          IconButton(
            icon: const Icon(Icons.restore_from_trash_rounded, color: Colors.white),
            tooltip: "Kho lưu trữ (Đã xóa)",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminDeletedHousesScreen(userId: widget.userId)),
            ).then((_) => _refreshData()),
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _refreshData),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "admin_add_house_fab",
        onPressed: () => _openHouseForm(),
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<HouseModel>>(
        future: _housesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Chưa có nhà trọ nào."));

          final houses = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
            ),
            itemCount: houses.length,
            itemBuilder: (context, index) {
              final house = houses[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.1)),
                ),
                child: Stack(
                  children: [
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminMainScreen(userId: widget.userId, houseName: house.tenNha, houseId: house.id))),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.home_work_rounded, color: Color(0xFF10B981), size: 45),
                            const SizedBox(height: 12),
                            Text(
                              house.tenNha,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              house.diaChi,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 18, color: Color(0xFF10B981)), onPressed: () => _openHouseForm(house: house)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _confirmDelete(house)),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
