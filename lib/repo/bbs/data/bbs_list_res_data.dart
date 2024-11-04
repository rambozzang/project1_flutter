// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:project1/repo/bbs/data/bbs_file_data_res.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/bbs/data/bbs_list_paging.dart';

class BbsListResData {
  BbsListPaging pageData;
  List<BbsListData> bbsList;
  BbsListResData({
    required this.pageData,
    required this.bbsList,
  });

  BbsListResData copyWith({
    BbsListPaging? pageData,
    List<BbsListData>? bbsList,
  }) {
    return BbsListResData(
      pageData: pageData ?? this.pageData,
      bbsList: bbsList ?? this.bbsList,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pageData': pageData.toMap(),
      'bbsList': bbsList.map((x) => x.toMap()).toList(),
    };
  }

  factory BbsListResData.fromMap(Map<String, dynamic> map) {
    return BbsListResData(
      pageData: BbsListPaging.fromMap(map['pageData'] as Map<String, dynamic>),
      bbsList: List<BbsListData>.from(
        (map['bbsList'] as List).map<BbsListData>(
          (x) => BbsListData.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory BbsListResData.fromJson(String source) => BbsListResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'BbsListResData(pageData: $pageData, bbsList: $bbsList)';

  @override
  bool operator ==(covariant BbsListResData other) {
    if (identical(this, other)) return true;

    return other.pageData == pageData && listEquals(other.bbsList, bbsList);
  }

  @override
  int get hashCode => pageData.hashCode ^ bbsList.hashCode;
}
