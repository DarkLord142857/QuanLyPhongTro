class UserAdminModel {
  final int id;
  final String username;
  final String fullName;
  final String? identityCard;
  final String? phoneNumber;
  final String? email;
  final String role;
  final int isApproved;
  final int isDeleted;
  final String createdDate;
  final String? updatedDate;
  final String? isApprovedDate;
  final String? isDeletedDate;
  final String? nguoiSuaName;
  final String? nguoiDuyetName;
  final String? nguoiXoaName;
  final List<ActivityLog> activityLogs;

  UserAdminModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.identityCard,
    this.phoneNumber,
    this.email,
    required this.role,
    required this.isApproved,
    required this.isDeleted,
    required this.createdDate,
    this.updatedDate,
    this.isApprovedDate,
    this.isDeletedDate,
    this.nguoiSuaName,
    this.nguoiDuyetName,
    this.nguoiXoaName,
    required this.activityLogs,
  });

  factory UserAdminModel.fromJson(Map<String, dynamic> json) {
    var list = json['activityLogs'] as List? ?? [];
    List<ActivityLog> logs = list.map((i) => ActivityLog.fromJson(i)).toList();

    return UserAdminModel(
      id: json['id'],
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      identityCard: json['identityCard'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      role: json['role'] ?? '',
      isApproved: json['isApproved'] ?? 0,
      isDeleted: json['isDeleted'] ?? 0,
      createdDate: json['createdDate'] ?? '',
      updatedDate: json['updatedDate'],
      isApprovedDate: json['isApprovedDate'],
      isDeletedDate: json['isDeletedDate'],
      nguoiSuaName: json['nguoiSuaName'],
      nguoiDuyetName: json['nguoiDuyetName'],
      nguoiXoaName: json['nguoiXoaName'],
      activityLogs: logs,
    );
  }
}

class ActivityLog {
  final String hanhDong;
  final String ghiChu;
  final String thoiGian;
  final String? adminName;

  ActivityLog({
    required this.hanhDong,
    required this.ghiChu,
    required this.thoiGian,
    this.adminName,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      hanhDong: json['hanhDong'] ?? '',
      ghiChu: json['ghiChu'] ?? '',
      thoiGian: json['thoiGian'] ?? '',
      adminName: json['adminName'],
    );
  }
}
