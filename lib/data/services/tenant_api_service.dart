import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tenant_model.dart';

class TenantApiService {
  // Đồng bộ IP máy ảo Android nội bộ trùng với file landlord_home_screen.dart của bạn
  static const String baseUrl = 'http://192.168.1.250/myapi/src/Controllers';

  static Future<List<TenantModel>> fetchTenants({int? houseId, int? landlordId}) async {
    try {
      String url = '$baseUrl/GetTenant.php?';
      if (houseId != null) url += 'house_id=$houseId&';
      if (landlordId != null) url += 'landlord_id=$landlordId&';
      
      final response = await http.get(Uri.parse(url));
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
        headers: {
          'Content-Type': 'application/json',
          'X-Caller-Id': nguoiXoaId.toString(), // 🟢 ĐÍNH KÈM ID NGƯỜI XÓA VÀO HEADER
        },
        body: json.encode({
          "KhachHangId": khachHangId,
          "NguoiXoaId": nguoiXoaId,
        }),
      );
      final data = json.decode(response.body);
      return response.statusCode == 200 ? data : {"status": "error", "message": "Lỗi từ máy chủ PHP."};
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối máy chủ PHP."};
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAvailableRooms({int? houseId, int? landlordId}) async {
    try {
      String url = '$baseUrl/GetAvailableRooms.php?';
      if (houseId != null) url += 'house_id=$houseId&';
      if (landlordId != null) url += 'landlord_id=$landlordId&';

      final response = await http.get(Uri.parse(url));
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