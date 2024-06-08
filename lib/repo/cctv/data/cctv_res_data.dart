// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CctvResData {
  String? coordtype;
  int? datacount;
  String? roadsectionid;
  String? filecreatetime;
  String? cctvtype; //  CCTV 유형(1: 실시간 스트리밍(HLS) / 2: 동영상 파일 / 3: 정지 영상)
  String? cctvurl;
  String? cctvresolution;
  String? coordx;
  String? coordy;
  String? cctvformat;
  String? cctvname;
  double? km;

  CctvResData({
    this.coordtype,
    this.datacount,
    this.roadsectionid,
    this.filecreatetime,
    this.cctvtype,
    this.cctvurl,
    this.cctvresolution,
    this.coordx,
    this.coordy,
    this.cctvformat,
    this.cctvname,
    this.km,
  });

  CctvResData copyWith({
    String? coordtype,
    int? datacount,
    String? roadsectionid,
    String? filecreatetime,
    String? cctvtype,
    String? cctvurl,
    String? cctvresolution,
    String? coordx,
    String? coordy,
    String? cctvformat,
    String? cctvname,
    double? km,
  }) {
    return CctvResData(
      coordtype: coordtype ?? this.coordtype,
      datacount: datacount ?? this.datacount,
      roadsectionid: roadsectionid ?? this.roadsectionid,
      filecreatetime: filecreatetime ?? this.filecreatetime,
      cctvtype: cctvtype ?? this.cctvtype,
      cctvurl: cctvurl ?? this.cctvurl,
      cctvresolution: cctvresolution ?? this.cctvresolution,
      coordx: coordx ?? this.coordx,
      coordy: coordy ?? this.coordy,
      cctvformat: cctvformat ?? this.cctvformat,
      cctvname: cctvname ?? this.cctvname,
      km: km ?? this.km,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'coordtype': coordtype,
      'datacount': datacount,
      'roadsectionid': roadsectionid,
      'filecreatetime': filecreatetime,
      'cctvtype': cctvtype,
      'cctvurl': cctvurl,
      'cctvresolution': cctvresolution,
      'coordx': coordx,
      'coordy': coordy,
      'cctvformat': cctvformat,
      'cctvname': cctvname,
      'km': km,
    };
  }

  factory CctvResData.fromMap(Map<String, dynamic> map) {
    return CctvResData(
      coordtype: map['coordtype'] != null ? map['coordtype'] as String : null,
      datacount: map['datacount'] != null ? map['datacount'] as int : null,
      roadsectionid: map['roadsectionid'] != null ? map['roadsectionid'] as String : null,
      filecreatetime: map['filecreatetime'] != null ? map['filecreatetime'] as String : null,
      cctvtype: map['cctvtype'] != null ? map['cctvtype'] as String : null,
      cctvurl: map['cctvurl'] != null ? map['cctvurl'] as String : null,
      cctvresolution: map['cctvresolution'] != null ? map['cctvresolution'] as String : null,
      coordx: map['coordx'] != null ? map['coordx'] as String : null,
      coordy: map['coordy'] != null ? map['coordy'] as String : null,
      cctvformat: map['cctvformat'] != null ? map['cctvformat'] as String : null,
      cctvname: map['cctvname'] != null ? map['cctvname'] as String : null,
      km: map['km'] != null ? map['km'] as double : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CctvResData.fromJson(String source) => CctvResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CctvResData(coordtype: $coordtype, datacount: $datacount, roadsectionid: $roadsectionid, filecreatetime: $filecreatetime, cctvtype: $cctvtype, cctvurl: $cctvurl, cctvresolution: $cctvresolution, coordx: $coordx, coordy: $coordy, cctvformat: $cctvformat, cctvname: $cctvname, km: $km)';
  }

  @override
  bool operator ==(covariant CctvResData other) {
    if (identical(this, other)) return true;

    return other.coordtype == coordtype &&
        other.datacount == datacount &&
        other.roadsectionid == roadsectionid &&
        other.filecreatetime == filecreatetime &&
        other.cctvtype == cctvtype &&
        other.cctvurl == cctvurl &&
        other.cctvresolution == cctvresolution &&
        other.coordx == coordx &&
        other.coordy == coordy &&
        other.cctvformat == cctvformat &&
        other.cctvname == cctvname &&
        other.km == km;
  }

  @override
  int get hashCode {
    return coordtype.hashCode ^
        datacount.hashCode ^
        roadsectionid.hashCode ^
        filecreatetime.hashCode ^
        cctvtype.hashCode ^
        cctvurl.hashCode ^
        cctvresolution.hashCode ^
        coordx.hashCode ^
        coordy.hashCode ^
        cctvformat.hashCode ^
        cctvname.hashCode ^
        km.hashCode;
  }
}
