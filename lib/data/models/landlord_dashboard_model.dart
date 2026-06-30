// Model for landlord dashboard

class LandlordDashboardModel {
  final int tongPhong;
  final int dangO;
  final int conTrong;
  final double daThu;
  final double conNo;
  final List<YeuCauMoi> yeuCauMoi;
  final List<ThongBaoDaGui> thongBaoDaGui;

  LandlordDashboardModel({
    required this.tongPhong,
    required this.dangO,
    required this.conTrong,
    required this.daThu,
    required this.conNo,
    required this.yeuCauMoi,
    required this.thongBaoDaGui,
  });

  factory LandlordDashboardModel.fromJson(Map<String, dynamic> json) {
    // Ép kiểu danh sách an toàn, tránh lỗi rò rỉ kiểu dữ liệu động (dynamic list)
    var listYc = json['yeuCauMoi'] as List? ?? [];
    List<YeuCauMoi> dynamicYeuCau = listYc.map((i) => YeuCauMoi.fromJson(i)).toList();

    var listTb = json['thongBaoDaGui'] as List? ?? [];
    List<ThongBaoDaGui> dynamicThongBao = listTb.map((i) => ThongBaoDaGui.fromJson(i)).toList();

    return LandlordDashboardModel(
      tongPhong: json['tongPhong'] ?? 0,
      dangO: json['dangO'] ?? 0,
      conTrong: json['conTrong'] ?? 0,
      daThu: (json['daThu'] is num) ? (json['daThu'] as num).toDouble() : 0.0,
      conNo: (json['conNo'] is num) ? (json['conNo'] as num).toDouble() : 0.0,
      yeuCauMoi: dynamicYeuCau,
      thongBaoDaGui: dynamicThongBao,
    );
  }
}

class YeuCauMoi {
  final int id;
  final String soPhong;
  final String tieuDe;
  final String moTa;
  final int trangThai;
  final String ngayGui;
  final String tenKhachHang;

  YeuCauMoi({
    required this.id,
    required this.soPhong,
    required this.tieuDe,
    required this.moTa,
    required this.trangThai,
    required this.ngayGui,
    required this.tenKhachHang,
  });

  factory YeuCauMoi.fromJson(Map<String, dynamic> json) {
    return YeuCauMoi(
      id: json['id'] ?? 0,
      soPhong: json['soPhong']?.toString() ?? '',
      tieuDe: json['tieuDe']?.toString() ?? '',
      moTa: json['moTa']?.toString() ?? '',
      // Bẫy lỗi ép kiểu cực kỳ an toàn: 
      // Nếu là int thì nhận luôn, nếu là kiểu khác thì chuyển thành chuỗi rồi ép kiểu về int
      trangThai: json['trangThai'] is int 
          ? json['trangThai'] 
          : (int.tryParse(json['trangThai']?.toString() ?? '0') ?? 0),
      ngayGui: json['ngayGui']?.toString() ?? '',
      tenKhachHang: json['tenKhachHang']?.toString() ?? '',
    );
  }
}

class ThongBaoDaGui {
  final int id;
  final String tieuDe;
  final String noiDung;
  final String tenNhaTro;
  final String ngayTao;

  ThongBaoDaGui({
    required this.id,
    required this.tieuDe,
    required this.noiDung,
    required this.tenNhaTro,
    required this.ngayTao,
  });

  factory ThongBaoDaGui.fromJson(Map<String, dynamic> json) {
    return ThongBaoDaGui(
      id: json['id'] ?? 0,
      tieuDe: json['tieuDe']?.toString() ?? '',
      noiDung: json['noiDung']?.toString() ?? '',
      tenNhaTro: json['tenNhaTro']?.toString() ?? 'Tất cả các khu nhà',
      ngayTao: json['ngayTao']?.toString() ?? '',
    );
  }
}