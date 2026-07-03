import 'dart:convert';

/// Khởi tạo Model chính chứa thông tin Phòng, Khách thuê và danh sách Đặc tính phòng
class RoomTenantModel {
  final int phongId;
  final int nhaTroId;
  final String soPhong;
  final int soNguoiToiDa;
  final int soLuongXeToiDa;
  final double giaPhong;
  final int trangThai; // 0 = Phòng trống, 1 = Đang thuê (Đồng bộ với TrangThai trong DB)
  final KhachThueModel? khachThue;
  final List<ThuocTinhPhongModel> danhSachThuocTinh; // 🔥 THUỘC TÍNH MỚI JOIN TỪ BACKEND

  RoomTenantModel({
    required this.phongId,
    required this.nhaTroId,
    required this.soPhong,
    required this.soNguoiToiDa,
    required this.soLuongXeToiDa,
    required this.giaPhong,
    required this.trangThai,
    this.khachThue,
    required this.danhSachThuocTinh,
  });

  factory RoomTenantModel.fromJson(Map<String, dynamic> json) {
    // Ép kiểu an toàn phòng tránh null hoặc sai kiểu dữ liệu từ API PHP
    int pId = json['PhongId'] ?? json['Id'] ?? json['phongId'] ?? json['id'] ?? 0;
    int nTroId = json['NhaTroId'] ?? json['nhaTroId'] ?? 1;
    String sPhong = json['SoPhong'] ?? json['soPhong'] ?? '';
    int sNguoi = json['SoNguoiToiDa'] ?? json['soNguoiToiDa'] ?? 0;
    int sXe = json['SoLuongXeToiDa'] ?? json['soLuongXeToiDa'] ?? 0;
    
    double gPhong = 0.0;
    if (json['GiaPhong'] != null) {
      gPhong = double.tryParse(json['GiaPhong'].toString()) ?? 0.0;
    } else if (json['giaPhong'] != null) {
      gPhong = double.tryParse(json['giaPhong'].toString()) ?? 0.0;
    }

    int active = json['IsActive'] ?? json['isActive'] ?? json['TrangThai'] ?? json['trangThai'] ?? 0;

    // Phân tích thông tin Khách Thuê (nếu có)
    KhachThueModel? kThue;
    if (json['KhachThue'] != null) {
      kThue = KhachThueModel.fromJson(json['KhachThue']);
    } else if (json['khachThue'] != null) {
      kThue = KhachThueModel.fromJson(json['khachThue']);
    }

    // 🔥 Xử lý mảng động danh sách thuộc tính phòng từ câu lệnh JOIN 3 bảng
    var listAttributes = json['DanhSachThuocTinh'] ?? json['danhSachThuocTinh'] ?? [];
    List<ThuocTinhPhongModel> attrs = [];
    if (listAttributes is List) {
      attrs = listAttributes.map((item) => ThuocTinhPhongModel.fromJson(item)).toList();
    }

    return RoomTenantModel(
      phongId: pId,
      nhaTroId: nTroId,
      soPhong: sPhong,
      soNguoiToiDa: sNguoi,
      soLuongXeToiDa: sXe,
      giaPhong: gPhong,
      trangThai: active,
      khachThue: kThue,
      danhSachThuocTinh: attrs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PhongId': phongId,
      'NhaTroId': nhaTroId,
      'SoPhong': soPhong,
      'SoNguoiToiDa': soNguoiToiDa,
      'SoLuongXeToiDa': soLuongXeToiDa,
      'GiaPhong': giaPhong,
      'TrangThai': trangThai,
      'KhachThue': khachThue?.toJson(),
      'DanhSachThuocTinh': danhSachThuocTinh.map((e) => e.toJson()).toList(),
    };
  }
}

/// Model con quản lý thông tin tóm tắt của Khách Thuê
class KhachThueModel {
  final String hoTen;
  final String soDienThoai;

  KhachThueModel({
    required this.hoTen,
    required this.soDienThoai,
  });

  factory KhachThueModel.fromJson(Map<String, dynamic> json) {
    return KhachThueModel(
      hoTen: json['HoTen'] ?? json['hoTen'] ?? json['FullName'] ?? json['fullName'] ?? '',
      soDienThoai: json['SoDienThoai'] ?? json['soDienThoai'] ?? json['PhoneNumber'] ?? json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'HoTen': hoTen,
      'SoDienThoai': soDienThoai,
    };
  }
}

/// 🔥 Model con quản lý các Đặc tính kỹ thuật của phòng (Gộp từ bảng ThuocTinhPhong)
class ThuocTinhPhongModel {
  final int thuocTinhId;
  final String tenThuocTinh;
  final String giaTriThucTe;
  final String? donVi;
  final int kieuDuLieu;

  ThuocTinhPhongModel({
    required this.thuocTinhId,
    required this.tenThuocTinh,
    required this.giaTriThucTe,
    this.donVi,
    required this.kieuDuLieu,
  });

  factory ThuocTinhPhongModel.fromJson(Map<String, dynamic> json) {
    return ThuocTinhPhongModel(
      thuocTinhId: json['ThuocTinhId'] ?? json['thuocTinhId'] ?? 0,
      tenThuocTinh: json['TenThuocTinh'] ?? json['tenThuocTinh'] ?? '',
      giaTriThucTe: json['GiaTriThucTe'] ?? json['giaTriThucTe'] ?? '',
      donVi: json['DonVi'] ?? json['donVi'],
      kieuDuLieu: json['KieuDuLieu'] ?? json['kieuDuLieu'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ThuocTinhId': thuocTinhId,
      'TenThuocTinh': tenThuocTinh,
      'GiaTriThucTe': giaTriThucTe,
      'DonVi': donVi,
      'KieuDuLieu': kieuDuLieu,
    };
  }
}