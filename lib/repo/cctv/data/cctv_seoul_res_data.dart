// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CctvSeoulResData {
  String? cctvname;
  String? centername;
  String? cctvid;
  String? xcoord;
  String? ycoord;
  int? seq;
  String? crtDtm;
  CctvSeoulResData({
    this.cctvname,
    this.centername,
    this.cctvid,
    this.xcoord,
    this.ycoord,
    this.seq,
    this.crtDtm,
  });

  CctvSeoulResData copyWith({
    String? cctvname,
    String? centername,
    String? cctvid,
    String? xcoord,
    String? ycoord,
    int? seq,
    String? crtDtm,
  }) {
    return CctvSeoulResData(
      cctvname: cctvname ?? this.cctvname,
      centername: centername ?? this.centername,
      cctvid: cctvid ?? this.cctvid,
      xcoord: xcoord ?? this.xcoord,
      ycoord: ycoord ?? this.ycoord,
      seq: seq ?? this.seq,
      crtDtm: crtDtm ?? this.crtDtm,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cctvname': cctvname,
      'centername': centername,
      'cctvid': cctvid,
      'xcoord': xcoord,
      'ycoord': ycoord,
      'seq': seq,
      'crtDtm': crtDtm,
    };
  }

  factory CctvSeoulResData.fromMap(Map<String, dynamic> map) {
    return CctvSeoulResData(
      cctvname: map['cctvname'] != null ? map['cctvname'] as String : null,
      centername: map['centername'] != null ? map['centername'] as String : null,
      cctvid: map['cctvid'] != null ? map['cctvid'] as String : null,
      xcoord: map['xcoord'] != null ? map['xcoord'] as String : null,
      ycoord: map['ycoord'] != null ? map['ycoord'] as String : null,
      seq: map['seq'] != null ? map['seq'] as int : null,
      crtDtm: map['crtDtm'] != null ? map['crtDtm'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CctvSeoulResData.fromJson(String source) => CctvSeoulResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CctvSeoulResData(cctvname: $cctvname, centername: $centername, cctvid: $cctvid, xcoord: $xcoord, ycoord: $ycoord, seq: $seq, crtDtm: $crtDtm)';
  }

  @override
  bool operator ==(covariant CctvSeoulResData other) {
    if (identical(this, other)) return true;

    return other.cctvname == cctvname &&
        other.centername == centername &&
        other.cctvid == cctvid &&
        other.xcoord == xcoord &&
        other.ycoord == ycoord &&
        other.seq == seq &&
        other.crtDtm == crtDtm;
  }

  @override
  int get hashCode {
    return cctvname.hashCode ^ centername.hashCode ^ cctvid.hashCode ^ xcoord.hashCode ^ ycoord.hashCode ^ seq.hashCode ^ crtDtm.hashCode;
  }
}
