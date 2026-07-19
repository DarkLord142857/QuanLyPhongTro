import 'package:flutter/material.dart';
import '../../data/models/tenant_model.dart';
import '../../data/services/tenant_api_service.dart';
import 'package:intl/intl.dart';

class AdminTenantScreen extends StatefulWidget {
  final int landlordId;
  final int? houseId; // Thêm houseId
  final VoidCallback? onBackHome;
  const AdminTenantScreen({super.key, required this.landlordId, this.houseId, this.onBackHome});

  @override
  State<AdminTenantScreen> createState() => _AdminTenantScreenState();
}

class _AdminTenantScreenState extends State<AdminTenantScreen> {
  List<TenantModel> _tenants = [];
  List<Map<String, dynamic>> _availableRooms = [];
  List<TenantModel> _allExistingUsers = []; 
  bool _isLoading = true;
  int? _selectedRoomId;
  int? _selectedTenantId; 
  bool _hasAccount = false;
  final Color primaryColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await TenantApiService.fetchTenants(houseId: widget.houseId);
      if (mounted) {
        setState(() {
          _tenants = data;
          _allExistingUsers = data; 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar("Lỗi kết nối máy chủ!", isSuccess: false);
    }
  }

  Future<void> _loadAvailableRooms(StateSetter setModalState) async {
    try {
      final rooms = await TenantApiService.fetchAvailableRooms(houseId: widget.houseId);
      if (mounted) {
        setModalState(() {
          _availableRooms = rooms;
        });
      }
    } catch (e) {
      print("Lỗi tải phòng trống: $e");
    }
  }

  void _showDeleteDialog(TenantModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Xác nhận xóa khách", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Xác nhận xóa khách hàng '${tenant.fullName}' và giải phóng phòng?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await TenantApiService.deleteTenant(tenant.id, widget.landlordId);
              _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
              if (res['status'] == 'success') _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isSuccess ? primaryColor : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Xóa AppBar để tránh chồng lấn với AdminMainScreen
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTenantFormBottomSheet(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: _isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _tenants.length,
              itemBuilder: (context, index) {
                final item = _tenants[index];
                return _buildTenantCard(item);
              },
            ),
      ),
    );
  }

  Widget _buildTenantCard(TenantModel tenant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tenant.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                        child: Text("Phòng ${tenant.soPhong ?? 'N/A'}", style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                  onPressed: () => _openTenantFormBottomSheet(tenant: tenant),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => _showDeleteDialog(tenant),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.8),
            Row(
              children: [
                _buildContactInfo(Icons.phone_android_rounded, tenant.phoneNumber ?? 'Chưa cập nhật'),
                const SizedBox(width: 20),
                _buildContactInfo(Icons.email_outlined, tenant.email ?? 'Chưa cập nhật'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _openTenantFormBottomSheet({TenantModel? tenant}) {
    final bool isEdit = tenant != null;
    final fullNameCtrl = TextEditingController(text: isEdit ? tenant.fullName : '');
    final identityCtrl = TextEditingController(text: isEdit ? tenant.identityCard : '');
    final phoneCtrl = TextEditingController(text: isEdit ? tenant.phoneNumber : '');
    final emailCtrl = TextEditingController(text: isEdit ? tenant.email : '');
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final depositCtrl = TextEditingController(text: '0');
    DateTime selectedStartDate = DateTime.now();
    DateTime selectedEndDate = DateTime.now().add(const Duration(days: 365));
    final DateFormat displayFormat = DateFormat('dd/MM/yyyy');
    final DateFormat dbFormat = DateFormat('yyyy-MM-dd');
    final startDateCtrl = TextEditingController(text: displayFormat.format(selectedStartDate));
    final endDateCtrl = TextEditingController(text: displayFormat.format(selectedEndDate));
    
    _selectedRoomId = null;
    _selectedTenantId = null;
    _hasAccount = false;

    Future<void> _selectDate(BuildContext context, bool isStartDate, StateSetter setModalState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: isStartDate ? selectedStartDate : selectedEndDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2040),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: primaryColor),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setModalState(() {
          if (isStartDate) {
            selectedStartDate = picked;
            startDateCtrl.text = displayFormat.format(picked);
          } else {
            selectedEndDate = picked;
            endDateCtrl.text = displayFormat.format(picked);
          }
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          if (!isEdit && _availableRooms.isEmpty) {
            _loadAvailableRooms(setModalState);
          }
          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 24, left: 24, right: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text(isEdit ? "Cập nhật hồ sơ khách" : "Thêm khách & Tạo hợp đồng", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (!isEdit) ...[
                    Row(
                      children: [
                        const Text("Đã có tài khoản hệ thống?", style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Switch(
                          value: _hasAccount,
                          activeColor: primaryColor,
                          onChanged: (val) { setModalState(() { _hasAccount = val; }); },
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (isEdit || !_hasAccount) ...[
                    TextField(controller: fullNameCtrl, decoration: InputDecoration(labelText: "Họ và tên *", prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                    const SizedBox(height: 16),
                    TextField(controller: identityCtrl, decoration: InputDecoration(labelText: "Số CCCD", prefixIcon: const Icon(Icons.badge_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                    const SizedBox(height: 16),
                    TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: "Số điện thoại", prefixIcon: const Icon(Icons.phone_android), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    TextField(controller: emailCtrl, decoration: InputDecoration(labelText: "Email", prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), keyboardType: TextInputType.emailAddress),
                    if (!isEdit) ...[
                      const SizedBox(height: 16),
                      TextField(controller: usernameCtrl, decoration: InputDecoration(labelText: "Tên đăng nhập *", prefixIcon: const Icon(Icons.account_circle_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                      const SizedBox(height: 16),
                      TextField(controller: passwordCtrl, decoration: InputDecoration(labelText: "Mật khẩu mặc định *", prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), obscureText: true),
                    ]
                  ] else ...[
                    DropdownButtonFormField<int>(
                      value: _selectedTenantId,
                      decoration: InputDecoration(labelText: "Chọn tài khoản có sẵn", prefixIcon: const Icon(Icons.how_to_reg_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                      items: _allExistingUsers.map((user) { return DropdownMenuItem<int>(value: user.id, child: Text("${user.fullName} (${user.username})")); }).toList(),
                      onChanged: (int? newValue) => setModalState(() => _selectedTenantId = newValue),
                    ),
                  ],
                  if (!isEdit) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedRoomId,
                      decoration: InputDecoration(labelText: "Chọn phòng trống *", prefixIcon: const Icon(Icons.door_front_door_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                      items: _availableRooms.map((room) { return DropdownMenuItem<int>(value: room['Id'], child: Text("Phòng ${room['SoPhong']}")); }).toList(),
                      onChanged: (int? newValue) => setModalState(() => _selectedRoomId = newValue),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: startDateCtrl, readOnly: true, onTap: () => _selectDate(context, true, setModalState), decoration: InputDecoration(labelText: "Ngày bắt đầu *", prefixIcon: const Icon(Icons.calendar_today_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                    const SizedBox(height: 16),
                    TextField(controller: endDateCtrl, readOnly: true, onTap: () => _selectDate(context, false, setModalState), decoration: InputDecoration(labelText: "Ngày kết thúc *", prefixIcon: const Icon(Icons.event_note_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                    const SizedBox(height: 16),
                    TextField(controller: depositCtrl, decoration: InputDecoration(labelText: "Số tiền cọc (VNĐ)", prefixIcon: const Icon(Icons.monetization_on_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), keyboardType: TextInputType.number),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
                      onPressed: () async {
                        if (isEdit) {
                          final data = {"id": tenant.id, "FullName": fullNameCtrl.text.trim(), "IdentityCard": identityCtrl.text.trim(), "PhoneNumber": phoneCtrl.text.trim(), "Email": emailCtrl.text.trim()};
                          final res = await TenantApiService.updateTenant(data);
                          Navigator.pop(context);
                          _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
                        } else {
                          if (_selectedRoomId == null) { _showSnackBar("Vui lòng chọn phòng", isSuccess: false); return; }
                          Map<String, dynamic> data = {"PhongTroId": _selectedRoomId, "NgayBatDau": dbFormat.format(selectedStartDate), "NgayKetThuc": dbFormat.format(selectedEndDate), "TienCoc": double.tryParse(depositCtrl.text) ?? 0};
                          if (_hasAccount) { if (_selectedTenantId == null) { _showSnackBar("Chọn tài khoản", isSuccess: false); return; } data["KhachHangId"] = _selectedTenantId; }
                          else { data.addAll({"Username": usernameCtrl.text.trim(), "Password": passwordCtrl.text.trim(), "FullName": fullNameCtrl.text.trim(), "IdentityCard": identityCtrl.text.trim(), "PhoneNumber": phoneCtrl.text.trim(), "Email": emailCtrl.text.trim()}); }
                          final res = await TenantApiService.addTenant(data);
                          Navigator.pop(context);
                          _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
                        }
                        _loadData();
                      },
                      child: Text(isEdit ? "Lưu thay đổi" : "Xác nhận & Kích hoạt", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
