import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../khach_hang/room_detail_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class RoomDiscoveryScreen extends StatefulWidget {
  final VoidCallback onBackHome;
  const RoomDiscoveryScreen({super.key, required this.onBackHome});

  @override
  State<RoomDiscoveryScreen> createState() => _RoomDiscoveryScreenState();
}

class _RoomDiscoveryScreenState extends State<RoomDiscoveryScreen> {
  bool _isLoading = true;
  List<dynamic> _rooms = [];         // Danh sách gốc tải về từ API
  List<dynamic> _filteredRooms = []; // DANH SÁCH SAU KHI LỌC TÌM KIẾM
  String _errorMessage = '';

  // Bộ điều khiển ô nhập liệu tìm kiếm
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAvailableRooms();
  }

  @override
  void dispose() {
    _searchController.dispose(); // Giải phóng bộ nhớ khi rời màn hình
    super.dispose();
  }

  // 🟢 HÀM KẾT NỐI VÀ LẤY DỮ LIỆU TỪ API
  Future<void> _fetchAvailableRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Endpoint API chạy dưới máy ảo Android kết nối tới Localhost (Laragon/XAMPP) via IP 192.168.1.250
      final url = Uri.parse('http://192.168.1.250/myapi/src/Controllers/RoomDiscoveryController.php');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          setState(() {
            _rooms = responseData['data'];
            _filteredRooms = List.from(_rooms); // Sao chép sang mảng lọc ban đầu
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Không thể tải dữ liệu phòng.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi kết nối Server (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi ngoại lệ: Không thể kết nối tới server mạng.';
        _isLoading = false;
      });
    }
  }

  // Hàm xử lý tìm kiếm theo Số phòng hoặc Tên khu nhà trọ
  void _filterRooms(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredRooms = _rooms;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredRooms = _rooms.where((room) {
        final soPhong = room['RoomNumber']?.toString().toLowerCase() ?? '';
        final tenNha = room['HouseName']?.toString().toLowerCase() ?? '';
        final diaChi = room['Address']?.toString().toLowerCase() ?? '';
        return soPhong.contains(lowercaseQuery) || 
               tenNha.contains(lowercaseQuery) ||
               diaChi.contains(lowercaseQuery);
      }).toList();
    });
  }

  // Định dạng hiển thị giá tiền tệ Việt Nam (Ví dụ: 3.500.000)
  String _formatPrice(dynamic price) {
    if (price == null) return "0 đ";
    final value = double.tryParse(price.toString())?.toInt() ?? 0;
    return "${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ/tháng";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: widget.onBackHome,
        ),
        title: const Text(
          "Khám phá phòng trống",
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔎 THANH TÌM KIẾM TÍCH HỢP BỘ LỌC TỰ ĐỘNG
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterRooms, // Mỗi khi nhập chữ, tự động chạy hàm lọc
              decoration: InputDecoration(
                hintText: "Tìm số phòng, tên nhà trọ, địa chỉ...",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 22),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterRooms('');
                      },
                    )
                  : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
            ),
          ),

          // PHẦN HIỂN THỊ DANH SÁCH PHÒNG
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchAvailableRooms,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                                child: const Text("Tải lại", style: TextStyle(color: Colors.white)),
                              )
                            ],
                          ),
                        ),
                      )
                    : _filteredRooms.isEmpty
                        ? const Center(
                            child: Text("Không tìm thấy phòng trọ nào phù hợp.", style: TextStyle(color: Color(0xFF64748B))),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAvailableRooms,
                            color: const Color(0xFF2563EB),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredRooms.length,
                              itemBuilder: (context, index) {
                                final room = _filteredRooms[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RoomDetailScreen(roomId: room['RoomId']),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // KHỐI HIỂN THỊ HÌNH ẢNH THUMBNAIL
                                       ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            bottomLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                          child: Container(
                                            width: double.infinity,                                           
                                            height: 180,
                                            color: const Color(0xFFF1F5F9),
                                            child: room['HinhAnhDaiDien'] != null && room['HinhAnhDaiDien'].toString().isNotEmpty
                                                ? Image.network(
                                                    room['HinhAnhDaiDien'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => _buildDefaultThumbnail(),
                                                  )
                                                : _buildDefaultThumbnail(),
                                          ),
                                        ),
                                        // KHỐI THÔNG TIN PHÒNG
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "Phòng ${room['RoomNumber']}",
                                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                  ),
                                                  Text(
                                                    _formatPrice(room['Price']),
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                room['HouseName'] ?? 'Nhà trọ',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      room['Address'] ?? 'Đang cập nhật địa chỉ',
                                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.group_outlined, size: 16, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "Tối đa: ${room['MaxPeople']} người",
                                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // Hàm bổ trợ tạo ảnh thu nhỏ mặc định
  Widget _buildDefaultThumbnail() {
    return const Center(
      child: Icon(
        Icons.room_preferences_outlined,
        size: 40,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}