// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/paging_data.dart';

class BoardMainData {
  PagingData? pageData;
  List<BoardDetailData>? boardDetailList;
  BoardMainData({
    this.pageData,
    this.boardDetailList,
  });

  BoardMainData copyWith({
    PagingData? pageData,
    List<BoardDetailData>? boardInfoList,
  }) {
    return BoardMainData(
      pageData: pageData ?? this.pageData,
      boardDetailList: boardInfoList ?? this.boardDetailList,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pageData': pageData?.toMap(),
      'boardInfoList': boardDetailList!.map((x) => x?.toMap()).toList(),
    };
  }

  factory BoardMainData.fromMap(Map<String, dynamic> map) {
    return BoardMainData(
      pageData: map['pageData'] != null ? PagingData.fromMap(map['pageData'] as Map<String, dynamic>) : null,
      boardDetailList: map['boardInfoList'] != null
          ? List<BoardDetailData>.from(
              (map['boardInfoList'] as List).map<BoardDetailData?>(
                (x) => BoardDetailData.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardMainData.fromJson(String source) => BoardMainData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'NotiData(pageData: $pageData, boardInfoList: $boardDetailList)';

  @override
  bool operator ==(covariant BoardMainData other) {
    if (identical(this, other)) return true;

    return other.pageData == pageData && listEquals(other.boardDetailList, boardDetailList);
  }

  @override
  int get hashCode => pageData.hashCode ^ boardDetailList.hashCode;
}
