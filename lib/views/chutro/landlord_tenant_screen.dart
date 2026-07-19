import 'package:flutter/material.dart';
import '../../data/models/tenant_model.dart';
import '../../data/services/tenant_api_service.dart';
import 'package:intl/intl.dart';

class LandlordTenantScreen extends StatefulWidget {
  final int landlordId;
  final VoidCallback? onBackHome;
  const LandlordTenantScreen({super.key, required this.landlordId, this.onBackHome});

  @override
  State<LandlordTenantScreen> createState() => _LandlordTenantScreenState();
}

class _LandlordTenantScreenState extends State<LandlordTenantScreen> {
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
      // 🔥 NGĂN VÁCH DỮ LIỆU: Chỉ lấy khách thuê của chủ trọ này
      final data = await TenantApiService.fetchTenants(landlordId: widget.landlordId);
      if (mounted) {
        setState(() {
          _tenants = data;
          _allExistingUsers = data; 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar("Lỗi kết nối máy chủ backend!", isSuccess: false);
    }
  }

Future<void> _loadAvailableRooms([StateSetter? setModalState]) async {
    try {
      // 🔥 NGĂN VÁCH DỮ LIỆU: Chỉ lấy phòng trống của chủ trọ này
      final rooms = await TenantApiService.fetchAvailableRooms(landlordId: widget.landlordId);
      if (mounted) {
        setState(() {
          _availableRooms = rooms;
        });
        // Nếu có setModalState của Bottom Sheet thì cập nhật luôn giao diện bên trong nó
        if (setModalState != null) {
          setModalState(() {
            _availableRooms = rooms;
          });
        }
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
        title: const Text("Thanh lý hợp đồng & Xóa khách?"),
        content: Text("Bạn có chắc chắn muốn xóa khách hàng '${tenant.fullName}'? Hệ thống sẽ tự động giải phóng phòng '${tenant.soPhong ?? ''}' về trạng thái TRỐNG."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await TenantApiService.deleteTenant(tenant.id, widget.landlordId);
              _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
              if (res['status'] == 'success') _loadData();
            },
            child: const Text("Xác nhận xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        helpText: isStartDate ? 'CHỌN NGÀY BẮT ĐẦU Ở' : 'CHỌN NGÀY HẾT HẠN HỢP ĐỒNG',
        cancelText: 'HỦY',
        confirmText: 'CHỌN',
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
        if (!isEdit) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
      
            });
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEdit ? "Cập nhật hồ sơ khách thuê" : "Thêm mới khách & Tạo hợp đồng",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)), 
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (!isEdit) ...[
                    Row(
                      children: [
                        const Text("Khách đã có tài khoản hệ thống?", style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Switch(
                          value: _hasAccount,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) {
                            setModalState(() {
                              _hasAccount = val;
                              _selectedTenantId = null;
                              fullNameCtrl.clear();
                              identityCtrl.clear();
                              phoneCtrl.clear();
                              emailCtrl.clear();
                            });
                          },
                        )
                      ],
                    ),
                    const Divider(),
                  ],

                  if (isEdit || !_hasAccount) ...[
                    TextField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: "Họ và tên khách thuê *")),
                    TextField(controller: identityCtrl, decoration: const InputDecoration(labelText: "Số CCCD / CMND"), keyboardType: TextInputType.number),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Số điện thoại"), keyboardType: TextInputType.phone),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Địa chỉ Email"), keyboardType: TextInputType.emailAddress),
                    
                    if (!isEdit) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 4),
                        child: Text("Cấp tài khoản ứng dụng khách thuê", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      ),
                      TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: "Tên tài khoản (Username) *")),
                      TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: "Mật khẩu đăng nhập *"), obscureText: true),
                    ]
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: Text("Chọn tài khoản khách thuê có sẵn *", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ),
                    DropdownButtonFormField<int>(
                      value: _selectedTenantId,
                      decoration: const InputDecoration(
                        labelText: "Danh sách tài khoản",
                        prefixIcon: Icon(Icons.person, color: Color(0xFF10B981)),
                      ),
                      hint: const Text("Chọn khách hàng đã đăng ký"),
                      items: _allExistingUsers.map((user) {
                        return DropdownMenuItem<int>(
                          value: user.id,
                          child: Text("${user.fullName} (${user.username})"),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setModalState(() {
                          _selectedTenantId = newValue;
                        });
                      },
                    ),
                  ],

                  if (!isEdit) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 4),
                      child: Text("Cấu hình xếp phòng & Hợp đồng", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedRoomId,
                      decoration: const InputDecoration(
                        labelText: "Chọn phòng trọ trống *",
                        prefixIcon: Icon(Icons.home_work_rounded, color: Color(0xFF10B981)),
                      ),
                      hint: const Text("Bấm vào để chọn phòng trống"),
                      items: _availableRooms.map((room) {
                        return DropdownMenuItem<int>(
                          value: room['Id'],
                          child: Text("Phòng ${room['SoPhong']} (${room['TenNha']})"),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setModalState(() {
                          _selectedRoomId = newValue;
                        });
                      },
                    ),
                    TextField(
                      controller: startDateCtrl,
                      readOnly: true, 
                      onTap: () => _selectDate(context, true, setModalState),
                      decoration: const InputDecoration(
                        labelText: "Ngày bắt đầu ở *",
                        prefixIcon: Icon(Icons.calendar_today_rounded, color: Color(0xFF10B981)),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                    ),
                    TextField(
                      controller: endDateCtrl,
                      readOnly: true, 
                      onTap: () => _selectDate(context, false, setModalState),
                      decoration: const InputDecoration(
                        labelText: "Ngày hết hạn HĐ *",
                        prefixIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF10B981)),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                    ),
                    TextField(controller: depositCtrl, decoration: const InputDecoration(labelText: "Tiền đặt cọc giữ phòng"), keyboardType: TextInputType.number),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                          if (isEdit) {
                            if (fullNameCtrl.text.trim().isEmpty) {
                              _showSnackBar("Vui lòng không để trống họ tên khách", isSuccess: false);
                              return;
                            }
                            final data = {
                              "id": tenant.id,
                              "FullName": fullNameCtrl.text.trim(),
                              "IdentityCard": identityCtrl.text.trim().isEmpty ? null : identityCtrl.text.trim(),
                              "PhoneNumber": phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              "Email": emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                              "NguoiGuiId": widget.landlordId, 
                              "caller_id": widget.landlordId,
                            };
                            final res = await TenantApiService.updateTenant(data);
                            Navigator.pop(context);
                            _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
                          } else {
                            // CHẾ ĐỘ: TẠO MỚI HỢP ĐỒNG (ADD TENANT)
                            if (_selectedRoomId == null) {
                              _showSnackBar("Vui lòng chọn phòng trọ trống", isSuccess: false);
                              return;
                            }
                            
                            // Khởi tạo các tham số hợp đồng bắt buộc [source: 7]
                            Map<String, dynamic> data = {
                              "PhongTroId": _selectedRoomId,
                              "NgayBatDau": dbFormat.format(selectedStartDate), 
                              "NgayKetThuc": dbFormat.format(selectedEndDate),   
                              "TienCoc": double.tryParse(depositCtrl.text) ?? 0,
                              "NguoiGuiId": widget.landlordId,
                            };

                            if (_hasAccount) {
                              // TRƯỜNG HỢP: KHÁCH ĐÃ CÓ TÀI KHOẢN HỆ THỐNG
                              if (_selectedTenantId == null) {
                                _showSnackBar("Vui lòng chọn một tài khoản khách hàng", isSuccess: false);
                                return;
                              }
                              
                              // Tìm tài khoản khách hàng được chọn trong danh sách có sẵn
                              final selectedUser = _allExistingUsers.firstWhere((u) => u.id == _selectedTenantId);
                              
                              data.addAll({
                                "KhachHangId": _selectedTenantId,
                                // Bắt buộc phải truyền các trường này lên để vượt qua bộ lọc !empty của backend PHP [source: 7]
                                "FullName": selectedUser.fullName,
                                "Username": selectedUser.username,
                                "Password": "bypass_password_validation", // Chuỗi giả định không rỗng để tránh lỗi 400 [source: 7]
                                "IdentityCard": selectedUser.identityCard,
                                "PhoneNumber": selectedUser.phoneNumber,
                                "Email": selectedUser.email,
                              });
                            } else {
                              // TRƯỜNG HỢP: KHÁCH CHƯA CÓ TÀI KHOẢN (TẠO MỚI HOÀN TOÀN)
                              if (fullNameCtrl.text.trim().isEmpty || usernameCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
                                _showSnackBar("Vui lòng nhập đầy đủ Họ tên, Username và Mật khẩu", isSuccess: false);
                                return;
                              }
                              data.addAll({
                                "Username": usernameCtrl.text.trim(),
                                "Password": passwordCtrl.text.trim(),
                                "FullName": fullNameCtrl.text.trim(),
                                "IdentityCard": identityCtrl.text.trim().isEmpty ? null : identityCtrl.text.trim(),
                                "PhoneNumber": phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                "Email": emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                              });
                            }

                            final res = await TenantApiService.addTenant(data);
                            Navigator.pop(context);
                            _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
                          }
                          _loadData();
                        },
                    child: Text(isEdit ? "Lưu thay đổi" : "Lập hợp đồng & Kích hoạt khách", style: const TextStyle(fontWeight: FontWeight.bold)),
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
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildEmptyWidget(BoxConstraints constraints) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 72, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "Không có dữ liệu khách thuê nào", 
                style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                "Vui lòng nhấn nút góc dưới để thêm khách mới", 
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // AppBar đã được LandlordMainScreen quản lý chung
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF10B981),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF10B981))));
            }
            
            if (_tenants.isEmpty) {
              return _buildEmptyWidget(constraints);
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _tenants.length,
              itemBuilder: (context, index) {
                final item = _tenants[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text("Tài khoản: ${item.username}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.home_work_outlined, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.phongTroId != null ? "Phòng ${item.soPhong} - ${item.tenNha}" : "Chưa xếp phòng / Đã thanh lý HĐ",
                                      style: TextStyle(
                                        fontSize: 13, 
                                        color: item.phongTroId != null ? const Color(0xFF334155) : Colors.red, 
                                        fontWeight: item.phongTroId != null ? FontWeight.w500 : FontWeight.normal
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.ngayBatDau != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text("Thời hạn: ${item.ngayBatDau} đến ${item.ngayKetThuc}", style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.monetization_on_outlined, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text("Tiền đặt cọc: ${_formatCurrency(item.tienCoc)}", style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                              onPressed: () => _openTenantFormBottomSheet(tenant: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => _showDeleteDialog(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 1. Gọi API tải danh sách phòng trống mới nhất trước
          await _loadAvailableRooms();
          // 2. Sau khi có data mới nhất rồi mới mở Bottom Sheet lên
          _openTenantFormBottomSheet();
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }
}