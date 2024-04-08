// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:project1/repo/board/data/board_info_data.dart';
import 'package:project1/repo/board/data/paging_data.dart';

class BoardData {
  PagingData? pageData;
  List<BoardInfoData>? boardInfoList;
  BoardData({
    this.pageData,
    this.boardInfoList,
  });

  BoardData copyWith({
    PagingData? pageData,
    List<BoardInfoData>? boardInfoList,
  }) {
    return BoardData(
      pageData: pageData ?? this.pageData,
      boardInfoList: boardInfoList ?? this.boardInfoList,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pageData': pageData?.toMap(),
      'boardInfoList': boardInfoList!.map((x) => x?.toMap()).toList(),
    };
  }

  factory BoardData.fromMap(Map<String, dynamic> map) {
    return BoardData(
      pageData: map['pageData'] != null ? PagingData.fromMap(map['pageData'] as Map<String, dynamic>) : null,
      boardInfoList: map['boardInfoList'] != null
          ? List<BoardInfoData>.from(
              (map['boardInfoList'] as List).map<BoardInfoData?>(
                (x) => BoardInfoData.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardData.fromJson(String source) => BoardData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'NotiData(pageData: $pageData, boardInfoList: $boardInfoList)';

  @override
  bool operator ==(covariant BoardData other) {
    if (identical(this, other)) return true;

    return other.pageData == pageData && listEquals(other.boardInfoList, boardInfoList);
  }

  @override
  int get hashCode => pageData.hashCode ^ boardInfoList.hashCode;
}
