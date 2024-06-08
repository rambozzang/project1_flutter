// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:project1/repo/cust/data/cust_data.dart';

class CustCountData {
  int? followCnt;
  int? followerCnt;
  int? boardCnt;
  int? likeCnt;
  CustData? custInfo;
  CustCountData({
    this.followCnt,
    this.followerCnt,
    this.boardCnt,
    this.likeCnt,
    this.custInfo,
  });

  CustCountData copyWith({
    int? followCnt,
    int? followerCnt,
    int? boardCnt,
    int? likeCnt,
    CustData? custInfo,
  }) {
    return CustCountData(
      followCnt: followCnt ?? this.followCnt,
      followerCnt: followerCnt ?? this.followerCnt,
      boardCnt: boardCnt ?? this.boardCnt,
      likeCnt: likeCnt ?? this.likeCnt,
      custInfo: custInfo ?? this.custInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'followCnt': followCnt,
      'followerCnt': followerCnt,
      'boardCnt': boardCnt,
      'likeCnt': likeCnt,
      'custInfo': custInfo?.toMap(),
    };
  }

  factory CustCountData.fromMap(Map<String, dynamic> map) {
    return CustCountData(
      followCnt: map['followCnt'] != null ? map['followCnt'] as int : null,
      followerCnt: map['followerCnt'] != null ? map['followerCnt'] as int : null,
      boardCnt: map['boardCnt'] != null ? map['boardCnt'] as int : null,
      likeCnt: map['likeCnt'] != null ? map['likeCnt'] as int : null,
      custInfo: map['custInfo'] != null ? CustData.fromMap(map['custInfo'] as Map<String, dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustCountData.fromJson(String source) => CustCountData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CustCountData(followCnt: $followCnt, followerCnt: $followerCnt, boardCnt: $boardCnt, likeCnt: $likeCnt, custInfo: $custInfo)';
  }

  @override
  bool operator ==(covariant CustCountData other) {
    if (identical(this, other)) return true;

    return other.followCnt == followCnt &&
        other.followerCnt == followerCnt &&
        other.boardCnt == boardCnt &&
        other.likeCnt == likeCnt &&
        other.custInfo == custInfo;
  }

  @override
  int get hashCode {
    return followCnt.hashCode ^ followerCnt.hashCode ^ boardCnt.hashCode ^ likeCnt.hashCode ^ custInfo.hashCode;
  }
}
