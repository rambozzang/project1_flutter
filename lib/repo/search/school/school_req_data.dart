// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class SchoolReqData {
  String? apiKey;
  String? svcType;
  String? svcCode;
  String? contentType;
  String? gubun;
  String? region;
  String? sch1;
  String? sch2;
  String? est;
  String? thisPage;
  String? perPage;
  String? searchSchulNm;
  SchoolReqData({
    this.apiKey,
    this.svcType,
    this.svcCode,
    this.contentType,
    this.gubun,
    this.region,
    this.sch1,
    this.sch2,
    this.est,
    this.thisPage,
    this.perPage,
    this.searchSchulNm,
  });

  SchoolReqData copyWith({
    String? apiKey,
    String? svcType,
    String? svcCode,
    String? contentType,
    String? gubun,
    String? region,
    String? sch1,
    String? sch2,
    String? est,
    String? thisPage,
    String? perPage,
    String? searchSchulNm,
  }) {
    return SchoolReqData(
      apiKey: apiKey ?? this.apiKey,
      svcType: svcType ?? this.svcType,
      svcCode: svcCode ?? this.svcCode,
      contentType: contentType ?? this.contentType,
      gubun: gubun ?? this.gubun,
      region: region ?? this.region,
      sch1: sch1 ?? this.sch1,
      sch2: sch2 ?? this.sch2,
      est: est ?? this.est,
      thisPage: thisPage ?? this.thisPage,
      perPage: perPage ?? this.perPage,
      searchSchulNm: searchSchulNm ?? this.searchSchulNm,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'apiKey': apiKey,
      'svcType': svcType,
      'svcCode': svcCode,
      'contentType': contentType,
      'gubun': gubun,
      'region': region,
      'sch1': sch1,
      'sch2': sch2,
      'est': est,
      'thisPage': thisPage,
      'perPage': perPage,
      'searchSchulNm': searchSchulNm,
    };
  }

  factory SchoolReqData.fromMap(Map<String, dynamic> map) {
    return SchoolReqData(
      apiKey: map['apiKey'] != null ? map['apiKey'] as String : null,
      svcType: map['svcType'] != null ? map['svcType'] as String : null,
      svcCode: map['svcCode'] != null ? map['svcCode'] as String : null,
      contentType: map['contentType'] != null ? map['contentType'] as String : null,
      gubun: map['gubun'] != null ? map['gubun'] as String : null,
      region: map['region'] != null ? map['region'] as String : null,
      sch1: map['sch1'] != null ? map['sch1'] as String : null,
      sch2: map['sch2'] != null ? map['sch2'] as String : null,
      est: map['est'] != null ? map['est'] as String : null,
      thisPage: map['thisPage'] != null ? map['thisPage'] as String : null,
      perPage: map['perPage'] != null ? map['perPage'] as String : null,
      searchSchulNm: map['searchSchulNm'] != null ? map['searchSchulNm'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SchoolReqData.fromJson(String source) => SchoolReqData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SchoolReqData(apiKey: $apiKey, svcType: $svcType, svcCode: $svcCode, contentType: $contentType, gubun: $gubun, region: $region, sch1: $sch1, sch2: $sch2, est: $est, thisPage: $thisPage, perPage: $perPage, searchSchulNm: $searchSchulNm)';
  }

  @override
  bool operator ==(covariant SchoolReqData other) {
    if (identical(this, other)) return true;

    return other.apiKey == apiKey &&
        other.svcType == svcType &&
        other.svcCode == svcCode &&
        other.contentType == contentType &&
        other.gubun == gubun &&
        other.region == region &&
        other.sch1 == sch1 &&
        other.sch2 == sch2 &&
        other.est == est &&
        other.thisPage == thisPage &&
        other.perPage == perPage &&
        other.searchSchulNm == searchSchulNm;
  }

  @override
  int get hashCode {
    return apiKey.hashCode ^
        svcType.hashCode ^
        svcCode.hashCode ^
        contentType.hashCode ^
        gubun.hashCode ^
        region.hashCode ^
        sch1.hashCode ^
        sch2.hashCode ^
        est.hashCode ^
        thisPage.hashCode ^
        perPage.hashCode ^
        searchSchulNm.hashCode;
  }
}
