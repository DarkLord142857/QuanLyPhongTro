import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // 🔥 Thêm thư viện này ở đầu file
import 'dart:convert';

class RoomDetailScreen extends StatefulWidget {
  final int roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _roomDetail;
  String _errorMessage = '';
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchRoomDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoomDetail() async {
    try {
      // 🛠️ ĐÃ ĐỒNG BỘ: Link API kết nối đến máy chủ Laragon của bạn
      final url = Uri.parse('http://192.168.1.250/myapi/src/Controllers/RoomDetailController.php?room_id=${widget.roomId}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _roomDetail = data['data']; // Lấy mảng dữ liệu nằm trong key 'data' của API
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Không thể tải thông tin phòng trọ.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối máy chủ API: $e';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  /// 🛠️ An toàn xử lý Images có thể là String, List, hoặc null
  List<dynamic> _parseImagesList(dynamic imagesData) {
    if (imagesData == null) return [];
    
    // Nếu đã là List rồi
    if (imagesData is List) return imagesData;
    
    // Nếu là String đơn lẻ, bọc nó trong một List
    if (imagesData is String) {
      return imagesData.trim().isEmpty ? [] : [imagesData.trim()];
    }
    
    // Các trường hợp khác, trả về List rỗng
    return [];
  }

// 🛠️ HÀM HIỂN THỊ BOTTOM SHEET THÔNG TIN CHỦ TRỌ
  void _showLandlordBottomSheet(BuildContext context, int landlordId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return _LandlordInfoWidget(landlordId: landlordId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    if (_errorMessage.isNotEmpty || _roomDetail == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text("Chi tiết phòng trọ")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // 🛠️ ÉP BIẾN CHUẨN ĐỒNG BỘ KEY JSON TỪ API PHP TRẢ VỀ (Hỗ trợ cả 2 định dạng)
    final room = _roomDetail!;
    final String roomNumber = (room['SoPhong'] ?? room['RoomNumber'])?.toString() ?? 'Không rõ';
    final String houseName = room['HouseName'] ?? room['TenNha'] ?? 'Nhà trọ';
    final double price = (room['GiaPhong'] ?? room['Price'] ?? 0).toDouble();
    final String address = room['Address'] ?? room['DiaChi'] ?? 'Chưa cập nhật địa chỉ';
    final int maxPeople = room['SoNguoiToiDa'] ?? room['MaxPeople'] ?? 0;
    final int maxVehicles = room['SoLuongXeToiDa'] ?? room['MaxVehicles'] ?? 0;
    final String legalDocuments = room['LegalDocuments'] ?? 'Chưa có thông tin pháp lý';
    
    // 🛠️ ĐÃ THÊM: Lấy mã quản lý (ID chủ trọ) từ API phòng trọ
    final int landlordId = room['MaQL'] != null ? int.tryParse(room['MaQL'].toString()) ?? 2 : 2;

    // Ép kiểu mảng an toàn không lo null cho hình ảnh và thuộc tính tiện ích tiện nghi
    final List<dynamic> imagesList = _parseImagesList(room['DanhSachHinhAnh'] ?? room['Images']); 
    final List<dynamic> attributes = room['DanhSachThuocTinh'] ?? room['Attributes'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // 1. THANH APP BAR HIỂN THỊ HÌNH ẢNH SLIDER
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Slider hiển thị danh sách hình ảnh từ API
                  imagesList.isNotEmpty
                      ? PageView.builder(
                        controller: _pageController,
                        itemCount: imagesList.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                         // Ép kiểu phần tử từ API về dạng chuỗi văn bản thuần (URL String)
                            String rawUrl = imagesList[index].toString().trim();

                            if (rawUrl.isEmpty) {
                              return _buildDetailPlaceholder();
                            }

                            // 🛠️ ĐÃ SỬA: Kiểm tra nếu chỉ là tên file thì thêm tiền tố URL
                            if (!rawUrl.startsWith('http')) {
                              rawUrl = 'http://192.168.1.250/myapi/uploads/$rawUrl';
                            }

                            // Hiển thị trực tiếp ảnh từ URL mạng thông qua Image.network
                            return Image.network(
                              rawUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child; // Ảnh đã tải xong hoàn toàn
                                  
                                  double? finalProgress;
                                  
                                  if (loadingProgress.expectedTotalBytes != null && loadingProgress.expectedTotalBytes! > 0) {
                                    final double computed = loadingProgress.cumulativeBytesLoaded.toDouble() / 
                                                            loadingProgress.expectedTotalBytes!.toDouble();
                                    
                                    if (computed >= 0.0 && computed <= 1.0) {
                                      finalProgress = computed;
                                    } else if (computed > 1.0) {
                                      finalProgress = 1.0;
                                    } else {
                                      finalProgress = 0.0;
                                    }
                                  }

                                  return Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: finalProgress,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                      ),
                                    ),
                                  );
                                },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint("Lỗi tải ảnh slider chi tiết: $error tại link: $rawUrl");
                                return _buildDetailPlaceholder();
                              },                       
                            );
                        },
                      )
                      : _buildDetailPlaceholder(),
                  // Điểm chấm tròn báo vị trí ảnh (Dots Indicator)
                  if (imagesList.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("${_currentImageIndex + 1}/${imagesList.length}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. PHẦN NỘI DUNG CHI TIẾT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên phòng và Tên nhà trọ
                  Text(
                    "Phòng $roomNumber - $houseName",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  // Địa chỉ nhà trọ
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Khối thông tin thông số cơ bản (Số người, số xe)
                  Row(
                    children: [
                      _buildQuickInfoCard(Icons.group_outlined, "Tối đa", "$maxPeople người"),
                      const SizedBox(width: 12),
                      _buildQuickInfoCard(Icons.directions_bike_rounded, "Giới hạn xe", "$maxVehicles xe"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // DANH SÁCH TIỆN ÍCH TIỆN NGHI ĐỘNG (Kết nối từ bảng PhongTro_ThuocTinh)
                  const Text("Tiện ích phòng trọ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  attributes.isNotEmpty
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 3,
                          ),
                          itemCount: attributes.length,
                          itemBuilder: (context, index) {
                            final attr = attributes[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2563EB), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          (attr['TenThuocTinh'] ?? attr['name'] ?? '').toString(),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "${attr['GiaTriThucTe'] ?? attr['value'] ?? ''} ${attr['DonVi'] ?? attr['unit'] ?? ''}".trim(),
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : const Text("Không có tiện ích đặc biệt nào được cập nhật.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  
                  const SizedBox(height: 24),

                  // THÔNG TIN GIẤY TỜ PHÁP LÝ
                  const Text("Giấy tờ pháp lý", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      legalDocuments,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 100), // Khoảng trống cuộn để không bị che khuất bởi Bottom Bar
                ],
              ),
            ),
          ),
        ],
      ),
      
      // 3. THANH ĐẶT PHÒNG / LIÊN HỆ DƯỚI CÙNG
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Giá thuê hằng tháng", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(price), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showLandlordBottomSheet(context, landlordId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text("Liên hệ thuê phòng", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Widget con dùng vẽ nhanh khối tiện ích giới hạn người / xe
  Widget _buildQuickInfoCard(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🛠️ WIDGET CON CHUYÊN TRÁCH TẢI DỮ LIỆU CHỦ TRỌ
// ==========================================
class _LandlordInfoWidget extends StatefulWidget {
  final int landlordId;
  const _LandlordInfoWidget({required this.landlordId});

  @override
  State<_LandlordInfoWidget> createState() => _LandlordInfoWidgetState();
}

class _LandlordInfoWidgetState extends State<_LandlordInfoWidget> {
  bool _loading = true;
  Map<String, dynamic>? _landlordData;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchLandlordInfo();
  }

  Future<void> _fetchLandlordInfo() async {
    try {
      // 🛠️ ĐỒNG BỘ ĐƯỜNG DẪN: Kết nối trực tiếp đến API get_landlord_info.php của bạn trên Laragon
      final url = Uri.parse('http://192.168.1.250/myapi/src/Controllers/GetLandLordInfo.php?id=${widget.landlordId}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _landlordData = data['data'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['message'] ?? 'Không thể lấy thông tin chủ trọ.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể kết nối API chủ trọ: $e';
        _loading = false;
      });
    }
  }

// 🔥 HÀM MỚI: KÍCH HOẠT ỨNG DỤNG EMAIL GỐC TRÊN MÁY
  Future<void> _sendEmail(String email) async {
    final String subject = 'Liên hệ hỏi thuê phòng trọ';
  final String body = 'Xin chào chủ nhà,\nTôi muốn hỏi thuê phòng...'; // \n là xuống dòng
  
  final Uri launchUri = Uri.parse(
    'mailto:${email.trim()}'
    '?subject=${Uri.encodeComponent(subject)}'
    '&body=${Uri.encodeComponent(body)}'
  );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể mở ứng dụng Email cho hòm thư: $email")),
        );
      }
    }
  }

// 🔥 HÀM KÍCH HOẠT ỨNG DỤNG GỌI ĐIỆN GỐC
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll('.', '').trim(), // Xóa dấu chấm nếu có trong chuỗi số đt
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể mở ứng dụng gọi điện cho số: $phoneNumber")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh kéo nhỏ thẩm mỹ phía trên đầu Bottom Sheet
          Container(
            width: 45,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Thông tin liên hệ chủ phòng",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          else if (_error.isNotEmpty || _landlordData == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
            )
          else ...[
            // Vòng tròn Avatar hiển thị chữ cái đầu tiên của Tên Chủ Trọ
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Text(
                _landlordData!['FullName'] != null && _landlordData!['FullName'].isNotEmpty
                    ? _landlordData!['FullName'][0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _landlordData!['FullName'] ?? 'Chưa cập nhật họ tên',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Chủ trọ chính chủ",
                style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),

            // Dòng hiển thị Số điện thoại
            _buildInfoRow(Icons.phone_iphone_rounded, "Số điện thoại chính thức", _landlordData!['PhoneNumber'] ?? 'Chưa cung cấp'),
            const SizedBox(height: 12),

            // Dòng hiển thị Email
            _buildInfoRow(Icons.mail_outline_rounded, "Hòm thư điện tử (Email)", _landlordData!['Email'] ?? 'Chưa cung cấp'),
            const SizedBox(height: 24),

            // Bộ đôi nút nhấn gọi điện / nhắn tin nhanh
           Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // 🛠️ Lấy Email từ API trả về và kích hoạt hàm mở Email
                      final email = _landlordData!['Email'];
                      if (email != null && email.isNotEmpty) {
                        _sendEmail(email); 
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Chủ trọ chưa cập nhật địa chỉ Email")),
                        );
                      }
                    },
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: const Text("Gửi Email liên hệ", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final phone = _landlordData!['PhoneNumber'];
                      if (phone != null && phone.isNotEmpty) {
                        _makePhoneCall(phone);
                      }
                    },
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text("Gọi điện trực tiếp"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailPlaceholder() {
  return Container(
    color: const Color(0xFFF1F5F9), // Màu nền xám nhạt hiện đại
    width: double.infinity,
    height: double.infinity,
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded, 
            size: 48, 
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 8),
          Text(
            "Hình ảnh phòng đang cập nhật",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          )
        ],
      ),
    ),
  );
}
