import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TenantUtilityScreen extends StatefulWidget {
  final int userId; // Nhận userId truyền từ KhachHangHomeScreen sang
  const TenantUtilityScreen({super.key, required this.userId});

  @override
  State<TenantUtilityScreen> createState() => _TenantUtilityScreenState();
}

class _TenantUtilityScreenState extends State<TenantUtilityScreen> {
  bool _isLoading = true;
  List<dynamic> _utilities = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUtilities();
  }

  // Hàm kết nối API lấy danh sách chỉ số điện nước từ máy chủ Laragon
  Future<void> _fetchUtilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 10.0.2.2 là địa chỉ IP đặc biệt để máy ảo Android kết nối tới localhost của máy tính
      final url = Uri.parse('http://10.0.2.2/myapi/src/Controllers/GetUtilityIndexController.php?user_id=${widget.userId}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _utilities = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Không thể tải chỉ số điện nước.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối máy chủ Laragon. Vui lòng kiểm tra lại!';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Nền xám nhạt hiện đại
      appBar: AppBar(
        title: const Text(
          "Chỉ số Điện / Nước", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchUtilities,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage, 
                      style: const TextStyle(color: Colors.red), 
                      textAlign: TextAlign.center
                    ),
                  ),
                )
              : _utilities.isEmpty
                  ? const Center(child: Text("Chưa có lịch sử chốt chỉ số điện nước."))
                  : RefreshIndicator(
                      onRefresh: _fetchUtilities,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _utilities.length,
                        itemBuilder: (context, index) {
                          final item = _utilities[index];
                          // Phân loại dựa trên ServiceId (1: Điện, 2: Nước) từ API
                          final bool isElectricity = item['ServiceId'] == 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hàng tiêu đề card: Icon + Tên dịch vụ + Lượng tiêu thụ
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isElectricity 
                                              ? Colors.amber.withOpacity(0.1) 
                                              : Colors.blue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isElectricity 
                                              ? Icons.bolt_rounded 
                                              : Icons.water_drop_rounded,
                                          color: isElectricity 
                                              ? Colors.amber.shade700 
                                              : Colors.blue.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isElectricity ? "Chỉ số Điện" : "Chỉ số Nước",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                fontSize: 16, 
                                                color: Color(0xFF1E293B)
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Kỳ hóa đơn: ${item['Period']}", 
                                              style: const TextStyle(color: Colors.grey, fontSize: 12)
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Khối hiển thị số lượng tiêu thụ thực tế
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${item['Consumption']} ${isElectricity ? 'kWh' : 'm³'}",
                                          style: const TextStyle(
                                            fontSize: 13, 
                                            fontWeight: FontWeight.bold, 
                                            color: Color(0xFF1E293B)
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
                                  ),
                                  
                                  // Hàng hiển thị: Số cũ -> Số mới
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Chỉ số đầu kỳ (Cũ)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${item['OldIndex']}", 
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569))
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 18),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text("Chỉ số cuối kỳ (Mới)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${item['NewIndex']}", 
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  // Hiển thị vị trí phòng trọ nhỏ bên dưới
                                  Text(
                                    "${item['HouseName']} - Phòng ${item['RoomNumber']}",
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}