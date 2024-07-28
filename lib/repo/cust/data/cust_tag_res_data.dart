// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CustagResData {
  CustTagId? id;
  String? lat;
  String? lon;
  String? addr;
  String? crtDTM;
  CustagResData({
    this.id,
    this.lat,
    this.lon,
    this.addr,
    this.crtDTM,
  });

  CustagResData copyWith({
    CustTagId? id,
    String? lat,
    String? lon,
    String? addr,
    String? crtDTM,
  }) {
    return CustagResData(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      addr: addr ?? this.addr,
      crtDTM: crtDTM ?? this.crtDTM,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id?.toMap(),
      'lat': lat,
      'lon': lon,
      'addr': addr,
      'crtDTM': crtDTM,
    };
  }

  factory CustagResData.fromMap(Map<String, dynamic> map) {
    return CustagResData(
      id: map['id'] != null ? CustTagId.fromMap(map['id'] as Map<String, dynamic>) : null,
      lat: map['lat'] != null ? map['lat'] as String : null,
      lon: map['lon'] != null ? map['lon'] as String : null,
      addr: map['addr'] != null ? map['addr'] as String : null,
      crtDTM: map['crtDTM'] != null ? map['crtDTM'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustagResData.fromJson(String source) => CustagResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CustagResData(id: $id, lat: $lat, lon: $lon, addr: $addr, crtDTM: $crtDTM)';
  }

  @override
  bool operator ==(covariant CustagResData other) {
    if (identical(this, other)) return true;

    return other.id == id && other.lat == lat && other.lon == lon && other.addr == addr && other.crtDTM == crtDTM;
  }

  @override
  int get hashCode {
    return id.hashCode ^ lat.hashCode ^ lon.hashCode ^ addr.hashCode ^ crtDTM.hashCode;
  }
}

class CustTagId {
  String? custId;
  String? tagNm;
  String? tagType;
  CustTagId({
    this.custId,
    this.tagNm,
    this.tagType,
  });

  CustTagId copyWith({
    String? custId,
    String? tagNm,
    String? tagType,
  }) {
    return CustTagId(
      custId: custId ?? this.custId,
      tagNm: tagNm ?? this.tagNm,
      tagType: tagType ?? this.tagType,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'custId': custId,
      'tagNm': tagNm,
      'tagType': tagType,
    };
  }

  factory CustTagId.fromMap(Map<String, dynamic> map) {
    return CustTagId(
      custId: map['custId'] != null ? map['custId'] as String : null,
      tagNm: map['tagNm'] != null ? map['tagNm'] as String : null,
      tagType: map['tagType'] != null ? map['tagType'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustTagId.fromJson(String source) => CustTagId.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'CustTagId(custId: $custId, tagNm: $tagNm, tagType: $tagType)';

  @override
  bool operator ==(covariant CustTagId other) {
    if (identical(this, other)) return true;

    return other.custId == custId && other.tagNm == tagNm && other.tagType == tagType;
  }

  @override
  int get hashCode => custId.hashCode ^ tagNm.hashCode ^ tagType.hashCode;
}
