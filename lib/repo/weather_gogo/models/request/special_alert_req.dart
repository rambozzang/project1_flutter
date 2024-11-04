// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class SpecialAlertReq {
  final String serviceKey;
  final String dataType;
  final int numOfRows;
  final int pageNo;
  final String stnId;
  final String fromTmFc;
  final String toTmFc;
  SpecialAlertReq({
    required this.serviceKey,
    required this.dataType,
    required this.numOfRows,
    required this.pageNo,
    required this.stnId,
    required this.fromTmFc,
    required this.toTmFc,
  });

  SpecialAlertReq copyWith({
    String? serviceKey,
    String? dataType,
    int? numOfRows,
    int? pageNo,
    String? stnId,
    String? fromTmFc,
    String? toTmFc,
  }) {
    return SpecialAlertReq(
      serviceKey: serviceKey ?? this.serviceKey,
      dataType: dataType ?? this.dataType,
      numOfRows: numOfRows ?? this.numOfRows,
      pageNo: pageNo ?? this.pageNo,
      stnId: stnId ?? this.stnId,
      fromTmFc: fromTmFc ?? this.fromTmFc,
      toTmFc: toTmFc ?? this.toTmFc,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceKey': serviceKey.toString(),
      'dataType': dataType.toString(),
      'numOfRows': numOfRows.toString(),
      'pageNo': pageNo.toString(),
      'stnId': stnId.toString(),
      'fromTmFc': fromTmFc.toString(),
      'toTmFc': toTmFc.toString(),
    };
  }

  factory SpecialAlertReq.fromMap(Map<String, dynamic> map) {
    return SpecialAlertReq(
      serviceKey: map['serviceKey'] as String,
      dataType: map['dataType'] as String,
      numOfRows: map['numOfRows'] as int,
      pageNo: map['pageNo'] as int,
      stnId: map['stnId'] as String,
      fromTmFc: map['fromTmFc'] as String,
      toTmFc: map['toTmFc'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SpecialAlertReq.fromJson(String source) => SpecialAlertReq.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SpecialAlertReq(serviceKey: $serviceKey, dataType: $dataType, numOfRows: $numOfRows, pageNo: $pageNo, stnId: $stnId, fromTmFc: $fromTmFc, toTmFc: $toTmFc)';
  }

  @override
  bool operator ==(covariant SpecialAlertReq other) {
    if (identical(this, other)) return true;

    return other.serviceKey == serviceKey &&
        other.dataType == dataType &&
        other.numOfRows == numOfRows &&
        other.pageNo == pageNo &&
        other.stnId == stnId &&
        other.fromTmFc == fromTmFc &&
        other.toTmFc == toTmFc;
  }

  @override
  int get hashCode {
    return serviceKey.hashCode ^
        dataType.hashCode ^
        numOfRows.hashCode ^
        pageNo.hashCode ^
        stnId.hashCode ^
        fromTmFc.hashCode ^
        toTmFc.hashCode;
  }
}
