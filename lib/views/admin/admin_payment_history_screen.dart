import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPaymentHistoryScreen extends StatefulWidget {
  final int landlordId;
  const AdminPaymentHistoryScreen({super.key, required this.landlordId});

  @override
  State<AdminPaymentHistoryScreen> createState() => _AdminPaymentHistoryScreenState();
}

class _AdminPaymentHistoryScreenState extends State<AdminPaymentHistoryScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;
  
  final String _apiUrl = "http://10.0.2.2/myapi/src/Controllers/GetPaymentHistoryLandlord.php";

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$_apiUrl?landlord_id=${widget.landlordId}"));
      
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
      setState(() => _isLoading = false);
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
      body: _isLoading
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
                            Text("Phòng ${payment['room_number']} - ${payment['house_name']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
    );
  }
}
