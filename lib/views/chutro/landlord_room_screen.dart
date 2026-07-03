import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; 
import 'package:dotted_border/dotted_border.dart'; 
import '../../data/models/room_tenant_model.dart';

class LandlordRoomsScreen extends StatefulWidget {
  final VoidCallback? onBackHome;
  const LandlordRoomsScreen({super.key, this.onBackHome});

  @override
  State<LandlordRoomsScreen> createState() => _LandlordRoomsScreenState();
}

class _LandlordRoomsScreenState extends State<LandlordRoomsScreen> {
  late Future<List<RoomTenantModel>> _roomsFuture;
  final String baseUrl = 'http://10.0.2.2/myapi/src/Controllers';
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImages = false;
  final String _currentUserId = '1'; // Giả sử ID người dùng hiện tại là 1, bạn có thể thay đổi theo logic của bạn

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

  // 1. API LẤY DANH SÁCH PHÒNG
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
        _refreshData();
      }
      throw Exception("Mã lỗi từ máy chủ: ${response.statusCode}");
    } catch (e) {
      throw Exception("Không thể kết nối đến Laragon API.");
    }
  }

  // 2. API THÊM PHÒNG MỚI (Đã thêm tham số thuocTinhJson)
  Future<void> _createRoom(String soPhong, double giaPhong, int soNguoi, int soXe, List<File> images, String thuocTinhJson) async {
    try {
      var uri = Uri.parse('$baseUrl/CreateRoom.php');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'X-User-Id': _currentUserId,
        'X-Caller-Id': _currentUserId,
      });

      request.fields['NhaTroId'] = '1'; 
      request.fields['SoPhong'] = soPhong;
      request.fields['GiaPhong'] = giaPhong.toStringAsFixed(0);
      request.fields['SoNguoiToiDa'] = soNguoi.toString();
      request.fields['SoLuongXeToiDa'] = soXe.toString();
      request.fields['NguoiGuiId'] = _currentUserId;
      // 🔥 GỬI CHUỖI THUỘC TÍNH JSON LÊN PHP
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
      _showSnackBar("Lỗi kết nối mạng khi tải dữ liệu ảnh lên.", Colors.red);
    }
  }

  // 3. API CẬP NHẬT PHÒNG (Đã thêm tham số thuocTinhJson)
  Future<void> _updateRoom(int id, String soPhong, double giaPhong, int soNguoi, int soXe, List<File> images, String thuocTinhJson) async {
    try {
      var uri = Uri.parse('$baseUrl/UpdateRoom.php');
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'X-User-Id': _currentUserId,
        'X-Caller-Id': _currentUserId,
      });
      request.fields['Id'] = id.toString();
      request.fields['SoPhong'] = soPhong;
      request.fields['GiaPhong'] = giaPhong.toStringAsFixed(0);
      request.fields['SoNguoiToiDa'] = soNguoi.toString();
      request.fields['SoLuongXeToiDa'] = soXe.toString();
      request.fields['NguoiGuiId'] = _currentUserId;
      // 🔥 GỬI CHUỖI THUỘC TÍNH JSON LÊN PHP ĐỂ CẬP NHẬT
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

  // 4. API XÓA PHÒNG
  Future<void> _deleteRoom(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DeleteRoom.php'),
        headers: {
          'X-User-Id': _currentUserId,
          'X-Caller-Id': _currentUserId,
        },
        body: {
          "Id": id.toString(), 
          "NguoiXoaId": _currentUserId
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

  // Form BottomSheet dùng chung cho cả Thêm & Sửa
  void _openRoomFormBottomSheet({RoomTenantModel? roomModel}) {
    final bool isEdit = roomModel != null;
    final txtSoPhong = TextEditingController(text: isEdit ? roomModel.soPhong : "");
    final txtGiaPhong = TextEditingController(text: isEdit ? roomModel.giaPhong.toStringAsFixed(0) : "");
    final txtSoNguoi = TextEditingController(text: isEdit ? roomModel.soNguoiToiDa.toString() : "2");
    final txtSoXe = TextEditingController(text: isEdit ? roomModel.soLuongXeToiDa.toString() : "2");
    
    // 🔥 Thêm 2 Controller mới phục vụ nhập thuộc tính động diện tích và cấu trúc phòng
    final txtDienTich = TextEditingController();
    final txtTienIch = TextEditingController();
    final txtMayLanh = TextEditingController();

    // Nếu sửa, bạn có thể gán giá trị mặc định cho thuộc tính nếu model đã hỗ trợ, ví dụ minh họa:
    if (isEdit) {
      txtDienTich.text = "25m2"; // Bạn có thể map từ dữ liệu thật của roomModel nếu có
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
            if (_isPickingImages) return;
            
            _isPickingImages = true;
            try {
              final List<XFile> pickedFiles = await _picker.pickMultiImage();
              if (pickedFiles.isNotEmpty && mounted) {
                setModalState(() {
                  selectedImages = pickedFiles.map((xFile) => File(xFile.path)).toList();
                });
              }
            } catch (e) {
              if (mounted) {
                _showSnackBar("Lỗi chọn ảnh: ${e.toString()}", Colors.red);
              }
            } finally {
              _isPickingImages = false;
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
                    isEdit ? "Chỉnh sửa thông tin phòng" : "Thêm phòng trọ mới",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: txtSoPhong,
                    decoration: InputDecoration(
                      labelText: "Số phòng/Tên phòng *", 
                      prefixIcon: const Icon(Icons.meeting_room_rounded, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: txtGiaPhong,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Giá phòng (VNĐ) *", 
                      prefixIcon: const Icon(Icons.payments_rounded, color: Color(0xFF10B981)),
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
                  
                  // 🔥 ĐÃ THÊM: Giao diện nhập Thuộc tính động bổ sung
                  const SizedBox(height: 18),
                  const Text("Thông số mở rộng (Thuộc tính phòng)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: txtDienTich,
                    decoration: InputDecoration(
                      labelText: "Diện tích thực tế (Ví dụ: 25m2)", 
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
                      labelText: "Tiện ích bổ sung (Ví dụ: Có gác lửng, Cửa sổ thoáng)", 
                      prefixIcon: const Icon(Icons.star_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isEdit ? "Chọn ảnh mới để thay thế/bổ sung" : "Hình ảnh thực tế phòng trọ", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _isPickingImages ? null : pickImages,
                    borderRadius: BorderRadius.circular(12),
                    child: DottedBorder(
                      color: const Color(0xFF10B981),
                      strokeWidth: 1.5,
                      dashPattern: const [6, 4],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF10B981).withOpacity(0.04),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPickingImages ? Icons.hourglass_top_rounded : Icons.add_a_photo_rounded, 
                              color: Color(0xFF10B981), 
                              size: 28
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isPickingImages ? "Đang tải ảnh..." : "Bấm vào đây để chọn bộ sưu tập ảnh", 
                              style: TextStyle(
                                color: Color(0xFF10B981), 
                                fontWeight: FontWeight.w600, 
                                fontSize: 13
                              )
                            ),
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
                        
                        // 🔥 ĐÓNG GÓI THUỘC TÍNH THÀNH CHUỖI JSON ĐÚNG ĐỊNH DẠNG API YÊU CẦU
                        List<Map<String, dynamic>> listThuocTinh = [];
                        if (txtTienIch.text.trim().isNotEmpty) {
                          listThuocTinh.add({
                            "ThuocTinhId": 1, // 1 khớp với ID Diện tích trong DB của bạn
                            "GiaTriThucTe": txtTienIch.text.trim()
                          });
                        }
                        if (txtMayLanh.text.trim().isNotEmpty) {
                          listThuocTinh.add({
                            "ThuocTinhId": 2, // 2 khớp với ID Tiện ích/Thiết kế trong DB của bạn
                            "GiaTriThucTe": txtMayLanh.text.trim()
                          });
                        }
                        if (txtDienTich.text.trim().isNotEmpty) {
                          listThuocTinh.add({
                            "ThuocTinhId": 3, // 2 khớp với ID Tiện ích/Thiết kế trong DB của bạn
                            "GiaTriThucTe": txtDienTich.text.trim()
                          });
                        }
                        // Mã hóa list thành chuỗi đại diện JSON
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
                        backgroundColor: const Color(0xFF10B981),
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
        content: Text("Bạn có chắc chắn muốn xóa vĩnh viễn phòng $soPhong khỏi hệ thống không? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoom(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text("Xóa phòng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)), 
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      )
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
        title: const Text("Quản Lý Phòng Trọ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        backgroundColor: const Color(0xFF10B981),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 28),
            onPressed: () => _openRoomFormBottomSheet(),
            tooltip: 'Thêm phòng trọ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Làm mới dữ liệu',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF10B981),
        child: FutureBuilder<List<RoomTenantModel>>(
          future: _roomsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
            } else if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error.toString().replaceAll("Exception: ", "")}", style: const TextStyle(color: Colors.redAccent)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Khu nhà trọ chưa có phòng nào.", style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)));
            }

            final rooms = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 85), 
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final bool isOccupied = room.trangThai == 1 || room.khachThue != null; 
                
                final Color cardBgColor = isOccupied ? const Color(0xFFF0FDF4) : Colors.white; 
                final Color primaryStatusColor = isOccupied ? const Color(0xFF10B981) : const Color(0xFF64748B);
                final Color badgeBgColor = isOccupied ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), 
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isOccupied ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  Icon(Icons.door_sliding_rounded, color: primaryStatusColor, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Phòng ${room.soPhong} • ${isOccupied ? "Đang thuê" : "Phòng trống"}", 
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryStatusColor),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 20),
                                    onPressed: () => _openRoomFormBottomSheet(roomModel: room),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                    onPressed: () {
                                      if (isOccupied) {
                                        _showSnackBar("Phòng đang có khách ở, không được phép xóa!", Colors.orange);
                                      } else {
                                        _showDeleteConfirmDialog(room.phongId, room.soPhong);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Giá thuê", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                      Text(_formatCurrency(room.giaPhong), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.group_outlined, size: 18, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Giới hạn chứa", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                      Text("${room.soNguoiToiDa} người - ${room.soLuongXeToiDa} xe", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isOccupied && room.khachThue != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_pin_rounded, size: 18, color: Color(0xFF10B981)),
                                    const SizedBox(width: 8),
                                    RichText(
                                      text: TextSpan(
                                        text: "Khách thuê: ",
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                        children: [
                                          TextSpan(text: room.khachThue!.hoTen, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_android_rounded, size: 18, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Text("Số điện thoại: ${room.khachThue!.soDienThoai}", style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.cloud_done_outlined, size: 18, color: Color(0xFF94A3B8)),
                                SizedBox(width: 8),
                                Text("Phòng trống • Sẵn sàng tạo hợp đồng", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
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