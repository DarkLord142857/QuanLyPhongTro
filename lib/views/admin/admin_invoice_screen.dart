import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../khach_hang/tenant_invoice_detail_screen.dart';

class AdminInvoiceScreen extends StatefulWidget {
  final int landlordId;
  final int? houseId; // Thêm houseId để lọc
  const AdminInvoiceScreen({super.key, required this.landlordId, this.houseId});

  @override
  State<AdminInvoiceScreen> createState() => _AdminInvoiceScreenState();
}

class _AdminInvoiceScreenState extends State<AdminInvoiceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allInvoices = [];
  List<dynamic> _houses = []; // Danh sách nhà trọ
  int? _selectedHouseId; // Nhà trọ đang chọn
  bool _isLoading = true;
  final String _baseUrl = "http://192.168.1.250/myapi/src/Controllers";
  final Color primaryColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _selectedHouseId = widget.houseId;
    _fetchHouses();
    _fetchInvoices();
  }

  Future<void> _fetchHouses() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/GetHouses.php?user_id=${widget.landlordId}"),
      ).timeout(const Duration(seconds: 10));
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return "0 đ";
    final double value = double.tryParse(amount.toString()) ?? 0.0;
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(value);
  }

  Future<void> _fetchInvoices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      String invoiceUrl = "$_baseUrl/GetLandlordInvoices.php?user_id=${widget.landlordId}";
      if (_selectedHouseId != null) invoiceUrl += "&house_id=$_selectedHouseId";
      
      String utilityUrl = "$_baseUrl/GetLandlordUtilityIndex.php?landlord_id=${widget.landlordId}";
      if (_selectedHouseId != null) utilityUrl += "&house_id=$_selectedHouseId";

      // 🔥 CHẠY SONG SONG & THÊM TIMEOUT 10 GIÂY ĐỂ TRÁNH ĐƠ APP
      final responses = await Future.wait([
        http.get(
          Uri.parse(invoiceUrl),
          headers: {"X-User-Id": widget.landlordId.toString()},
        ).timeout(const Duration(seconds: 10)),
        http.get(
          Uri.parse(utilityUrl),
          headers: {"X-User-Id": widget.landlordId.toString()},
        ).timeout(const Duration(seconds: 10)).catchError((_) => http.Response('{"status":"error","data":[]}', 200)),
      ]);

      final invoiceRes = responses[0];
      final utilityRes = responses[1];

      if (invoiceRes.statusCode == 200) {
        final invoiceData = json.decode(invoiceRes.body);

        if (invoiceData['status'] == 'success') {
          List<dynamic> invoices = List.from(invoiceData['data']);
          
          Map<String, dynamic> uMap = {};
          if (utilityRes.statusCode == 200) {
             final utilityData = json.decode(utilityRes.body);
             if (utilityData['status'] == 'success') {
                for (var u in utilityData['data']) {
                  uMap["${u['HoaDonId']}_${u['ServiceId']}"] = u;
                }
             }
          }

          for (var inv in invoices) {
            final String hId = inv['InvoiceId'].toString();
            final e = uMap["${hId}_1"];
            final w = uMap["${hId}_2"];
            
            inv['ElectricOld'] = e != null ? e['OldIndex'] : 0;
            inv['ElectricNew'] = e != null ? e['NewIndex'] : 0;
            inv['WaterOld'] = w != null ? w['OldIndex'] : 0;
            inv['WaterNew'] = w != null ? w['NewIndex'] : 0;
          }

          if (mounted) setState(() => _allInvoices = invoices);
        }
      }
    } on SocketException {
      _showSnackBar("Không thể kết nối máy chủ Laragon!", Colors.red);
    } on TimeoutException {
      _showSnackBar("Kết nối quá hạn (10s). Server phản hồi chậm!", Colors.orange);
    } catch (e) {
      _showSnackBar("Lỗi xử lý dữ liệu hóa đơn", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredInvoices(String status) {
    List<dynamic> filtered = _allInvoices.where((inv) {
      final String invoiceStatus = (inv['TrangThaiThanhToan'] ?? inv['Status'] ?? inv['TrangThai'] ?? '').toString().toLowerCase();
      return invoiceStatus == status;
    }).toList();

    if (status == 'dathanhtoan') {
      filtered.sort((a, b) => (b['CreatedDate'] ?? '').compareTo(a['CreatedDate'] ?? ''));
    } else {
      filtered.sort((a, b) => (a['CreatedDate'] ?? '').compareTo(b['CreatedDate'] ?? ''));
    }
    return filtered;
  }

  Future<void> _updatePaymentStatus(int hoaDonId, String status) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/UpdatePaymentStatus.php"),
        headers: {"Content-Type": "application/json", "X-User-Id": widget.landlordId.toString()},
        body: json.encode({"hoa_don_id": hoaDonId, "trang_thai": status, "ghi_chu": "Admin cập nhật trạng thái"}),
      );
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        _showSnackBar(data['message'], Colors.green);
        _fetchInvoices();
      } else {
        _showSnackBar(data['message'], Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống", Colors.red);
    }
  }

  Future<void> _updateInvoice(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/UpdateInvoice.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );
      final resData = json.decode(response.body);
      if (resData['status'] == 'success') {
        _showSnackBar(resData['message'], Colors.green);
        _fetchInvoices();
      } else {
        _showSnackBar(resData['message'], Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống khi cập nhật", Colors.red);
    }
  }

  Future<void> _deleteInvoice(int invoiceId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận xóa hóa đơn", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc chắn muốn xóa hóa đơn này khỏi hệ thống?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Xác nhận xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/DeleteInvoice.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"hoa_don_id": invoiceId, "nguoi_xoa_id": widget.landlordId}),
      );
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        _showSnackBar(data['message'], primaryColor);
        _fetchInvoices();
      } else {
        _showSnackBar(data['message'], Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống", Colors.red);
    }
  }

  void _showEditInvoiceDialog(dynamic item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final url = Uri.parse('$_baseUrl/GetInvoiceDetail.php?InvoiceId=${item['InvoiceId']}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success') {
          final detail = resData['data'];
          final services = detail['DanhSachDichVu'] as List;

          final dien = services.firstWhere((s) => s['TenDichVu'].toString().contains('Điện'), orElse: () => null);
          final nuoc = services.firstWhere((s) => s['TenDichVu'].toString().contains('Nước'), orElse: () => null);
          final internet = services.firstWhere((s) => s['TenDichVu'].toString().contains('Internet'), orElse: () => null);

          final roomPriceCtrl = TextEditingController(text: (item['TienPhong'] ?? item['RoomPrice'] ?? item['GiaPhong'] ?? 0).toString());
          final dienCuCtrl = TextEditingController(text: (dien != null ? dien['ChiSoCu'] : item['ElectricOld'] ?? 0).toString());
          final dienMoiCtrl = TextEditingController(text: (dien != null ? dien['ChiSoMoi'] : item['ElectricNew'] ?? 0).toString());
          final dienDonGiaCtrl = TextEditingController(text: (dien != null ? dien['DonGia'] : 3500).toString());
          
          final nuocCuCtrl = TextEditingController(text: (nuoc != null ? nuoc['ChiSoCu'] : item['WaterOld'] ?? 0).toString());
          final nuocMoiCtrl = TextEditingController(text: (nuoc != null ? nuoc['ChiSoMoi'] : item['WaterNew'] ?? 0).toString());
          final nuocDonGiaCtrl = TextEditingController(text: (nuoc != null ? nuoc['DonGia'] : 15000).toString());
          
          final internetCtrl = TextEditingController(text: (internet != null ? internet['DonGia'] : 100000).toString());

          if (!mounted) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Chỉnh sửa hóa đơn (Admin)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextField(controller: roomPriceCtrl, decoration: const InputDecoration(labelText: "Tiền phòng", prefixIcon: Icon(Icons.home)), keyboardType: TextInputType.number),
                    const Divider(height: 30),
                    const Text("Chỉ số Điện", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: dienCuCtrl, decoration: const InputDecoration(labelText: "Số cũ"), keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: dienMoiCtrl, decoration: const InputDecoration(labelText: "Số mới"), keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: dienDonGiaCtrl, decoration: const InputDecoration(labelText: "Đơn giá"), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text("Chỉ số Nước", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: nuocCuCtrl, decoration: const InputDecoration(labelText: "Số cũ"), keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: nuocMoiCtrl, decoration: const InputDecoration(labelText: "Số mới"), keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: nuocDonGiaCtrl, decoration: const InputDecoration(labelText: "Đơn giá"), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(controller: internetCtrl, decoration: const InputDecoration(labelText: "Phí dịch vụ khác", prefixIcon: Icon(Icons.miscellaneous_services)), keyboardType: TextInputType.number),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: () {
                          Map<String, dynamic> updateData = {
                            "hoa_don_id": item['InvoiceId'],
                            "tien_phong": double.tryParse(roomPriceCtrl.text) ?? 0,
                            "dien": {
                              "cu": double.tryParse(dienCuCtrl.text) ?? 0,
                              "moi": double.tryParse(dienMoiCtrl.text) ?? 0,
                              "don_gia": double.tryParse(dienDonGiaCtrl.text) ?? 0
                            },
                            "nuoc": {
                              "cu": double.tryParse(nuocCuCtrl.text) ?? 0,
                              "moi": double.tryParse(nuocMoiCtrl.text) ?? 0,
                              "don_gia": double.tryParse(nuocDonGiaCtrl.text) ?? 0
                            },
                            "internet": double.tryParse(internetCtrl.text) ?? 0
                          };
                          Navigator.pop(ctx);
                          _updateInvoice(updateData);
                        },
                        child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Lỗi khi tải thông tin", Colors.red);
    }
  }

  Future<void> _createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/CreateInvoice.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );
      final resData = json.decode(response.body);
      if (resData['status'] == 'success') {
        _showSnackBar(resData['message'], Colors.green);
        _fetchInvoices();
      } else {
        _showSnackBar(resData['message'], Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống khi tạo hóa đơn", Colors.red);
    }
  }

  void _showAddInvoiceDialog() async {
    int? currentHouseId = _selectedHouseId;
    List<dynamic> rooms = [];
    bool isFetchingRooms = false;

    // Hàm phụ để tải danh sách phòng
    Future<void> fetchRoomsForHouse(int houseId, StateSetter setModalState) async {
      setModalState(() => isFetchingRooms = true);
      try {
        final response = await http.get(Uri.parse("$_baseUrl/GetRoom.php?house_id=$houseId"));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            setModalState(() {
              rooms = data['data'];
              isFetchingRooms = false;
            });
          }
        }
      } catch (e) {
        setModalState(() => isFetchingRooms = false);
      }
    }

    // Nếu đã chọn nhà từ trước, tải phòng luôn
    if (currentHouseId != null) {
      showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
      try {
        final res = await http.get(Uri.parse("$_baseUrl/GetRoom.php?house_id=$currentHouseId"));
        Navigator.pop(context);
        final data = json.decode(res.body);
        if (data['status'] == 'success') rooms = data['data'];
      } catch (_) { 
        if(mounted) Navigator.pop(context); 
      }
    }

    int? selectedRoomId;
    if (rooms.isNotEmpty) selectedRoomId = int.tryParse(rooms[0]['Id'].toString());
    
    final periodCtrl = TextEditingController(text: DateFormat('MM/yyyy').format(DateTime.now()));
    final roomPriceCtrl = TextEditingController();
    if (rooms.isNotEmpty) roomPriceCtrl.text = rooms[0]['GiaPhong'].toString();
    
    final dienCuCtrl = TextEditingController(text: "0");
    final dienMoiCtrl = TextEditingController(text: "0");
    final dienDonGiaCtrl = TextEditingController(text: "3500");
    final nuocCuCtrl = TextEditingController(text: "0");
    final nuocMoiCtrl = TextEditingController(text: "0");
    final nuocDonGiaCtrl = TextEditingController(text: "15000");
    final internetCtrl = TextEditingController(text: "100000");

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Thêm hóa đơn mới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                // Ô CHỌN NHÀ TRỌ
                DropdownButtonFormField<int>(
                  value: currentHouseId,
                  decoration: const InputDecoration(labelText: "Chọn nhà trọ", prefixIcon: Icon(Icons.business_rounded)),
                  items: _houses.map((h) => DropdownMenuItem<int>(
                    value: int.tryParse(h['Id'].toString()),
                    child: Text(h['TenNha']),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        currentHouseId = val;
                        selectedRoomId = null;
                        rooms = [];
                      });
                      fetchRoomsForHouse(val, setModalState);
                    }
                  },
                ),
                const SizedBox(height: 10),
                // Ô CHỌN PHÒNG
                isFetchingRooms 
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()))
                  : DropdownButtonFormField<int>(
                      value: selectedRoomId,
                      decoration: const InputDecoration(labelText: "Chọn phòng", prefixIcon: Icon(Icons.meeting_room)),
                      items: rooms.map((r) {
                        final id = int.tryParse(r['Id'].toString());
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text("Phòng ${r['SoPhong']}"),
                        );
                      }).where((item) => item.value != null).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedRoomId = val;
                          final selectedRoom = rooms.firstWhere((r) => int.tryParse(r['Id'].toString()) == val);
                          roomPriceCtrl.text = selectedRoom['GiaPhong'].toString();
                        });
                      },
                    ),
                const SizedBox(height: 10),
                TextField(controller: periodCtrl, decoration: const InputDecoration(labelText: "Kỳ hóa đơn (MM/YYYY)", prefixIcon: Icon(Icons.calendar_today))),
                TextField(controller: roomPriceCtrl, decoration: const InputDecoration(labelText: "Tiền phòng", prefixIcon: Icon(Icons.home)), keyboardType: TextInputType.number),
                const Divider(height: 30),
                const Text("Chỉ số Điện", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Row(
                  children: [
                    Expanded(child: TextField(controller: dienCuCtrl, decoration: const InputDecoration(labelText: "Số cũ"), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: dienMoiCtrl, decoration: const InputDecoration(labelText: "Số mới"), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: dienDonGiaCtrl, decoration: const InputDecoration(labelText: "Đơn giá"), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 15),
                const Text("Chỉ số Nước", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
                Row(
                  children: [
                    Expanded(child: TextField(controller: nuocCuCtrl, decoration: const InputDecoration(labelText: "Số cũ"), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: nuocMoiCtrl, decoration: const InputDecoration(labelText: "Số mới"), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: nuocDonGiaCtrl, decoration: const InputDecoration(labelText: "Đơn giá"), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(controller: internetCtrl, decoration: const InputDecoration(labelText: "Dịch vụ khác", prefixIcon: Icon(Icons.wifi)), keyboardType: TextInputType.number),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () {
                      if (selectedRoomId == null) return;
                      Map<String, dynamic> createData = {
                        "nguoi_lap_id": widget.landlordId,
                        "phong_tro_id": selectedRoomId,
                        "ky_hoa_don": periodCtrl.text,
                        "tien_phong": double.tryParse(roomPriceCtrl.text) ?? 0,
                        "dien": {
                          "cu": double.tryParse(dienCuCtrl.text) ?? 0,
                          "moi": double.tryParse(dienMoiCtrl.text) ?? 0,
                          "don_gia": double.tryParse(dienDonGiaCtrl.text) ?? 0
                        },
                        "nuoc": {
                          "cu": double.tryParse(nuocCuCtrl.text) ?? 0,
                          "moi": double.tryParse(nuocMoiCtrl.text) ?? 0,
                          "don_gia": double.tryParse(nuocDonGiaCtrl.text) ?? 0
                        },
                        "internet": double.tryParse(internetCtrl.text) ?? 0
                      };
                      Navigator.pop(ctx);
                      _createInvoice(createData);
                    },
                    child: const Text("Tạo hóa đơn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Ẩn thông báo cũ trước khi hiện mới
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: color, 
        behavior: SnackBarBehavior.fixed, // Chuyển sang fixed để tránh lỗi layout
        duration: const Duration(seconds: 3),
      )
    );
  }

  void _showStatusUpdateDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cập nhật thanh toán", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(item['InvoiceId'], 'chuathanhtoan', 'Chưa thanh toán', Colors.orange),
            _buildStatusOption(item['InvoiceId'], 'choduyet', 'Chờ duyệt', Colors.blue),
            _buildStatusOption(item['InvoiceId'], 'thanhtoanmotphan', 'Thanh toán một phần', Colors.purple),
            _buildStatusOption(item['InvoiceId'], 'dathanhtoan', 'Đã thanh toán', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(int id, String status, String label, Color color) {
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 16),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        _updatePaymentStatus(id, status);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Hóa Đơn Hệ Thống", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false, // Hiển thị 4 tab gọn trong màn hình
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Chờ duyệt"),
            Tab(text: "Chưa đóng"),
            Tab(text: "Một phần"),
            Tab(text: "Đã đóng"),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_tabController.index == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                heroTag: "add_invoice",
                backgroundColor: primaryColor,
                onPressed: _showAddInvoiceDialog,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          FloatingActionButton(
            heroTag: "refresh_invoices",
            backgroundColor: Colors.white,
            onPressed: () => _fetchInvoices(),
            child: Icon(Icons.refresh_rounded, color: primaryColor),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHouseFilter(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInvoiceList('choduyet'),
                      _buildInvoiceList('chuathanhtoan'),
                      _buildInvoiceList('thanhtoanmotphan'),
                      _buildInvoiceList('dathanhtoan'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseFilter() {
    if (_houses.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _houses.length + 1,
        itemBuilder: (context, index) {
          final bool isAll = index == 0;
          final dynamic house = isAll ? null : _houses[index - 1];
          final int? houseId = isAll ? null : int.tryParse(house['Id'].toString());
          final String houseName = isAll ? "Tất cả nhà" : house['TenNha'];
          final bool isSelected = _selectedHouseId == houseId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(houseName, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              backgroundColor: Colors.white,
              selectedColor: primaryColor,
              onSelected: (bool selected) {
                setState(() {
                  _selectedHouseId = houseId;
                });
                _fetchInvoices();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceList(String status) {
    final filtered = _getFilteredInvoices(status);
    if (filtered.isEmpty) {
      return const Center(child: Text("Không có hóa đơn nào trong mục này."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildInvoiceCard(item);
      },
    );
  }

  Widget _buildInvoiceCard(dynamic item) {
    final String status = (item['TrangThaiThanhToan'] ?? item['Status'] ?? item['TrangThai'] ?? '').toString().toLowerCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TenantInvoiceDetailScreen(invoiceId: item['InvoiceId']))),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.receipt_long_rounded, color: _getStatusColor(status), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Phòng ${item['RoomNumber']} - ${item['TenNha'] ?? item['HouseName'] ?? 'Hệ thống'}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text("Kỳ: ${item['Period']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                ],
              ),
              const Divider(height: 24, thickness: 0.8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildQuickStat(Icons.home_outlined, "Tiền phòng", _formatCurrency(item['TienPhong'] ?? item['RoomPrice'] ?? item['GiaPhong'] ?? 0))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildQuickStat(Icons.bolt_rounded, "Điện", "${item['ElectricOld'] ?? 0}➔${item['ElectricNew'] ?? 0}")),
                  const SizedBox(width: 4),
                  Expanded(child: _buildQuickStat(Icons.water_drop_rounded, "Nước", "${item['WaterOld'] ?? 0}➔${item['WaterNew'] ?? 0}")),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTotalInfo("Tổng hóa đơn", _formatCurrency(item['TotalPrice']), const Color(0xFF0F172A)),
                    _buildTotalInfo("Còn nợ", _formatCurrency(item['Debt']), Colors.redAccent, crossAxisAlignment: CrossAxisAlignment.end),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("Khách: ${item['CustomerName'] ?? 'Ẩn danh'}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
                  Row(
                    children: [
                      if (status == 'choduyet') ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                          onPressed: () => _showEditInvoiceDialog(item),
                          tooltip: "Sửa hóa đơn",
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteInvoice(item['InvoiceId']),
                          tooltip: "Xóa hóa đơn",
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        onPressed: () => _showStatusUpdateDialog(item),
                        tooltip: "Duyệt thanh toán",
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'dathanhtoan': return Colors.green;
      case 'thanhtoanmotphan': return Colors.purple;
      case 'choduyet': return Colors.blue;
      case 'chuathanhtoan': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    String text = "Chưa đóng"; 
    Color color = Colors.orange;
    if (status == 'dathanhtoan') { text = "Đã đóng"; color = Colors.green; }
    else if (status == 'thanhtoanmotphan') { text = "Một phần"; color = Colors.purple; }
    else if (status == 'choduyet') { text = "Chờ duyệt"; color = Colors.blue; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuickStat(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      ],
    );
  }

  Widget _buildTotalInfo(String label, String value, Color valueColor, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: valueColor)),
      ],
    );
  }
}
