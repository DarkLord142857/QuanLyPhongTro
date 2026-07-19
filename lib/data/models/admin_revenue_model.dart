class AdminRevenueModel {
  final String status;
  final String cheDo;
  final RevenueData data;

  AdminRevenueModel({
    required this.status,
    required this.cheDo,
    required this.data,
  });

  factory AdminRevenueModel.fromJson(Map<String, dynamic> json) {
    return AdminRevenueModel(
      status: json['status'] ?? '',
      cheDo: json['cheDo'] ?? '',
      data: RevenueData.fromJson(json['data'], json['cheDo']),
    );
  }
}

class RevenueData {
  final int? thang;
  final int nam;
  final SummaryStats tongQuan;
  final List<HouseRevenueDetail> chiTietTheoNhaTro;
  final Comparison? soSanhThangTruoc;
  final List<MonthlyRevenueDetail>? chiTietTheoThang;

  RevenueData({
    this.thang,
    required this.nam,
    required this.tongQuan,
    required this.chiTietTheoNhaTro,
    this.soSanhThangTruoc,
    this.chiTietTheoThang,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json, String cheDo) {
    var houseList = json['chiTietTheoNhaTro'] as List? ?? [];
    List<HouseRevenueDetail> houses = houseList.map((i) => HouseRevenueDetail.fromJson(i)).toList();

    List<MonthlyRevenueDetail>? months;
    if (json['chiTietTheoThang'] != null) {
      var monthList = json['chiTietTheoThang'] as List;
      months = monthList.map((i) => MonthlyRevenueDetail.fromJson(i)).toList();
    }

    return RevenueData(
      thang: json['thang'],
      nam: json['nam'] ?? DateTime.now().year,
      tongQuan: SummaryStats.fromJson(json['tongQuan'] ?? {}),
      chiTietTheoNhaTro: houses,
      soSanhThangTruoc: json['soSanhThangTruoc'] != null ? Comparison.fromJson(json['soSanhThangTruoc']) : null,
      chiTietTheoThang: months,
    );
  }
}

class SummaryStats {
  final double tongTienCoc;
  final double tongTienNha;
  final double tongTienDichVu;
  final double tongDoanhThu;
  final double? trungBinhThang;

  SummaryStats({
    required this.tongTienCoc,
    required this.tongTienNha,
    required this.tongTienDichVu,
    required this.tongDoanhThu,
    this.trungBinhThang,
  });

  factory SummaryStats.fromJson(Map<String, dynamic> json) {
    return SummaryStats(
      tongTienCoc: (json['tongTienCoc'] ?? 0).toDouble(),
      tongTienNha: (json['tongTienNha'] ?? 0).toDouble(),
      tongTienDichVu: (json['tongTienDichVu'] ?? 0).toDouble(),
      tongDoanhThu: (json['tongDoanhThu'] ?? 0).toDouble(),
      trungBinhThang: json['trungBinhThang']?.toDouble(),
    );
  }
}

class HouseRevenueDetail {
  final int nhaTroId;
  final String tenNha;
  final double tienCoc;
  final double tienNha;
  final double tienDichVu;
  final double tongDoanhThu;

  HouseRevenueDetail({
    required this.nhaTroId,
    required this.tenNha,
    required this.tienCoc,
    required this.tienNha,
    required this.tienDichVu,
    required this.tongDoanhThu,
  });

  factory HouseRevenueDetail.fromJson(Map<String, dynamic> json) {
    return HouseRevenueDetail(
      nhaTroId: json['nhaTroId'] ?? 0,
      tenNha: json['tenNha'] ?? '',
      tienCoc: (json['tienCoc'] ?? 0).toDouble(),
      tienNha: (json['tienNha'] ?? 0).toDouble(),
      tienDichVu: (json['tienDichVu'] ?? 0).toDouble(),
      tongDoanhThu: (json['tongDoanhThu'] ?? 0).toDouble(),
    );
  }
}

class MonthlyRevenueDetail {
  final int thang;
  final double tienCoc;
  final double tienNha;
  final double tienDichVu;
  final double tongDoanhThu;

  MonthlyRevenueDetail({
    required this.thang,
    required this.tienCoc,
    required this.tienNha,
    required this.tienDichVu,
    required this.tongDoanhThu,
  });

  factory MonthlyRevenueDetail.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueDetail(
      thang: json['thang'] ?? 0,
      tienCoc: (json['tienCoc'] ?? 0).toDouble(),
      tienNha: (json['tienNha'] ?? 0).toDouble(),
      tienDichVu: (json['tienDichVu'] ?? 0).toDouble(),
      tongDoanhThu: (json['tongDoanhThu'] ?? 0).toDouble(),
    );
  }
}

class Comparison {
  final int thangSoSanh;
  final int namSoSanh;
  final double doanhThuKyTruoc;
  final double chenhLech;
  final String tiLeTangGiam;

  Comparison({
    required this.thangSoSanh,
    required this.namSoSanh,
    required this.doanhThuKyTruoc,
    required this.chenhLech,
    required this.tiLeTangGiam,
  });

  factory Comparison.fromJson(Map<String, dynamic> json) {
    return Comparison(
      thangSoSanh: json['thangSoSanh'] ?? 0,
      namSoSanh: json['namSoSanh'] ?? 0,
      doanhThuKyTruoc: (json['doanhThuKyTruoc'] ?? 0).toDouble(),
      chenhLech: (json['chenhLech'] ?? 0).toDouble(),
      tiLeTangGiam: json['tiLeTangGiam'] ?? '',
    );
  }
}
