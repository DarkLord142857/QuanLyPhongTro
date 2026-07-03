class HouseModel {
  final int id;
  final String tenNha;
  final String diaChi;
  final String? giayToPhapLy;
  final int maQL;
  final int isApproved;
  final int isDeleted;

  HouseModel({
    required this.id,
    required this.tenNha,
    required this.diaChi,
    this.giayToPhapLy,
    required this.maQL,
    required this.isApproved,
    required this.isDeleted,
  });

  factory HouseModel.fromJson(Map<String, dynamic> json) {
    return HouseModel(
      id: json['Id'] ?? 0,
      tenNha: json['TenNha']?.toString() ?? '',
      diaChi: json['DiaChi']?.toString() ?? '',
      giayToPhapLy: json['GiayToPhapLy']?.toString(),
      maQL: json['MaQL'] ?? 0,
      isApproved: json['IsApproved'] ?? 0,
      isDeleted: json['IsDeleted'] ?? 0,
    );
  }
}
