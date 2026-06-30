import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tenant_model.dart';

class TenantApiService {
  // Đồng bộ IP máy ảo Android nội bộ trùng với file landlord_home_screen.dart của bạn
  static const String baseUrl = 'http://10.0.2.2/myapi/src/Controllers'; 

  static Future<List<TenantModel>> fetchTenants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/GetTenant.php'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> list = data['data'];
          return list.map((json) => TenantModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print("Lỗi fetchTenants: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> addTenant(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/AddTenant.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối máy chủ PHP."};
    }
  }

  static Future<Map<String, dynamic>> updateTenant(Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/UpdateTenant.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối máy chủ PHP."};
    }
  }

  static Future<Map<String, dynamic>> deleteTenant(int khachHangId, int nguoiXoaId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/DeleteTenant.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "KhachHangId": khachHangId,
          "NguoiXoaId": nguoiXoaId,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối máy chủ PHP."};
    }
  }

    // Thêm hàm này vào bên trong class TenantApiService của file lib/data/services/tenant_api_service.dart
  static Future<List<Map<String, dynamic>>> fetchAvailableRooms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/GetAvailableRooms.php'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print("Lỗi fetchAvailableRooms: $e");
      return [];
    }
  }
}