/// 내 제보 / 운영자 승인목록 아이템 (상태 포함).
/// GET /api/spot/my, /api/spot/pending 응답.
class SpotAdminData {
  int? spotId;
  String? name;
  String? category; // camping | fishing | golf
  double? lat;
  double? lon;
  String? addr;
  String? status; // PENDING | APPROVED | REJECTED
  String? rejectReason;
  String? crtCustId;
  String? crtDtm;

  SpotAdminData({
    this.spotId,
    this.name,
    this.category,
    this.lat,
    this.lon,
    this.addr,
    this.status,
    this.rejectReason,
    this.crtCustId,
    this.crtDtm,
  });

  /// 상태 한글 라벨
  String get statusLabel {
    switch (status) {
      case 'APPROVED':
        return '승인됨';
      case 'REJECTED':
        return '반려됨';
      case 'PENDING':
      default:
        return '승인 대기';
    }
  }

  /// 카테고리 한글 라벨
  String get categoryLabel {
    switch (category) {
      case 'camping':
        return '캠핑';
      case 'fishing':
        return '낚시';
      case 'golf':
        return '골프';
      default:
        return category ?? '';
    }
  }

  factory SpotAdminData.fromMap(Map<String, dynamic> map) {
    double? toD(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    int? toI(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
    return SpotAdminData(
      spotId: toI(map['spotId']),
      name: map['name']?.toString(),
      category: map['category']?.toString(),
      lat: toD(map['lat']),
      lon: toD(map['lon']),
      addr: map['addr']?.toString(),
      status: map['status']?.toString(),
      rejectReason: map['rejectReason']?.toString(),
      crtCustId: map['crtCustId']?.toString(),
      crtDtm: map['crtDtm']?.toString(),
    );
  }
}
