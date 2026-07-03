import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; 
import 'package:dotted_border/dotted_border.dart'; 
import '../../data/models/room_tenant_model.dart';

class AdminRoomsScreen extends StatefulWidget {
  final VoidCallback? onBackHome;
  const AdminRoomsScreen({super.key, this.onBackHome});

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  late Future<List<RoomTenantModel>> _roomsFuture;
  final String baseUrl = 'http://10.0.2.2/myapi/src/Controllers';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _roomsFuture = _fetchRoomsWithTenants();
    });
    await _roomsFuture.catchError((_) => <RoomTenantModel>[]); 
  }

  Future<List<RoomTenantModel>> _fetchRoomsWithTenants() async {
    final String url = '$baseUrl/GetRoomWithTenants.php';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == 'success' && res['data'] != null) {
          List data = res['data'];
          return data.map((item) => RoomTenantModel.fromJson(item)).toList();
        }
      }
      throw Exception("Mã lỗi từ máy chủ: ${response.statusCode}");
    } catch (e) {
      throw Exception("Không thể kết nối đến Laragon API.");
    }
  }

  Future<void> _createRoom(String soPhong, double giaPhong, int soNguoi, int soXe, List<File> images, String thuocTinhJson) async {
    try {
      var uri = Uri.parse('$baseUrl/CreateRoom.php');
      var request = http.MultipartRequest('POST', uri);

      request.fields['NhaTroId'] = '1'; 
      request.fields['SoPhong'] = soPhong;
      request.fields['GiaPhong'] = giaPhong.toStringAsFixed(0);
      request.fields['SoNguoiToiDa'] = soNguoi.toString();
      request.fields['SoLuongXeToiDa'] = soXe.toString();
      request.fields['ThuocTinh'] = thuocTinhJson;

      for (var file in images) {
        request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final res = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(res['message'] ?? "Thêm phòng thành công!", Colors.green);
        _refreshData();
      } else {
        _showSnackBar(res['message'] ?? "Thêm phòng thất bại.", Colors.orange);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối mạng.", Colors.red);
    }
  }

  Future<void> _updateRoom(int id, String soPhong, double giaPhong, int soNguoi, int soXe, List<File> images, String thuocTinhJson) async {
    try {
      var uri = Uri.parse('$baseUrl/UpdateRoom.php');
      var request = http.MultipartRequest('POST', uri);

      request.fields['Id'] = id.toString();
      request.fields['SoPhong'] = soPhong;
      request.fields['GiaPhong'] = giaPhong.toStringAsFixed(0);
      request.fields['SoNguoiToiDa'] = soNguoi.toString();
      request.fields['SoLuongXeToiDa'] = soXe.toString();
      request.fields['ThuocTinh'] = thuocTinhJson;

      for (var file in images) {
        request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final res = json.decode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar(res['message'] ?? "Cập nhật thành công!", Colors.green);
        _refreshData(); 
      } else {
        _showSnackBar(res['message'] ?? "Cập nhật thất bại.", Colors.orange);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối mạng khi cập nhật.", Colors.red);
    }
  }

  Future<void> _deleteRoom(int id) async {
    int currentAdminId = 1; 
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DeleteRoom.php'),
        body: {
          "Id": id.toString(), 
          "NguoiXoaId": currentAdminId.toString()
        },
      );
      
      final res = json.decode(response.body);
      if (response.statusCode == 200) {
        _showSnackBar(res['message'] ?? "Đã xóa phòng thành công!", Colors.green);
        _refreshData();
      } else {
        _showSnackBar(res['message'] ?? "Xóa phòng thất bại.", Colors.orange);
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống hoặc mất kết nối mạng.", Colors.red);
    }
  }

  void _openRoomFormBottomSheet({RoomTenantModel? roomModel}) {
    final bool isEdit = roomModel != null;
    final txtSoPhong = TextEditingController(text: isEdit ? roomModel.soPhong : "");
    final txtGiaPhong = TextEditingController(text: isEdit ? roomModel.giaPhong.toStringAsFixed(0) : "");
    final txtSoNguoi = TextEditingController(text: isEdit ? roomModel.soNguoiToiDa.toString() : "2");
    final txtSoXe = TextEditingController(text: isEdit ? roomModel.soLuongXeToiDa.toString() : "2");
    
    final txtDienTich = TextEditingController();
    final txtTienIch = TextEditingController();
    final txtMayLanh = TextEditingController();

    if (isEdit) {
      txtDienTich.text = "25m2"; 
      txtTienIch.text = "Có gác lửng";
      txtMayLanh.text = "0";
    }
    
    List<File> selectedImages = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          
          Future<void> pickImages() async {
            final List<XFile> pickedFiles = await _picker.pickMultiImage();
            if (pickedFiles.isNotEmpty) {
              setModalState(() {
                selectedImages = pickedFiles.map((xFile) => File(xFile.path)).toList();
              });
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 24, left: 20, right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45, height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEdit ? "Chỉnh sửa thông tin phòng (Admin)" : "Thêm phòng trọ mới (Admin)",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: txtSoPhong,
                    decoration: InputDecoration(
                      labelText: "Số phòng/Tên phòng *", 
                      prefixIcon: const Icon(Icons.meeting_room_rounded, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: txtGiaPhong,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Giá phòng (VNĐ) *", 
                      prefixIcon: const Icon(Icons.payments_rounded, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: txtSoNguoi,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Số người tối đa", 
                            prefixIcon: const Icon(Icons.group_rounded, color: Color(0xFF64748B)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: txtSoXe,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Số xe tối đa", 
                            prefixIcon: const Icon(Icons.directions_bike_rounded, color: Color(0xFF64748B)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 18),
                  const Text("Thông số mở rộng (Thuộc tính phòng)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: txtDienTich,
                    decoration: InputDecoration(
                      labelText: "Diện tích thực tế", 
                      prefixIcon: const Icon(Icons.straighten_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: txtMayLanh,
                    decoration: InputDecoration(
                      labelText: "Số lượng máy lạnh", 
                      prefixIcon: const Icon(Icons.hvac, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: txtTienIch,
                    decoration: InputDecoration(
                      labelText: "Tiện ích bổ sung", 
                      prefixIcon: const Icon(Icons.star_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isEdit ? "Chọn ảnh mới" : "Hình ảnh thực tế", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: pickImages,
                    borderRadius: BorderRadius.circular(12),
                    child: DottedBorder(
                      color: Colors.blue,
                      strokeWidth: 1.5,
                      dashPattern: const [6, 4],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.blue.withOpacity(0.04),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: Colors.blue, size: 28),
                            SizedBox(height: 6),
                            Text("Bấm vào đây để chọn bộ sưu tập ảnh", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, idx) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(selectedImages[idx], width: 80, height: 80, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4, right: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        selectedImages.removeAt(idx);
                                      });
                                    },
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.black.withOpacity(0.6),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (txtSoPhong.text.trim().isEmpty || txtGiaPhong.text.trim().isEmpty) {
                          _showSnackBar("Vui lòng điền đủ số phòng và giá phòng!", Colors.orange);
                          return;
                        }
                        
                        List<Map<String, dynamic>> listThuocTinh = [];
                        if (txtTienIch.text.trim().isNotEmpty) {
                          listThuocTinh.add({"ThuocTinhId": 1, "GiaTriThucTe": txtTienIch.text.trim()});
                        }
                        if (txtMayLanh.text.trim().isNotEmpty) {
                          listThuocTinh.add({"ThuocTinhId": 2, "GiaTriThucTe": txtMayLanh.text.trim()});
                        }
                        if (txtDienTich.text.trim().isNotEmpty) {
                          listThuocTinh.add({"ThuocTinhId": 3, "GiaTriThucTe": txtDienTich.text.trim()});
                        }
                        String targetThuocTinhJson = json.encode(listThuocTinh);

                        Navigator.pop(context);
                        
                        final String sPhong = txtSoPhong.text.trim();
                        final double gPhong = double.tryParse(txtGiaPhong.text.trim()) ?? 0.0;
                        final int sNguoi = int.tryParse(txtSoNguoi.text.trim()) ?? 2;
                        final int sXe = int.tryParse(txtSoXe.text.trim()) ?? 2;

                        if (isEdit) {
                          _updateRoom(roomModel.phongId, sPhong, gPhong, sNguoi, sXe, selectedImages, targetThuocTinhJson);
                        } else {
                          _createRoom(sPhong, gPhong, sNguoi, sXe, selectedImages, targetThuocTinhJson);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(isEdit ? "Cập nhật ngay" : "Tạo phòng mới", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(int id, String soPhong) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Xác nhận xóa phòng", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Bạn có chắc chắn muốn xóa vĩnh viễn phòng $soPhong?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoom(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Xóa phòng", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color, behavior: SnackBarBehavior.floating)
    );
  }

  String _formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (widget.onBackHome != null) {
              widget.onBackHome!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text("Quản Lý Phòng Trọ (Admin)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 28),
            onPressed: () => _openRoomFormBottomSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refreshData,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.blue,
        child: FutureBuilder<List<RoomTenantModel>>(
          future: _roomsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.blue));
            } else if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error.toString()}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Chưa có phòng nào."));
            }

            final rooms = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 85), 
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final bool isOccupied = room.isActive == 1 || room.khachThue != null; 
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), 
                  decoration: BoxDecoration(
                    color: isOccupied ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isOccupied ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Phòng ${room.soPhong}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openRoomFormBottomSheet(roomModel: room)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRoom(room.phongId)),
                              ],
                            )
                          ],
                        ),
                        Text("Giá: ${_formatCurrency(room.giaPhong)}"),
                        Text("Trạng thái: ${isOccupied ? "Đang thuê" : "Trống"}"),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
