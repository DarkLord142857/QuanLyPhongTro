import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; 
import 'package:dotted_border/dotted_border.dart'; 
import '../../data/models/room_tenant_model.dart';

class LandlordRoomsScreen extends StatefulWidget {
  final int landlordId;
  final VoidCallback? onBackHome;
  const LandlordRoomsScreen({super.key, required this.landlordId, this.onBackHome});

  @override
  State<LandlordRoomsScreen> createState() => _LandlordRoomsScreenState();
}

class _LandlordRoomsScreenState extends State<LandlordRoomsScreen> {
  late Future<List<RoomTenantModel>> _roomsFuture;
  List<dynamic> _houses = [];
  final String baseUrl = 'http://192.168.1.250/myapi/src/Controllers';
  final ImagePicker _picker = ImagePicker();
  final Color primaryColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _refreshData();
    _fetchHouses();
  }

  Future<void> _fetchHouses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/GetHouses.php?user_id=${widget.landlordId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _houses = data['data'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching houses: $e");
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _roomsFuture = _fetchRoomsWithTenants();
    });
  }

  Future<List<RoomTenantModel>> _fetchRoomsWithTenants() async {
    // 🔥 NGĂN VÁCH DỮ LIỆU: Chỉ lấy phòng của chủ trọ này
    final String url = '$baseUrl/GetRoom.php?landlord_id=${widget.landlordId}';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == 'success' && res['data'] != null) {
          final List<dynamic> data = res['data'] as List<dynamic>;
          return data.map<RoomTenantModel>((item) => RoomTenantModel.fromJson(item as Map<String, dynamic>)).toList();
        }
        throw Exception(res['message'] ?? 'Lỗi không xác định');
      }
      throw Exception("Lỗi HTTP: ${response.statusCode}");
    } catch (e) {
      throw Exception("Lỗi kết nối máy chủ: $e");
    }
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Xóa AppBar vì dùng chung AppBar của LandlordMainScreen
      floatingActionButton: FloatingActionButton(
        heroTag: "landlord_add_room_fab",
        onPressed: () => _openRoomFormBottomSheet(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: FutureBuilder<List<RoomTenantModel>>(
          future: _roomsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primaryColor));
            } else if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
              ));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Bạn chưa có phòng trọ nào."));
            }

            final rooms = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final bool isOccupied = room.trangThai == 1 || room.khachThue != null;
                return _buildRoomCard(room, isOccupied);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoomCard(RoomTenantModel room, bool isOccupied) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isOccupied ? primaryColor.withOpacity(0.1) : const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              child: room.hinhAnh.isNotEmpty
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: room.hinhAnh.length,
                    itemBuilder: (context, idx) {
                      String imageUrl = room.hinhAnh[idx];
                      if (!imageUrl.startsWith('http')) {
                        imageUrl = 'http://192.168.1.250/myapi/uploads/$imageUrl';
                      }
                      return Image.network(
                        imageUrl,
                        width: MediaQuery.of(context).size.width * 0.85,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultThumbnail(),
                      );
                    },
                  )
                : _buildDefaultThumbnail(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isOccupied ? primaryColor.withOpacity(0.05) : const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.meeting_room_rounded, color: isOccupied ? primaryColor : const Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text("Phòng ${room.soPhong}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                  _buildStatusBadge(isOccupied),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(Icons.payments_outlined, "Giá thuê", _formatCurrency(room.giaPhong)),
                      _buildInfoItem(Icons.people_outline_rounded, "Tối đa", "${room.soNguoiToiDa} người"),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  if (room.danhSachThuocTinh.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: room.danhSachThuocTinh.map((attr) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "${attr.tenThuocTinh}: ${attr.giaTriThucTe}${attr.donVi ?? ''}",
                            style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isOccupied && room.khachThue != null) ...[
                    Row(
                      children: [
                        const CircleAvatar(radius: 14, backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.person, size: 16, color: Colors.blue)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(room.khachThue!.hoTen, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(room.khachThue!.soDienThoai, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openRoomFormBottomSheet(roomModel: room),
                          icon: Icon(Icons.edit_outlined, size: 18, color: primaryColor),
                          label: Text("Chỉnh sửa", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmDialog(room.phongId, room.soPhong),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_not_supported_rounded, size: 40, color: Color(0xFF94A3B8)), SizedBox(height: 8), Text("Chưa có hình ảnh", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))]),
    );
  }

  Widget _buildStatusBadge(bool isOccupied) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isOccupied ? primaryColor.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(isOccupied ? "ĐANG THUÊ" : "TRỐNG", style: TextStyle(color: isOccupied ? primaryColor : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 14, color: const Color(0xFF94A3B8)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))]),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  void _openRoomFormBottomSheet({RoomTenantModel? roomModel}) async {
    final bool isEdit = roomModel != null;
    final roomNumberCtrl = TextEditingController(text: isEdit ? roomModel.soPhong : "");
    final priceCtrl = TextEditingController(text: isEdit ? roomModel.giaPhong.toString() : "");
    final capacityCtrl = TextEditingController(text: isEdit ? roomModel.soNguoiToiDa.toString() : "2");
    final vehicleCtrl = TextEditingController(text: isEdit ? roomModel.soLuongXeToiDa.toString() : "2");
    
    int? selectedHouseId = isEdit ? roomModel.nhaTroId : (_houses.isNotEmpty ? int.tryParse(_houses[0]['Id'].toString()) : null);
    List<File> selectedImages = [];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEdit ? "Cập nhật phòng" : "Thêm phòng mới", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Chọn nhà trọ
                const Text("Nhà trọ quản lý", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedHouseId,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF10B981)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true, fillColor: Colors.grey[50],
                  ),
                  items: _houses.map((h) => DropdownMenuItem<int>(
                    value: int.tryParse(h['Id'].toString()),
                    child: Text(h['TenNha']),
                  )).toList(),
                  onChanged: isEdit ? null : (val) => setModalState(() => selectedHouseId = val),
                  hint: const Text("Chọn nhà trọ"),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Số phòng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: roomNumberCtrl,
                            decoration: InputDecoration(
                              hintText: "VD: 101",
                              prefixIcon: const Icon(Icons.meeting_room_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Giá thuê (đ/tháng)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "3500000",
                              prefixIcon: const Icon(Icons.payments_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Số người tối đa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: capacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.people_alt_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Số xe tối đa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: vehicleCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.directions_bike_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text("Hình ảnh phòng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...selectedImages.map((file) => Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedImages.remove(file)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      )),
                      GestureDetector(
                        onTap: () async {
                          final List<XFile> images = await _picker.pickMultiImage();
                          if (images.isNotEmpty) {
                            setModalState(() {
                              selectedImages.addAll(images.map((x) => File(x.path)));
                            });
                          }
                        },
                        child: DottedBorder(
                          color: const Color(0xFF10B981),
                          strokeWidth: 2,
                          dashPattern: const [6, 3],
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(15),
                          child: Container(
                            width: 100,
                            height: 100,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.add_a_photo_rounded, color: Color(0xFF10B981)), Text("Thêm ảnh", style: TextStyle(fontSize: 10, color: Color(0xFF10B981)))],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: isSubmitting ? null : () async {
                      if (roomNumberCtrl.text.isEmpty || priceCtrl.text.isEmpty || selectedHouseId == null) {
                        _showSnackBar("Vui lòng nhập đầy đủ thông tin bắt buộc!", Colors.orange);
                        return;
                      }

                      setModalState(() => isSubmitting = true);

                      try {
                        var request = http.MultipartRequest(
                          'POST',
                          Uri.parse(isEdit ? '$baseUrl/UpdateRoom.php' : '$baseUrl/CreateRoom.php')
                        );

                        request.headers.addAll({
                          "X-User-Id": widget.landlordId.toString(),
                        });

                        if (isEdit) request.fields['Id'] = roomModel.phongId.toString();
                        request.fields['NhaTroId'] = selectedHouseId.toString();
                        request.fields['SoPhong'] = roomNumberCtrl.text.trim();
                        request.fields['GiaPhong'] = priceCtrl.text.trim();
                        request.fields['SoNguoiToiDa'] = capacityCtrl.text.trim();
                        request.fields['SoLuongXeToiDa'] = vehicleCtrl.text.trim();
                        request.fields['TrangThai'] = isEdit ? roomModel.trangThai.toString() : "0";

                        for (var file in selectedImages) {
                          request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
                        }

                        var streamedResponse = await request.send();
                        var response = await http.Response.fromStream(streamedResponse);
                        var resData = json.decode(response.body);

                        if (resData['status'] == 'success') {
                          Navigator.pop(ctx);
                          _showSnackBar(resData['message'], const Color(0xFF10B981));
                          _refreshData();
                        } else {
                          _showSnackBar(resData['message'] ?? "Lỗi không xác định", Colors.red);
                        }
                      } catch (e) {
                        _showSnackBar("Lỗi kết nối server: $e", Colors.red);
                      } finally {
                        setModalState(() => isSubmitting = false);
                      }
                    },
                    child: isSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? "CẬP NHẬT PHÒNG" : "TẠO PHÒNG TRỌ MỚI", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(int id, String soPhong) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận xóa", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Bạn muốn xóa phòng $soPhong khỏi hệ thống?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await http.post(
                  Uri.parse('$baseUrl/DeleteRoom.php'),
                  headers: {"Content-Type": "application/json"},
                  body: json.encode({"Id": id, "NguoiXoaId": widget.landlordId})
                );
                final res = json.decode(response.body);
                if (res['status'] == 'success') {
                  _showSnackBar("Đã xóa phòng thành công", primaryColor);
                  _refreshData();
                } else {
                  _showSnackBar(res['message'], Colors.red);
                }
              } catch (e) {
                _showSnackBar("Lỗi khi xóa", Colors.red);
              }
            }, 
            child: const Text("Xác nhận xóa", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }
}
