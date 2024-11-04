// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:project1/repo/bbs/data/bbs_file_req_data.dart';

class BoardCommentUpdateReqData {
  String? boardId;
  String? delYn;
  String? hideYn;
  String? contents;
  List<BbsFileData>? fileListData;
  BoardCommentUpdateReqData({
    this.boardId,
    this.delYn,
    this.hideYn,
    this.contents,
    this.fileListData,
  });

  BoardCommentUpdateReqData copyWith({
    String? boardId,
    String? delYn,
    String? hideYn,
    String? contents,
    List<BbsFileData>? fileListData,
  }) {
    return BoardCommentUpdateReqData(
      boardId: boardId ?? this.boardId,
      delYn: delYn ?? this.delYn,
      hideYn: hideYn ?? this.hideYn,
      contents: contents ?? this.contents,
      fileListData: fileListData ?? this.fileListData,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'boardId': boardId,
      'delYn': delYn,
      'hideYn': hideYn,
      'contents': contents,
      'fileListData': fileListData!.map((x) => x?.toMap()).toList(),
    };
  }

  factory BoardCommentUpdateReqData.fromMap(Map<String, dynamic> map) {
    return BoardCommentUpdateReqData(
      boardId: map['boardId'] != null ? map['boardId'] as String : null,
      delYn: map['delYn'] != null ? map['delYn'] as String : null,
      hideYn: map['hideYn'] != null ? map['hideYn'] as String : null,
      contents: map['contents'] != null ? map['contents'] as String : null,
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

  factory BoardCommentUpdateReqData.fromJson(String source) =>
      BoardCommentUpdateReqData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardCommentUpdateReqData(boardId: $boardId, delYn: $delYn, hideYn: $hideYn, contents: $contents, fileListData: $fileListData)';
  }

  @override
  bool operator ==(covariant BoardCommentUpdateReqData other) {
    if (identical(this, other)) return true;

    return other.boardId == boardId &&
        other.delYn == delYn &&
        other.hideYn == hideYn &&
        other.contents == contents &&
        listEquals(other.fileListData, fileListData);
  }

  @override
  int get hashCode {
    return boardId.hashCode ^ delYn.hashCode ^ hideYn.hashCode ^ contents.hashCode ^ fileListData.hashCode;
  }
}
