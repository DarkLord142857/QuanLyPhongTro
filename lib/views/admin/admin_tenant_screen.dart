import 'package:flutter/material.dart';
import '../../data/models/tenant_model.dart';
import '../../data/services/tenant_api_service.dart';
import 'package:intl/intl.dart';

class AdminTenantScreen extends StatefulWidget {
  final int landlordId;
  final VoidCallback? onBackHome;
  const AdminTenantScreen({super.key, required this.landlordId, this.onBackHome});

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await TenantApiService.fetchTenants();
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
      final rooms = await TenantApiService.fetchAvailableRooms();
      if (mounted) {
        setModalState(() {
          _availableRooms = rooms;
        });
      }
    } catch (e) {
      print("Lỗi tải phòng trống: $e");
    }
  }

  String _formatCurrency(String? amount) {
    if (amount == null || amount.isEmpty) return "0 đ";
    final value = double.tryParse(amount)?.toInt() ?? 0;
    return "${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  void _showDeleteDialog(TenantModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa khách & Giải phóng phòng?"),
        content: Text("Xác nhận xóa khách hàng '${tenant.fullName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await TenantApiService.deleteTenant(tenant.id, widget.landlordId);
              _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
              if (res['status'] == 'success') _loadData();
            },
            child: const Text("Xác nhận", style: TextStyle(color: Colors.red)),
          ),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          if (!isEdit && _availableRooms.isEmpty) {
            _loadAvailableRooms(setModalState);
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24, left: 20, right: 20
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? "Cập nhật hồ sơ khách (Admin)" : "Thêm mới & Tạo hợp đồng (Admin)",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (!isEdit) ...[
                    Row(
                      children: [
                        const Text("Đã có tài khoản?"),
                        const Spacer(),
                        Switch(
                          value: _hasAccount,
                          activeColor: Colors.blue,
                          onChanged: (val) {
                            setModalState(() {
                              _hasAccount = val;
                            });
                          },
                        )
                      ],
                    ),
                  ],

                  if (isEdit || !_hasAccount) ...[
                    TextField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: "Họ và tên *")),
                    TextField(controller: identityCtrl, decoration: const InputDecoration(labelText: "Số CCCD")),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "SĐT"), keyboardType: TextInputType.phone),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress),
                    
                    if (!isEdit) ...[
                      TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: "Username *")),
                      TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: "Mật khẩu *"), obscureText: true),
                    ]
                  ] else ...[
                    DropdownButtonFormField<int>(
                      value: _selectedTenantId,
                      decoration: const InputDecoration(labelText: "Chọn tài khoản có sẵn"),
                      items: _allExistingUsers.map((user) {
                        return DropdownMenuItem<int>(
                          value: user.id,
                          child: Text("${user.fullName} (${user.username})"),
                        );
                      }).toList(),
                      onChanged: (int? newValue) => setModalState(() => _selectedTenantId = newValue),
                    ),
                  ],

                  if (!isEdit) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedRoomId,
                      decoration: const InputDecoration(labelText: "Chọn phòng trống *"),
                      items: _availableRooms.map((room) {
                        return DropdownMenuItem<int>(
                          value: room['Id'],
                          child: Text("Phòng ${room['SoPhong']}"),
                        );
                      }).toList(),
                      onChanged: (int? newValue) => setModalState(() => _selectedRoomId = newValue),
                    ),
                    TextField(
                      controller: startDateCtrl,
                      readOnly: true,
                      onTap: () => _selectDate(context, true, setModalState),
                      decoration: const InputDecoration(labelText: "Ngày bắt đầu *"),
                    ),
                    TextField(
                      controller: endDateCtrl,
                      readOnly: true,
                      onTap: () => _selectDate(context, false, setModalState),
                      decoration: const InputDecoration(labelText: "Ngày hết hạn *"),
                    ),
                    TextField(controller: depositCtrl, decoration: const InputDecoration(labelText: "Tiền cọc"), keyboardType: TextInputType.number),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () async {
                      if (isEdit) {
                        final data = {
                          "id": tenant.id,
                          "FullName": fullNameCtrl.text.trim(),
                          "IdentityCard": identityCtrl.text.trim(),
                          "PhoneNumber": phoneCtrl.text.trim(),
                          "Email": emailCtrl.text.trim(),
                        };
                        final res = await TenantApiService.updateTenant(data);
                        Navigator.pop(context);
                        _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
                      } else {
                        if (_selectedRoomId == null) {
                          _showSnackBar("Vui lòng chọn phòng", isSuccess: false);
                          return;
                        }
                        Map<String, dynamic> data = {
                          "PhongTroId": _selectedRoomId,
                          "NgayBatDau": dbFormat.format(selectedStartDate),
                          "NgayKetThuc": dbFormat.format(selectedEndDate),
                          "TienCoc": double.tryParse(depositCtrl.text) ?? 0,
                        };

                        if (_hasAccount) {
                          if (_selectedTenantId == null) {
                            _showSnackBar("Chọn tài khoản", isSuccess: false);
                            return;
                          }
                          data["KhachHangId"] = _selectedTenantId;
                        } else {
                          data.addAll({
                            "Username": usernameCtrl.text.trim(),
                            "Password": passwordCtrl.text.trim(),
                            "FullName": fullNameCtrl.text.trim(),
                            "IdentityCard": identityCtrl.text.trim(),
                            "PhoneNumber": phoneCtrl.text.trim(),
                            "Email": emailCtrl.text.trim(),
                          });
                        }

                        final res = await TenantApiService.addTenant(data);
                        Navigator.pop(context);
                        _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
                      }
                      _loadData();
                    },
                    child: Text(isEdit ? "Lưu" : "Kích hoạt (Admin)"),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isSuccess ? Colors.blue : Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (widget.onBackHome != null) {
              widget.onBackHome!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text("Quản lý Khách thuê (Admin)"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true, 
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tenants.length,
              itemBuilder: (context, index) {
                final item = _tenants[index];
                return Card(
                  child: ListTile(
                    title: Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Phòng: ${item.soPhong ?? 'N/A'}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openTenantFormBottomSheet(tenant: item)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteDialog(item)),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTenantFormBottomSheet(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
