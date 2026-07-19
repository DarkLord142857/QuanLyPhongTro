import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPaymentHistoryScreen extends StatefulWidget {
  final int landlordId;
  final int? houseId; // Thêm houseId để lọc
  const AdminPaymentHistoryScreen({super.key, required this.landlordId, this.houseId});

  @override
  State<AdminPaymentHistoryScreen> createState() => _AdminPaymentHistoryScreenState();
}

class _AdminPaymentHistoryScreenState extends State<AdminPaymentHistoryScreen> {
  List<dynamic> _payments = [];
  List<dynamic> _houses = []; // Danh sách nhà trọ
  int? _selectedHouseId; // Nhà trọ đang chọn
  bool _isLoading = true;
  
  final String _apiUrl = "http://192.168.1.250/myapi/src/Controllers/GetPaymentHistoryLandlord.php";
  final String _baseBaseUrl = "http://192.168.1.250/myapi/src/Controllers";

  @override
  void initState() {
    super.initState();
    _selectedHouseId = widget.houseId;
    _fetchHouses();
    _fetchPaymentHistory();
  }

  Future<void> _fetchHouses() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseBaseUrl/Admin/GetHouses.php?user_id=${widget.landlordId}"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _houses = data['data'];
          });
        }
      }
    } catch (e) {
      print("Error fetching houses: $e");
    }
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      String url = "$_apiUrl?landlord_id=${widget.landlordId}";
      if (_selectedHouseId != null) {
        url += "&house_id=$_selectedHouseId";
      }
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _payments = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _payments = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    int value = amount.toInt();
    if (value == 0) return "0 đ";
    
    String result = "";
    while (value > 0) {
      int remainder = value % 1000;
      value = value ~/ 1000;
      if (value > 0) {
        result = ".${remainder.toString().padLeft(3, '0')}$result";
      } else {
        result = "$remainder$result";
      }
    }
    return "$result đ";
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử Thanh toán (Admin)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHouseFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : _payments.isEmpty
                    ? const Center(child: Text("Chưa có giao dịch nào."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                              "Phòng ${payment['room_number']} - ${payment['house_name']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                                  Text("Khách: ${payment['customer_name']}"),
                                  Text("Kỳ: ${payment['period']} - Ngày: ${payment['payment_date']}"),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Hóa đơn: ${_formatCurrency(double.tryParse(payment['total_invoice_amount'].toString()) ?? 0.0)}"),
                                      Text("+ ${_formatCurrency(double.tryParse(payment['amount_paid'].toString()) ?? 0.0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
              selectedColor: Colors.blue,
              onSelected: (bool selected) {
                setState(() {
                  _selectedHouseId = houseId;
                });
                _fetchPaymentHistory();
              },
            ),
          );
        },
      ),
    );
  }
}
