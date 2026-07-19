import 'dart:convert';

class RoomTenantModel {
  final int phongId;
  final int nhaTroId;
  final String soPhong;
  final int soNguoiToiDa;
  final int soLuongXeToiDa;
  final double giaPhong;
  final int trangThai;
  final KhachThueModel? khachThue;
  final List<ThuocTinhPhongModel> danhSachThuocTinh;
  final List<String> hinhAnh;

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
    required this.hinhAnh,
  });

  factory RoomTenantModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // Xử lý Danh sách thuộc tính linh hoạt
    var rawAttrs = json['DanhSachThuocTinh'] ?? json['danhSachThuocTinh'] ?? [];
    List<ThuocTinhPhongModel> attrs = [];
    if (rawAttrs is List) {
      attrs = rawAttrs.map<ThuocTinhPhongModel>((i) => ThuocTinhPhongModel.fromJson(i as Map<String, dynamic>)).toList();
    }

    // Xử lý Danh sách hình ảnh linh hoạt
    var rawImgs = json['DanhSachHinhAnh'] ?? json['hinhAnh'] ?? json['Images'] ?? [];
    List<String> imgs = [];
    if (rawImgs is List) {
      imgs = rawImgs.map<String>((e) => e.toString()).toList();
    } else if (rawImgs is String && rawImgs.isNotEmpty) {
      imgs = [rawImgs];
    }

    return RoomTenantModel(
      phongId: toInt(json['PhongId'] ?? json['phongId']),
      nhaTroId: toInt(json['NhaTroId'] ?? json['nhaTroId']),
      soPhong: (json['SoPhong'] ?? json['soPhong'] ?? '').toString(),
      soNguoiToiDa: toInt(json['SoNguoiToiDa'] ?? json['soNguoiToiDa']),
      soLuongXeToiDa: toInt(json['SoLuongXeToiDa'] ?? json['soLuongXeToiDa']),
      giaPhong: toDouble(json['GiaPhong'] ?? json['giaPhong']),
      trangThai: toInt(json['TrangThai'] ?? json['trangThai'] ?? json['isActive']),
      khachThue: (json['KhachThue'] ?? json['khachThue']) != null 
          ? KhachThueModel.fromJson((json['KhachThue'] ?? json['khachThue']) as Map<String, dynamic>) 
          : null,
      danhSachThuocTinh: attrs,
      hinhAnh: imgs,
    );
  }
}

class KhachThueModel {
  final String hoTen;
  final String soDienThoai;
  KhachThueModel({required this.hoTen, required this.soDienThoai});
  factory KhachThueModel.fromJson(Map<String, dynamic> json) {
    return KhachThueModel(
      hoTen: (json['HoTen'] ?? json['hoTen'] ?? json['FullName'] ?? '').toString(),
      soDienThoai: (json['SoDienThoai'] ?? json['soDienThoai'] ?? json['PhoneNumber'] ?? '').toString(),
    );
  }
}

class ThuocTinhPhongModel {
  final int thuocTinhId;
  final String tenThuocTinh;
  final String giaTriThucTe;
  final String? donVi;
  final int kieuDuLieu;

  ThuocTinhPhongModel({required this.thuocTinhId, required this.tenThuocTinh, required this.giaTriThucTe, this.donVi, required this.kieuDuLieu});

  factory ThuocTinhPhongModel.fromJson(Map<String, dynamic> json) {
    return ThuocTinhPhongModel(
      thuocTinhId: int.tryParse((json['ThuocTinhId'] ?? json['thuocTinhId'] ?? '0').toString()) ?? 0,
      tenThuocTinh: (json['TenThuocTinh'] ?? json['tenThuocTinh'] ?? '').toString(),
      giaTriThucTe: (json['GiaTriThucTe'] ?? json['giaTriThucTe'] ?? '').toString(),
      donVi: json['DonVi'] ?? json['donVi'],
      kieuDuLieu: int.tryParse((json['KieuDuLieu'] ?? json['kieuDuLieu'] ?? '0').toString()) ?? 0,
    );
  }
}
