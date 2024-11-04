// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:project1/repo/bbs/data/bbs_file_data_res.dart';

class BbsListData {
  String? subject;
  String? contents;
  String? profilePath;
  int? replyCnt;
  String? typeDtCd;
  String? typeDtNm;
  String? filePath;
  String? crtCustId;
  String? depthNo;
  String? sortNo;
  String? parentId;
  String? nickNm;
  String? typeCd;
  int? boardId;
  String? fileKey;
  String? crtDtm;
  String? custNm;
  String? likeYn;
  int? viewCnt;
  int? likeCnt;
  int? fileCnt;
  String? delYn;
  List<BbsFileDataRes>? fileList;
  BbsListData({
    this.subject,
    this.contents,
    this.profilePath,
    this.replyCnt,
    this.typeDtCd,
    this.typeDtNm,
    this.filePath,
    this.crtCustId,
    this.depthNo,
    this.sortNo,
    this.parentId,
    this.nickNm,
    this.typeCd,
    this.boardId,
    this.fileKey,
    this.crtDtm,
    this.custNm,
    this.likeYn,
    this.viewCnt,
    this.likeCnt,
    this.fileCnt,
    this.delYn,
    this.fileList,
  });

  BbsListData copyWith({
    String? subject,
    String? contents,
    String? profilePath,
    int? replyCnt,
    String? typeDtCd,
    String? typeDtNm,
    String? filePath,
    String? crtCustId,
    String? depthNo,
    String? sortNo,
    String? parentId,
    String? nickNm,
    String? typeCd,
    int? boardId,
    String? fileKey,
    String? crtDtm,
    String? custNm,
    String? likeYn,
    int? viewCnt,
    int? likeCnt,
    int? fileCnt,
    String? delYn,
    List<BbsFileDataRes>? fileList,
  }) {
    return BbsListData(
      subject: subject ?? this.subject,
      contents: contents ?? this.contents,
      profilePath: profilePath ?? this.profilePath,
      replyCnt: replyCnt ?? this.replyCnt,
      typeDtCd: typeDtCd ?? this.typeDtCd,
      typeDtNm: typeDtNm ?? this.typeDtNm,
      filePath: filePath ?? this.filePath,
      crtCustId: crtCustId ?? this.crtCustId,
      depthNo: depthNo ?? this.depthNo,
      sortNo: sortNo ?? this.sortNo,
      parentId: parentId ?? this.parentId,
      nickNm: nickNm ?? this.nickNm,
      typeCd: typeCd ?? this.typeCd,
      boardId: boardId ?? this.boardId,
      fileKey: fileKey ?? this.fileKey,
      crtDtm: crtDtm ?? this.crtDtm,
      custNm: custNm ?? this.custNm,
      likeYn: likeYn ?? this.likeYn,
      viewCnt: viewCnt ?? this.viewCnt,
      likeCnt: likeCnt ?? this.likeCnt,
      fileCnt: fileCnt ?? this.fileCnt,
      delYn: delYn ?? this.delYn,
      fileList: fileList ?? this.fileList,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'subject': subject,
      'contents': contents,
      'profilePath': profilePath,
      'replyCnt': replyCnt,
      'typeDtCd': typeDtCd,
      'typeDtNm': typeDtNm,
      'filePath': filePath,
      'crtCustId': crtCustId,
      'depthNo': depthNo,
      'sortNo': sortNo,
      'parentId': parentId,
      'nickNm': nickNm,
      'typeCd': typeCd,
      'boardId': boardId,
      'fileKey': fileKey,
      'crtDtm': crtDtm,
      'custNm': custNm,
      'likeYn': likeYn,
      'viewCnt': viewCnt,
      'likeCnt': likeCnt,
      'fileCnt': fileCnt,
      'delYn': delYn,
      'fileList': fileList!.map((x) => x?.toMap()).toList(),
    };
  }

  factory BbsListData.fromMap(Map<String, dynamic> map) {
    return BbsListData(
      subject: map['subject'] != null ? map['subject'] as String : null,
      contents: map['contents'] != null ? map['contents'] as String : null,
      profilePath: map['profilePath'] != null ? map['profilePath'] as String : null,
      replyCnt: map['replyCnt'] != null ? map['replyCnt'] as int : null,
      typeDtCd: map['typeDtCd'] != null ? map['typeDtCd'] as String : null,
      typeDtNm: map['typeDtNm'] != null ? map['typeDtNm'] as String : null,
      filePath: map['filePath'] != null ? map['filePath'] as String : null,
      crtCustId: map['crtCustId'] != null ? map['crtCustId'] as String : null,
      depthNo: map['depthNo'] != null ? map['depthNo'] as String : null,
      sortNo: map['sortNo'] != null ? map['sortNo'] as String : null,
      parentId: map['parentId'] != null ? map['parentId'] as String : null,
      nickNm: map['nickNm'] != null ? map['nickNm'] as String : null,
      typeCd: map['typeCd'] != null ? map['typeCd'] as String : null,
      boardId: map['boardId'] != null ? map['boardId'] as int : null,
      fileKey: map['fileKey'] != null ? map['fileKey'] as String : null,
      crtDtm: map['crtDtm'] != null ? map['crtDtm'] as String : null,
      custNm: map['custNm'] != null ? map['custNm'] as String : null,
      likeYn: map['likeYn'] != null ? map['likeYn'] as String : null,
      viewCnt: map['viewCnt'] != null ? map['viewCnt'] as int : null,
      likeCnt: map['likeCnt'] != null ? map['likeCnt'] as int : null,
      fileCnt: map['fileCnt'] != null ? map['fileCnt'] as int : null,
      delYn: map['delYn'] != null ? map['delYn'] as String : null,
      fileList: map['fileList'] != null
          ? List<BbsFileDataRes>.from(
              (map['fileList'] as List).map<BbsFileDataRes?>(
                (x) => BbsFileDataRes.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BbsListData.fromJson(String source) => BbsListData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BbsListData(subject: $subject, contents: $contents, profilePath: $profilePath, replyCnt: $replyCnt, typeDtCd: $typeDtCd, typeDtNm:$typeDtNm , filePath: $filePath, crtCustId: $crtCustId, deptNo : $depthNo , sortNo : $sortNo , parentId : $parentId nickNm: $nickNm, typeCd: $typeCd, boardId: $boardId, fileKey: $fileKey, crtDtm: $crtDtm, custNm: $custNm, delYn: $delYn ,  likeYn : $likeYn,  viewCnt: $viewCnt, likeCnt: $likeCnt, fileCnt: $fileCnt, fileList: $fileList)';
  }

  bool isNullOrEmpty() {
    return crtCustId == null || crtCustId!.isEmpty;
  }

  @override
  bool operator ==(covariant BbsListData other) {
    if (identical(this, other)) return true;

    return other.subject == subject &&
        other.contents == contents &&
        other.profilePath == profilePath &&
        other.replyCnt == replyCnt &&
        other.typeDtCd == typeDtCd &&
        other.typeDtNm == typeDtNm &&
        other.filePath == filePath &&
        other.crtCustId == crtCustId &&
        other.depthNo == depthNo &&
        other.sortNo == sortNo &&
        other.parentId == parentId &&
        other.nickNm == nickNm &&
        other.typeCd == typeCd &&
        other.boardId == boardId &&
        other.fileKey == fileKey &&
        other.crtDtm == crtDtm &&
        other.custNm == custNm &&
        other.likeYn == likeYn &&
        other.viewCnt == viewCnt &&
        other.likeCnt == likeCnt &&
        other.fileCnt == fileCnt &&
        other.delYn == delYn &&
        listEquals(other.fileList, fileList);
  }

  @override
  int get hashCode {
    return subject.hashCode ^
        contents.hashCode ^
        profilePath.hashCode ^
        replyCnt.hashCode ^
        typeDtCd.hashCode ^
        typeDtNm.hashCode ^
        filePath.hashCode ^
        crtCustId.hashCode ^
        depthNo.hashCode ^
        sortNo.hashCode ^
        parentId.hashCode ^
        nickNm.hashCode ^
        typeCd.hashCode ^
        boardId.hashCode ^
        fileKey.hashCode ^
        crtDtm.hashCode ^
        custNm.hashCode ^
        likeYn.hashCode ^
        viewCnt.hashCode ^
        likeCnt.hashCode ^
        fileCnt.hashCode ^
        delYn.hashCode ^
        fileList.hashCode;
  }
}
