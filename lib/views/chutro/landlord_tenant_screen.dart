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
  List<TenantModel> _allExistingUsers = []; // 🌟 THÊM MỚI: Danh sách toàn bộ user hệ thống để chọn
  bool _isLoading = true;
  int? _selectedRoomId;
  int? _selectedTenantId; // 🌟 THÊM MỚI: Id của tài khoản khách hàng được chọn (nếu đã có tk)
  bool _hasAccount = false; // 🌟 THÊM MỚI: Trạng thái toggle form

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
      // Giả lập hàm lấy danh sách gốc (hoặc lọc từ api trả về các user chưa/đã thuê)
      // Trong thực tế bạn có thể tạo 1 API riêng fetchAllKhachHang()
      if (mounted) {
        setState(() {
          _tenants = data;
          _allExistingUsers = data; // Tạm thời dùng data này hoặc gọi API riêng biệt tùy cấu trúc
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar("Lỗi kết nối máy chủ backend!", isSuccess: false);
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

// 🌟 1. TẠO BIẾN ĐỂ LƯU NGÀY CHỌN THỰC TẾ
    DateTime selectedStartDate = DateTime.now();
    DateTime selectedEndDate = DateTime.now().add(const Duration(days: 365));

    // Định dạng hiển thị phía người dùng (Ngày/Tháng/Năm)
    final DateFormat displayFormat = DateFormat('dd/MM/yyyy');
    // Định dạng gửi lên Database (Năm-Tháng-Ngày)
    final DateFormat dbFormat = DateFormat('yyyy-MM-dd');

    // Ô nhập hiển thị chuỗi ngày đã định dạng thân thiện cho user
    final startDateCtrl = TextEditingController(text: displayFormat.format(selectedStartDate));
    final endDateCtrl = TextEditingController(text: displayFormat.format(selectedEndDate));
    
    _selectedRoomId = null;
    _selectedTenantId = null;
    _hasAccount = false; // Mặc định mở ra là tạo tài khoản mới

// 🌟 2. HÀM CHỌN NGÀY THÔNG QUA LỊCH (DATE PICKER)
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

                  // 🌟 THÊM MỚI: Switch chọn loại hình nếu ở chế độ thêm mới
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

                  // FORM THAY ĐỔI ĐỘNG DỰA TRÊN SWITCH _hasAccount
                  if (isEdit || !_hasAccount) ...[
                    // Form nhập tay thông thường (Khi sửa hoặc khi tạo tài khoản mới)
                    TextField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: "Họ và tên khách thuê *")),
                    TextField(controller: identityCtrl, decoration: const InputDecoration(labelText: "Số CCCD / CMND")),
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
                    // 🌟 TRƯỜNG HỢP ĐÃ CÓ TÀI KHOẢN: Chỉ hiện Dropdown chọn Khách hàng
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

                  // PHẦN CHUNG: Cấu hình phòng và Hợp đồng luôn hiển thị khi tạo mới
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
                    // Ô chọn ngày bắt đầu
                    TextField(
                      controller: startDateCtrl,
                      readOnly: true, // Khóa bàn phím nhập tay, bắt buộc chọn qua lịch
                      onTap: () => _selectDate(context, true, setModalState),
                      decoration: const InputDecoration(
                        labelText: "Ngày bắt đầu ở *",
                        prefixIcon: Icon(Icons.calendar_today_rounded, color: Color(0xFF10B981)),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                    ),
                    // Ô chọn ngày kết thúc
                    TextField(
                      controller: endDateCtrl,
                      readOnly: true, // Khóa bàn phím nhập tay
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
                      // Logic Xử lý khi nhấn nút Lưu / Tạo
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
                        };
                        final res = await TenantApiService.updateTenant(data);
                        Navigator.pop(context);
                        _showSnackBar(res['message'], isSuccess: res['status'] == 'success');
                      } else {
                        // CHẾ ĐỘ TẠO MỚI HỢP ĐỒNG
                        if (_selectedRoomId == null) {
                          _showSnackBar("Vui lòng chọn phòng trọ trống", isSuccess: false);
                          return;
                        }
                        // 🌟 4. CHUYỂN ĐỔI SANG ĐỊNH DẠNG DB (YYYY-MM-DD) KHI GỬI API
                        Map<String, dynamic> data = {
                          "PhongTroId": _selectedRoomId,
                          "NgayBatDau": dbFormat.format(selectedStartDate), // Đã convert thành yyyy-MM-dd
                          "NgayKetThuc": dbFormat.format(selectedEndDate),   // Đã convert thành yyyy-MM-dd
                          "TienCoc": double.tryParse(depositCtrl.text) ?? 0,
                        };

                        if (_hasAccount) {
                          // Trường hợp ĐÃ CÓ tài khoản
                          if (_selectedTenantId == null) {
                            _showSnackBar("Vui lòng chọn một tài khoản khách hàng", isSuccess: false);
                            return;
                        }
                          data["KhachHangId"] = _selectedTenantId;
                        } else {
                          // Trường hợp CHƯA CÓ tài khoản (Tạo mới hoàn toàn)
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (widget.onBackHome != null) {
              widget.onBackHome!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text("Quản lý Khách thuê trọ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true, 
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
        ],
      ),
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
        onPressed: () => _openTenantFormBottomSheet(),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }
}