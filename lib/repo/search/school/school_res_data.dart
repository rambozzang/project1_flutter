// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class SchoolResData {
  String? totalCount;
  String? schoolName;
  String? schoolGubun;
  String? schoolType;
  String? estType;
  String? region;
  String? adres;
  String? collegeinfourl;
  String? link;
  SchoolResData({
    this.totalCount,
    this.schoolName,
    this.schoolGubun,
    this.schoolType,
    this.estType,
    this.region,
    this.adres,
    this.collegeinfourl,
    this.link,
  });

  SchoolResData copyWith({
    String? totalCount,
    String? schoolName,
    String? schoolGubun,
    String? schoolType,
    String? estType,
    String? region,
    String? adres,
    String? collegeinfourl,
    String? link,
  }) {
    return SchoolResData(
      totalCount: totalCount ?? this.totalCount,
      schoolName: schoolName ?? this.schoolName,
      schoolGubun: schoolGubun ?? this.schoolGubun,
      schoolType: schoolType ?? this.schoolType,
      estType: estType ?? this.estType,
      region: region ?? this.region,
      adres: adres ?? this.adres,
      collegeinfourl: collegeinfourl ?? this.collegeinfourl,
      link: link ?? this.link,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalCount': totalCount,
      'schoolName': schoolName,
      'schoolGubun': schoolGubun,
      'schoolType': schoolType,
      'estType': estType,
      'region': region,
      'adres': adres,
      'collegeinfourl': collegeinfourl,
      'link': link,
    };
  }

  factory SchoolResData.fromMap(Map<String, dynamic> map) {
    return SchoolResData(
      totalCount: map['totalCount'] != null ? map['totalCount'] as String : null,
      schoolName: map['schoolName'] != null ? map['schoolName'] as String : null,
      schoolGubun: map['schoolGubun'] != null ? map['schoolGubun'] as String : null,
      schoolType: map['schoolType'] != null ? map['schoolType'] as String : null,
      estType: map['estType'] != null ? map['estType'] as String : null,
      region: map['region'] != null ? map['region'] as String : null,
      adres: map['adres'] != null ? map['adres'] as String : null,
      collegeinfourl: map['collegeinfourl'] != null ? map['collegeinfourl'] as String : null,
      link: map['link'] != null ? map['link'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SchoolResData.fromJson(String source) => SchoolResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SchoolResData(totalCount: $totalCount, schoolName: $schoolName, schoolGubun: $schoolGubun, schoolType: $schoolType, estType: $estType, region: $region, adres: $adres, collegeinfourl: $collegeinfourl, link: $link)';
  }

  @override
  bool operator ==(covariant SchoolResData other) {
    if (identical(this, other)) return true;

    return other.totalCount == totalCount &&
        other.schoolName == schoolName &&
        other.schoolGubun == schoolGubun &&
        other.schoolType == schoolType &&
        other.estType == estType &&
        other.region == region &&
        other.adres == adres &&
        other.collegeinfourl == collegeinfourl &&
        other.link == link;
  }

  @override
  int get hashCode {
    return totalCount.hashCode ^
        schoolName.hashCode ^
        schoolGubun.hashCode ^
        schoolType.hashCode ^
        estType.hashCode ^
        region.hashCode ^
        adres.hashCode ^
        collegeinfourl.hashCode ^
        link.hashCode;
  }
}
