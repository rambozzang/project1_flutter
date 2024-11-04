// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:project1/repo/bbs/data/bbs_file_req_data.dart';

class BoardCommentData {
  String? custId;
  String? typeCd;
  String? typeDtCd;
  String? subject;
  String? contents;
  int? rootId;
  int? depthNo;
  int? parentId;
  int? sortNo;
  List<BbsFileData>? fileListData;
  BoardCommentData({
    this.custId,
    this.typeCd,
    this.typeDtCd,
    this.subject,
    this.contents,
    this.rootId,
    this.depthNo,
    this.parentId,
    this.sortNo,
    this.fileListData,
  });

  BoardCommentData copyWith({
    String? custId,
    String? typeCd,
    String? typeDtCd,
    String? subject,
    String? contents,
    int? rootId,
    int? depthNo,
    int? parentId,
    int? sortNo,
    List<BbsFileData>? fileListData,
  }) {
    return BoardCommentData(
      custId: custId ?? this.custId,
      typeCd: typeCd ?? this.typeCd,
      typeDtCd: typeDtCd ?? this.typeDtCd,
      subject: subject ?? this.subject,
      contents: contents ?? this.contents,
      rootId: rootId ?? this.rootId,
      depthNo: depthNo ?? this.depthNo,
      parentId: parentId ?? this.parentId,
      sortNo: sortNo ?? this.sortNo,
      fileListData: fileListData ?? this.fileListData,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'custId': custId,
      'typeCd': typeCd,
      'typeDtCd': typeDtCd,
      'subject': subject,
      'contents': contents,
      'rootId': rootId,
      'depthNo': depthNo,
      'parentId': parentId,
      'sortNo': sortNo,
      'fileListData': fileListData?.map((x) => x?.toMap()).toList(),
    };
  }

  factory BoardCommentData.fromMap(Map<String, dynamic> map) {
    return BoardCommentData(
      custId: map['custId'] != null ? map['custId'] as String : null,
      typeCd: map['typeCd'] != null ? map['typeCd'] as String : null,
      typeDtCd: map['typeDtCd'] != null ? map['typeDtCd'] as String : null,
      subject: map['subject'] != null ? map['subject'] as String : null,
      contents: map['contents'] != null ? map['contents'] as String : null,
      rootId: map['rootId'] != null ? map['rootId'] as int : null,
      depthNo: map['depthNo'] != null ? map['depthNo'] as int : null,
      parentId: map['parentId'] != null ? map['parentId'] as int : null,
      sortNo: map['sortNo'] != null ? map['sortNo'] as int : null,
      fileListData: map['fileListData'] != null
          ? List<BbsFileData>.from(
              (map['fileListData'] as List).map<BbsFileData?>(
                (x) => BbsFileData.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardCommentData.fromJson(String source) => BoardCommentData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardCommentData(custId: $custId, typeCd: $typeCd, typeDtCd: $typeDtCd, subject: $subject, contents: $contents, rootId: $rootId, depthNo: $depthNo, parentId: $parentId, sortNo: $sortNo, fileListData: $fileListData)';
  }

  @override
  bool operator ==(covariant BoardCommentData other) {
    if (identical(this, other)) return true;

    return other.custId == custId &&
        other.typeCd == typeCd &&
        other.typeDtCd == typeDtCd &&
        other.subject == subject &&
        other.contents == contents &&
        other.rootId == rootId &&
        other.depthNo == depthNo &&
        other.parentId == parentId &&
        other.sortNo == sortNo &&
        listEquals(other.fileListData, fileListData);
  }

  @override
  int get hashCode {
    return custId.hashCode ^
        typeCd.hashCode ^
        typeDtCd.hashCode ^
        subject.hashCode ^
        contents.hashCode ^
        rootId.hashCode ^
        depthNo.hashCode ^
        parentId.hashCode ^
        sortNo.hashCode ^
        fileListData.hashCode;
  }
}
