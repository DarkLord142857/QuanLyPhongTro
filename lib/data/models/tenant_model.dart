class TenantModel {
  final int id;
  final String username;
  final String fullName;
  final String? identityCard;
  final String? phoneNumber;
  final String? email;
  final int? phongTroId;
  final String? soPhong;
  final String? giaPhong;
  final String? tenNha;
  final int? hopDongId;
  final String? ngayBatDau;
  final String? ngayKetThuc;
  final String? tienCoc;

  TenantModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.identityCard,
    this.phoneNumber,
    this.email,
    this.phongTroId,
    this.soPhong,
    this.giaPhong,
    this.tenNha,
    this.hopDongId,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.tienCoc,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: int.parse(json['KhachHangId'].toString()),
      username: json['Username'] ?? '',
      fullName: json['FullName'] ?? '',
      identityCard: json['IdentityCard']?.toString(),
      phoneNumber: json['PhoneNumber']?.toString(),
      email: json['Email']?.toString(),
      phongTroId: json['PhongTroId'] != null ? int.tryParse(json['PhongTroId'].toString()) : null,
      soPhong: json['SoPhong']?.toString(),
      giaPhong: json['GiaPhong']?.toString(),
      tenNha: json['TenNha']?.toString(),
      hopDongId: json['HopDongId'] != null ? int.tryParse(json['HopDongId'].toString()) : null,
      ngayBatDau: json['NgayBatDau']?.toString(),
      ngayKetThuc: json['NgayKetThuc']?.toString(),
      tienCoc: json['TienCoc']?.toString(),
    );
  }
}