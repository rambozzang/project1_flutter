// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CampingReqData {
  String? serviceKey;
  String? numOfRows;
  String? pageNo;
  String? MobileOS;
  String? MobileApp;
  String? keyword;
  CampingReqData({
    this.serviceKey,
    this.numOfRows,
    this.pageNo,
    this.MobileOS,
    this.MobileApp,
    this.keyword,
  });

  CampingReqData copyWith({
    String? serviceKey,
    String? numOfRows,
    String? pageNo,
    String? MobileOS,
    String? MobileApp,
    String? keyword,
  }) {
    return CampingReqData(
      serviceKey: serviceKey ?? this.serviceKey,
      numOfRows: numOfRows ?? this.numOfRows,
      pageNo: pageNo ?? this.pageNo,
      MobileOS: MobileOS ?? this.MobileOS,
      MobileApp: MobileApp ?? this.MobileApp,
      keyword: keyword ?? this.keyword,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceKey': serviceKey,
      'numOfRows': numOfRows,
      'pageNo': pageNo,
      'MobileOS': MobileOS,
      'MobileApp': MobileApp,
      'keyword': keyword,
    };
  }

  factory CampingReqData.fromMap(Map<String, dynamic> map) {
    return CampingReqData(
      serviceKey: map['serviceKey'] != null ? map['serviceKey'] as String : null,
      numOfRows: map['numOfRows'] != null ? map['numOfRows'] as String : null,
      pageNo: map['pageNo'] != null ? map['pageNo'] as String : null,
      MobileOS: map['MobileOS'] != null ? map['MobileOS'] as String : null,
      MobileApp: map['MobileApp'] != null ? map['MobileApp'] as String : null,
      keyword: map['keyword'] != null ? map['keyword'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CampingReqData.fromJson(String source) => CampingReqData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CampingReqData(serviceKey: $serviceKey, numOfRows: $numOfRows, pageNo: $pageNo, MobileOS: $MobileOS, MobileApp: $MobileApp, keyword: $keyword)';
  }

  @override
  bool operator ==(covariant CampingReqData other) {
    if (identical(this, other)) return true;

    return other.serviceKey == serviceKey &&
        other.numOfRows == numOfRows &&
        other.pageNo == pageNo &&
        other.MobileOS == MobileOS &&
        other.MobileApp == MobileApp &&
        other.keyword == keyword;
  }

  @override
  int get hashCode {
    return serviceKey.hashCode ^ numOfRows.hashCode ^ pageNo.hashCode ^ MobileOS.hashCode ^ MobileApp.hashCode ^ keyword.hashCode;
  }
}
