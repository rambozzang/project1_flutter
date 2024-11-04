// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:project1/repo/bbs/data/bbs_file_req_data.dart';

class BbsRegisterData {
  String typeCd;
  String typeDtCd;
  String depthNo;
  String boardId;
  String title;
  String contents;
  int parentId;
  List<BbsFileData> fileListData;
  BbsRegisterData({
    required this.typeCd,
    required this.typeDtCd,
    required this.depthNo,
    required this.boardId,
    required this.title,
    required this.contents,
    required this.parentId,
    required this.fileListData,
  });

  BbsRegisterData copyWith({
    String? typeCd,
    String? typeDtCd,
    String? depthNo,
    String? boardId,
    String? title,
    String? contents,
    int? parentId,
    List<BbsFileData>? fileListData,
  }) {
    return BbsRegisterData(
      typeCd: typeCd ?? this.typeCd,
      typeDtCd: typeDtCd ?? this.typeDtCd,
      depthNo: depthNo ?? this.depthNo,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      contents: contents ?? this.contents,
      parentId: parentId ?? this.parentId,
      fileListData: fileListData ?? this.fileListData,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'typeCd': typeCd,
      'typeDtCd': typeDtCd,
      'depthNo': depthNo,
      'boardId': boardId,
      'title': title,
      'contents': contents,
      'parentId': parentId,
      'fileListData': fileListData.map((x) => x.toMap()).toList(),
    };
  }

  factory BbsRegisterData.fromMap(Map<String, dynamic> map) {
    return BbsRegisterData(
      typeCd: map['typeCd'] as String,
      typeDtCd: map['typeDtCd'] as String,
      depthNo: map['depthNo'] as String,
      boardId: map['boardId'] as String,
      title: map['title'] as String,
      contents: map['contents'] as String,
      parentId: map['parentId'] as int,
      fileListData: List<BbsFileData>.from(
        (map['fileListData'] as List).map<BbsFileData>(
          (x) => BbsFileData.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory BbsRegisterData.fromJson(String source) => BbsRegisterData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BbsRegisterData(typeCd: $typeCd, typeDtCd: $typeDtCd, depthNo: $depthNo, boardId: $boardId, title: $title, contents: $contents, parentId: $parentId, fileListData: $fileListData)';
  }

  @override
  bool operator ==(covariant BbsRegisterData other) {
    if (identical(this, other)) return true;

    return other.typeCd == typeCd &&
        other.typeDtCd == typeDtCd &&
        other.depthNo == depthNo &&
        other.boardId == boardId &&
        other.title == title &&
        other.contents == contents &&
        other.parentId == parentId &&
        listEquals(other.fileListData, fileListData);
  }

  @override
  int get hashCode {
    return typeCd.hashCode ^
        typeDtCd.hashCode ^
        depthNo.hashCode ^
        boardId.hashCode ^
        title.hashCode ^
        contents.hashCode ^
        parentId.hashCode ^
        fileListData.hashCode;
  }
}
