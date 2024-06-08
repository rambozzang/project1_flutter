// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class MistData {
  int? totalCount;
  int? pageNo;
  int? numOfRows;
  List<MistItemData>? items;
  MistData({
    this.totalCount,
    this.pageNo,
    this.numOfRows,
    this.items,
  });

  MistData copyWith({
    int? totalCount,
    int? pageNo,
    int? numOfRows,
    List<MistItemData>? items,
  }) {
    return MistData(
      totalCount: totalCount ?? this.totalCount,
      pageNo: pageNo ?? this.pageNo,
      numOfRows: numOfRows ?? this.numOfRows,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalCount': totalCount,
      'pageNo': pageNo,
      'numOfRows': numOfRows,
      'items': items!.map((x) => x?.toMap()).toList(),
    };
  }

  factory MistData.fromMap(Map<String, dynamic> map) {
    return MistData(
      totalCount: map['totalCount'] != null ? map['totalCount'] as int : null,
      pageNo: map['pageNo'] != null ? map['pageNo'] as int : null,
      numOfRows: map['numOfRows'] != null ? map['numOfRows'] as int : null,
      items: map['items'] != null
          ? List<MistItemData>.from(
              (map['items'] as List).map<MistItemData?>(
                (x) => MistItemData.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MistData.fromJson(String source) => MistData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MistData(totalCount: $totalCount, pageNo: $pageNo, numOfRows: $numOfRows, items: $items)';
  }

  @override
  bool operator ==(covariant MistData other) {
    if (identical(this, other)) return true;

    return other.totalCount == totalCount && other.pageNo == pageNo && other.numOfRows == numOfRows && listEquals(other.items, items);
  }

  @override
  int get hashCode {
    return totalCount.hashCode ^ pageNo.hashCode ^ numOfRows.hashCode ^ items.hashCode;
  }
}

class MistHeader {
  int? resultCode;
  String? resultMsg;
  MistHeader({
    this.resultCode,
    this.resultMsg,
  });

  MistHeader copyWith({
    int? resultCode,
    String? resultMsg,
  }) {
    return MistHeader(
      resultCode: resultCode ?? this.resultCode,
      resultMsg: resultMsg ?? this.resultMsg,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'resultCode': resultCode,
      'resultMsg': resultMsg,
    };
  }

  factory MistHeader.fromMap(Map<String, dynamic> map) {
    return MistHeader(
      resultCode: map['resultCode'] != null ? map['resultCode'] as int : null,
      resultMsg: map['resultMsg'] != null ? map['resultMsg'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MistHeader.fromJson(String source) => MistHeader.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'MistHeader(resultCode: $resultCode, resultMsg: $resultMsg)';

  @override
  bool operator ==(covariant MistHeader other) {
    if (identical(this, other)) return true;

    return other.resultCode == resultCode && other.resultMsg == resultMsg;
  }

  @override
  int get hashCode => resultCode.hashCode ^ resultMsg.hashCode;
}

class MistItemData {
  String? so2Grade;
  String? coFlag;
  String? khaiValue;
  String? so2Value;
  String? coValue;
  String? pm25Flag;
  String? pm10Flag;
  String? pm10Value;
  String? o3Grade;
  String? khaiGrade;
  String? pm25Value;
  String? no2Flag;
  String? no2Grade;
  String? o3Flag;
  String? pm25Grade;
  String? so2Flag;
  String? dataTime;
  String? coGrade;
  String? no2Value;
  String? pm10Grade;
  String? o3Value;
  MistItemData({
    this.so2Grade,
    this.coFlag,
    this.khaiValue,
    this.so2Value,
    this.coValue,
    this.pm25Flag,
    this.pm10Flag,
    this.pm10Value,
    this.o3Grade,
    this.khaiGrade,
    this.pm25Value,
    this.no2Flag,
    this.no2Grade,
    this.o3Flag,
    this.pm25Grade,
    this.so2Flag,
    this.dataTime,
    this.coGrade,
    this.no2Value,
    this.pm10Grade,
    this.o3Value,
  });

  MistItemData copyWith({
    String? so2Grade,
    String? coFlag,
    String? khaiValue,
    String? so2Value,
    String? coValue,
    String? pm25Flag,
    String? pm10Flag,
    String? pm10Value,
    String? o3Grade,
    String? khaiGrade,
    String? pm25Value,
    String? no2Flag,
    String? no2Grade,
    String? o3Flag,
    String? pm25Grade,
    String? so2Flag,
    String? dataTime,
    String? coGrade,
    String? no2Value,
    String? pm10Grade,
    String? o3Value,
  }) {
    return MistItemData(
      so2Grade: so2Grade ?? this.so2Grade,
      coFlag: coFlag ?? this.coFlag,
      khaiValue: khaiValue ?? this.khaiValue,
      so2Value: so2Value ?? this.so2Value,
      coValue: coValue ?? this.coValue,
      pm25Flag: pm25Flag ?? this.pm25Flag,
      pm10Flag: pm10Flag ?? this.pm10Flag,
      pm10Value: pm10Value ?? this.pm10Value,
      o3Grade: o3Grade ?? this.o3Grade,
      khaiGrade: khaiGrade ?? this.khaiGrade,
      pm25Value: pm25Value ?? this.pm25Value,
      no2Flag: no2Flag ?? this.no2Flag,
      no2Grade: no2Grade ?? this.no2Grade,
      o3Flag: o3Flag ?? this.o3Flag,
      pm25Grade: pm25Grade ?? this.pm25Grade,
      so2Flag: so2Flag ?? this.so2Flag,
      dataTime: dataTime ?? this.dataTime,
      coGrade: coGrade ?? this.coGrade,
      no2Value: no2Value ?? this.no2Value,
      pm10Grade: pm10Grade ?? this.pm10Grade,
      o3Value: o3Value ?? this.o3Value,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'so2Grade': so2Grade,
      'coFlag': coFlag,
      'khaiValue': khaiValue,
      'so2Value': so2Value,
      'coValue': coValue,
      'pm25Flag': pm25Flag,
      'pm10Flag': pm10Flag,
      'pm10Value': pm10Value,
      'o3Grade': o3Grade,
      'khaiGrade': khaiGrade,
      'pm25Value': pm25Value,
      'no2Flag': no2Flag,
      'no2Grade': no2Grade,
      'o3Flag': o3Flag,
      'pm25Grade': pm25Grade,
      'so2Flag': so2Flag,
      'dataTime': dataTime,
      'coGrade': coGrade,
      'no2Value': no2Value,
      'pm10Grade': pm10Grade,
      'o3Value': o3Value,
    };
  }

  factory MistItemData.fromMap(Map<String, dynamic> map) {
    return MistItemData(
      so2Grade: map['so2Grade'] != null ? map['so2Grade'] as String : null,
      coFlag: map['coFlag'] != null ? map['coFlag'] as String : null,
      khaiValue: map['khaiValue'] != null ? map['khaiValue'] as String : null,
      so2Value: map['so2Value'] != null ? map['so2Value'] as String : null,
      coValue: map['coValue'] != null ? map['coValue'] as String : null,
      pm25Flag: map['pm25Flag'] != null ? map['pm25Flag'] as String : null,
      pm10Flag: map['pm10Flag'] != null ? map['pm10Flag'] as String : null,
      pm10Value: map['pm10Value'] != null ? map['pm10Value'] as String : null,
      o3Grade: map['o3Grade'] != null ? map['o3Grade'] as String : null,
      khaiGrade: map['khaiGrade'] != null ? map['khaiGrade'] as String : null,
      pm25Value: map['pm25Value'] != null ? map['pm25Value'] as String : null,
      no2Flag: map['no2Flag'] != null ? map['no2Flag'] as String : null,
      no2Grade: map['no2Grade'] != null ? map['no2Grade'] as String : null,
      o3Flag: map['o3Flag'] != null ? map['o3Flag'] as String : null,
      pm25Grade: map['pm25Grade'] != null ? map['pm25Grade'] as String : null,
      so2Flag: map['so2Flag'] != null ? map['so2Flag'] as String : null,
      dataTime: map['dataTime'] != null ? map['dataTime'] as String : null,
      coGrade: map['coGrade'] != null ? map['coGrade'] as String : null,
      no2Value: map['no2Value'] != null ? map['no2Value'] as String : null,
      pm10Grade: map['pm10Grade'] != null ? map['pm10Grade'] as String : null,
      o3Value: map['o3Value'] != null ? map['o3Value'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MistItemData.fromJson(String source) => MistItemData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MistItemData(so2Grade: $so2Grade, coFlag: $coFlag, khaiValue: $khaiValue, so2Value: $so2Value, coValue: $coValue, pm25Flag: $pm25Flag, pm10Flag: $pm10Flag, pm10Value: $pm10Value, o3Grade: $o3Grade, khaiGrade: $khaiGrade, pm25Value: $pm25Value, no2Flag: $no2Flag, no2Grade: $no2Grade, o3Flag: $o3Flag, pm25Grade: $pm25Grade, so2Flag: $so2Flag, dataTime: $dataTime, coGrade: $coGrade, no2Value: $no2Value, pm10Grade: $pm10Grade, o3Value: $o3Value)';
  }

  @override
  bool operator ==(covariant MistItemData other) {
    if (identical(this, other)) return true;

    return other.so2Grade == so2Grade &&
        other.coFlag == coFlag &&
        other.khaiValue == khaiValue &&
        other.so2Value == so2Value &&
        other.coValue == coValue &&
        other.pm25Flag == pm25Flag &&
        other.pm10Flag == pm10Flag &&
        other.pm10Value == pm10Value &&
        other.o3Grade == o3Grade &&
        other.khaiGrade == khaiGrade &&
        other.pm25Value == pm25Value &&
        other.no2Flag == no2Flag &&
        other.no2Grade == no2Grade &&
        other.o3Flag == o3Flag &&
        other.pm25Grade == pm25Grade &&
        other.so2Flag == so2Flag &&
        other.dataTime == dataTime &&
        other.coGrade == coGrade &&
        other.no2Value == no2Value &&
        other.pm10Grade == pm10Grade &&
        other.o3Value == o3Value;
  }

  @override
  int get hashCode {
    return so2Grade.hashCode ^
        coFlag.hashCode ^
        khaiValue.hashCode ^
        so2Value.hashCode ^
        coValue.hashCode ^
        pm25Flag.hashCode ^
        pm10Flag.hashCode ^
        pm10Value.hashCode ^
        o3Grade.hashCode ^
        khaiGrade.hashCode ^
        pm25Value.hashCode ^
        no2Flag.hashCode ^
        no2Grade.hashCode ^
        o3Flag.hashCode ^
        pm25Grade.hashCode ^
        so2Flag.hashCode ^
        dataTime.hashCode ^
        coGrade.hashCode ^
        no2Value.hashCode ^
        pm10Grade.hashCode ^
        o3Value.hashCode;
  }
}
