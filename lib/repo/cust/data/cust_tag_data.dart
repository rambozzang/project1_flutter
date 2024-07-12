// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CustTagData {
  String? custId;
  String? tagNm;
  String? tagType;
  String? lat;
  String? lon;
  String? addr;
  CustTagData({
    this.custId,
    this.tagNm,
    this.tagType,
    this.lat,
    this.lon,
    this.addr,
  });

  CustTagData copyWith({
    String? custId,
    String? tagNm,
    String? tagType,
    String? lat,
    String? lon,
    String? addr,
  }) {
    return CustTagData(
      custId: custId ?? this.custId,
      tagNm: tagNm ?? this.tagNm,
      tagType: tagType ?? this.tagType,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      addr: addr ?? this.addr,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'custId': custId,
      'tagNm': tagNm,
      'tagType': tagType,
      'lat': lat,
      'lon': lon,
      'addr': addr,
    };
  }

  factory CustTagData.fromMap(Map<String, dynamic> map) {
    return CustTagData(
      custId: map['custId'] != null ? map['custId'] as String : null,
      tagNm: map['tagNm'] != null ? map['tagNm'] as String : null,
      tagType: map['tagType'] != null ? map['tagType'] as String : null,
      lat: map['lat'] != null ? map['lat'] as String : null,
      lon: map['lon'] != null ? map['lon'] as String : null,
      addr: map['addr'] != null ? map['addr'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustTagData.fromJson(String source) => CustTagData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CustTagData(custId: $custId, tagNm: $tagNm, tagType: $tagType, lat: $lat, lon: $lon, addr: $addr)';
  }

  @override
  bool operator ==(covariant CustTagData other) {
    if (identical(this, other)) return true;

    return other.custId == custId &&
        other.tagNm == tagNm &&
        other.tagType == tagType &&
        other.lat == lat &&
        other.lon == lon &&
        other.addr == addr;
  }

  @override
  int get hashCode {
    return custId.hashCode ^ tagNm.hashCode ^ tagType.hashCode ^ lat.hashCode ^ lon.hashCode ^ addr.hashCode;
  }
}
