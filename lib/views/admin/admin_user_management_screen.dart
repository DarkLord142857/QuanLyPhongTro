import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/user_admin_model.dart';
import 'package:intl/intl.dart';

class AdminUserManagementScreen extends StatefulWidget {
  final int adminId;
  const AdminUserManagementScreen({super.key, required this.adminId});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserAdminModel> _allUsers = [];
  bool _isLoading = true;
  String _adminName = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAdminInfo();
    _fetchUsers();
  }

  Future<void> _fetchAdminInfo() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/GetLandlordInfo.php?id=${widget.adminId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _adminName = data['data']['FullName'] ?? "Admin";
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/Admin/get_users.php'),
        headers: {
          "X-User-Id": widget.adminId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List list = data['data'];
          setState(() {
            _allUsers = list.map((e) => UserAdminModel.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackBar("Lỗi tải danh sách: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Lỗi kết nối: $e", Colors.red);
    }
  }

  Future<void> _updateStatus(int targetId, String targetName, String action) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.250/myapi/src/Controllers/Admin/update_user_status.php'),
        headers: {
          "Content-Type": "application/json",
          "X-User-Id": widget.adminId.toString(),
        },
        body: json.encode({
          "id": targetId,
          "action": action,
          "adminId": widget.adminId,
          "adminName": _adminName,
          "targetName": targetName
        }),
      );

      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        _showSnackBar(res['message'], Colors.green);
        _fetchUsers();
      } else {
        _showSnackBar(res['message'] ?? "Thao tác thất bại", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối server", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý tài khoản"),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Tất cả"),
            Tab(text: "Chờ duyệt"),
            Tab(text: "Đã khóa"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_allUsers),
                _buildUserList(_allUsers.where((u) => u.isApproved == 0 && u.isDeleted == 0).toList()),
                _buildUserList(_allUsers.where((u) => u.isDeleted == 1).toList()),
              ],
            ),
    );
  }

  Widget _buildUserList(List<UserAdminModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text("Không có người dùng nào."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
              child: Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role)),
            ),
            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${user.role} • ${user.username}"),
            trailing: _buildStatusBadge(user),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.phone, "Số điện thoại:", user.phoneNumber ?? "N/A"),
                    _buildInfoRow(Icons.email, "Email:", user.email ?? "N/A"),
                    _buildInfoRow(Icons.badge, "CCCD:", user.identityCard ?? "N/A"),
                    _buildInfoRow(Icons.calendar_today, "Ngày tạo:", user.createdDate),
                    const Divider(),
                    const Text("Hành động quản trị:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (user.isApproved == 0 && user.isDeleted == 0)
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(user.id, user.fullName, "approve"),
                            icon: const Icon(Icons.check),
                            label: const Text("Duyệt"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          ),
                        if (user.isDeleted == 0)
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(user.id, user.fullName, "delete"),
                            icon: const Icon(Icons.lock),
                            label: const Text("Khóa"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(user.id, user.fullName, "unlock"),
                            icon: const Icon(Icons.lock_open),
                            label: const Text("Mở khóa"),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                          ),
                      ],
                    ),
                    if (user.activityLogs.isNotEmpty) ...[
                      const Divider(),
                      const Text("Lịch sử hoạt động gần đây:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...user.activityLogs.map((log) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text("${log.hanhDong} bởi ${log.adminName ?? 'Admin'}"),
                        subtitle: Text("${log.ghiChu}\n${log.thoiGian}"),
                      )),
                    ]
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserAdminModel user) {
    String text = "Chờ duyệt";
    Color color = Colors.orange;
    if (user.isDeleted == 1) {
      text = "Đã khóa";
      color = Colors.red;
    } else if (user.isApproved == 1) {
      text = "Hoạt động";
      color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin': return Colors.red;
      case 'ChuTro': return const Color(0xFF10B981);
      case 'KhachHang': return const Color(0xFF2563EB);
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin': return Icons.admin_panel_settings;
      case 'ChuTro': return Icons.business_center;
      case 'KhachHang': return Icons.person;
      default: return Icons.help_outline;
    }
  }
}
