import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../data/models/admin_revenue_model.dart';
import '../../data/models/house_model.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart'; // Để dùng Clipboard

class AdminRevenueStatisticsScreen extends StatefulWidget {
  final int adminId;
  const AdminRevenueStatisticsScreen({super.key, required this.adminId});

  @override
  State<AdminRevenueStatisticsScreen> createState() => _AdminRevenueStatisticsScreenState();
}

class _AdminRevenueStatisticsScreenState extends State<AdminRevenueStatisticsScreen> {
  bool _isLoading = true;
  AdminRevenueModel? _revenueData;
  List<HouseModel> _houses = [];
  int? _selectedHouseId; // null = Tất cả nhà trọ
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isYearlyMode = false;

  final List<int> _years = List.generate(5, (index) => DateTime.now().year - index);
  final List<String> _months = [
    "Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6",
    "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchHouses();
    await _fetchStatistics();
  }

  Future<void> _fetchHouses() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/Admin/GetHouses.php?user_id=${widget.adminId}'),
        headers: {"X-User-Id": widget.adminId.toString()},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List list = data['data'] ?? [];
          setState(() {
            _houses = list.map((e) => HouseModel.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      print("Lỗi tải danh sách nhà: $e");
    }
  }

  Future<void> _fetchStatistics() async {
    setState(() => _isLoading = true);
    try {
      String url = 'http://192.168.1.250/myapi/src/Controllers/Admin/RevenueStatistics.php?nam=$_selectedYear';
      if (!_isYearlyMode) {
        url += '&thang=$_selectedMonth';
      }
      if (_selectedHouseId != null) {
        url += '&house_id=$_selectedHouseId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {"X-User-Id": widget.adminId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _revenueData = AdminRevenueModel.fromJson(data);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Lỗi server: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportToExcel() async {
    if (_revenueData == null) return;

    // 1. Khởi tạo Workbook
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // 2. Tiêu đề cột
    sheet.getRangeByName('A1').setText('Nhà Trọ');
    sheet.getRangeByName('B1').setText('Tiền Nhà');
    sheet.getRangeByName('C1').setText('Tiền Dịch Vụ');
    sheet.getRangeByName('D1').setText('Tiền Cọc');
    sheet.getRangeByName('E1').setText('Tổng Doanh Thu');
    sheet.getRangeByName('A1:E1').cellStyle.bold = true;

    // 3. Điền dữ liệu
    int rowIndex = 2;
    for (var house in _revenueData!.data.chiTietTheoNhaTro) {
      sheet.getRangeByIndex(rowIndex, 1).setText(house.tenNha);
      sheet.getRangeByIndex(rowIndex, 2).setNumber(house.tienNha);
      sheet.getRangeByIndex(rowIndex, 3).setNumber(house.tienDichVu);
      sheet.getRangeByIndex(rowIndex, 4).setNumber(house.tienCoc);
      sheet.getRangeByIndex(rowIndex, 5).setNumber(house.tongDoanhThu);
      sheet.getRangeByIndex(rowIndex, 2, rowIndex, 5).numberFormat = '#,##0 "đ"';
      rowIndex++;
    }

    // 4. Lưu file
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final String fileName = 'DoanhThu_${_selectedMonth}_${_selectedYear}.xlsx';
    
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        // Trỏ trực tiếp đến thư mục Download chung của máy
        directory = Directory('/storage/emulated/0/Download');
        // Nếu thư mục Download không tồn tại (hiếm gặp), lùi về thư mục dữ liệu app
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final String path = '${directory.path}/$fileName';
        final File file = File(path);
        await file.writeAsBytes(bytes, flush: true);

        // HIỂN THỊ DIALOG THÔNG BÁO THÀNH CÔNG
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text("Lưu thành công"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Báo cáo đã được lưu vào thư mục Tải về (Download) của máy."),
                  const SizedBox(height: 12),
                  const Text("Tên file:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(fileName, style: const TextStyle(fontSize: 13, color: Colors.blue)),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  child: const Text("ĐỒNG Ý", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Thống kê doanh thu"),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _exportToExcel,
            tooltip: 'Xuất Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _revenueData == null 
                ? const Center(child: Text("Không có dữ liệu"))
                : RefreshIndicator(
                    onRefresh: _fetchStatistics,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          if (!_isYearlyMode && _revenueData!.data.soSanhThangTruoc != null)
                            _buildComparisonCard(),
                          const SizedBox(height: 24),
                          _buildHouseDetailsList(),
                          if (_isYearlyMode && _revenueData!.data.chiTietTheoThang != null) ...[
                            const SizedBox(height: 24),
                            _buildMonthlyDetailsList(),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF10B981),
      child: Column(
        children: [
          // Dòng 1: Chọn Nhà trọ
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedHouseId,
                hint: const Text("Tất cả nhà trọ"),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text("Tất cả nhà trọ")),
                  ..._houses.map((h) => DropdownMenuItem<int?>(value: h.id, child: Text(h.tenNha))),
                ],
                onChanged: (val) {
                  setState(() => _selectedHouseId = val);
                  _fetchStatistics();
                },
              ),
            ),
          ),
          // Dòng 2: Năm và Tháng
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      items: _years.map((y) => DropdownMenuItem(value: y, child: Text("Năm $y"))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                          _fetchStatistics();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _isYearlyMode ? null : _selectedMonth,
                      hint: const Text("Cả năm"),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text("Cả năm")),
                        ...List.generate(12, (i) => DropdownMenuItem<int?>(value: i + 1, child: Text(_months[i]))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          if (val == null) {
                            _isYearlyMode = true;
                          } else {
                            _isYearlyMode = false;
                            _selectedMonth = val;
                          }
                        });
                        _fetchStatistics();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final stats = _revenueData!.data.tongQuan;
    return Column(
      children: [
        _buildMainStatCard("TỔNG DOANH THU", stats.tongDoanhThu, const Color(0xFF10B981)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSmallStatCard("Tiền Nhà", stats.tongTienNha, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildSmallStatCard("Dịch Vụ", stats.tongTienDichVu, Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        _buildSmallStatCard("Tiền Cọc", stats.tongTienCoc, Colors.purple),
        if (_isYearlyMode && stats.trungBinhThang != null) ...[
          const SizedBox(height: 12),
          _buildSmallStatCard("Trung bình/tháng", stats.trungBinhThang!, Colors.blueGrey),
        ]
      ],
    );
  }

  Widget _buildMainStatCard(String title, double amount, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_formatCurrency(amount), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_formatCurrency(amount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    final comp = _revenueData!.data.soSanhThangTruoc!;
    final bool isIncrease = comp.chenhLech >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(isIncrease ? Icons.trending_up : Icons.trending_down, color: isIncrease ? Colors.green : Colors.red, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "So với tháng ${comp.thangSoSanh}/${comp.namSoSanh}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  "${isIncrease ? "Tăng" : "Giảm"} ${comp.tiLeTangGiam} (${_formatCurrency(comp.chenhLech.abs())})",
                  style: TextStyle(fontWeight: FontWeight.bold, color: isIncrease ? Colors.green : Colors.red),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHouseDetailsList() {
    final list = _revenueData!.data.chiTietTheoNhaTro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CHI TIẾT THEO NHÀ TRỌ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 12),
        ...list.map((h) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(h.tenNha, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniInfo("Tiền nhà", h.tienNha),
                  _buildMiniInfo("Dịch vụ", h.tienDichVu),
                  _buildMiniInfo("Cọc", h.tienCoc),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tổng doanh thu", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_formatCurrency(h.tongDoanhThu), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              )
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMonthlyDetailsList() {
    final list = _revenueData!.data.chiTietTheoThang!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DOANH THU THEO THÁNG", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Tháng")),
                DataColumn(label: Text("Tổng doanh thu")),
                DataColumn(label: Text("Tiền nhà")),
              ],
              rows: list.map((m) => DataRow(cells: [
                DataCell(Text("Tháng ${m.thang}")),
                DataCell(Text(_formatCurrency(m.tongDoanhThu))),
                DataCell(Text(_formatCurrency(m.tienNha))),
              ])).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(_formatCurrency(amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
