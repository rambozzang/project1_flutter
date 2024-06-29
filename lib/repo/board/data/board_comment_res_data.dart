// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BoardCommentResData {
  int? boardId;
  String? subject;
  String? contents;
  String? custId;
  String? custNm;
  String? nickNm;
  String? selfId;
  String? profilePath;
  String? typeCd;
  String? typeDtCd;
  String? parentId;
  int? depthNo;
  int? sortNo;
  String? crtDtm;
  int? likeCnt;
  String? likeYn;
  BoardCommentResData({
    this.boardId,
    this.subject,
    this.contents,
    this.custId,
    this.custNm,
    this.nickNm,
    this.selfId,
    this.profilePath,
    this.typeCd,
    this.typeDtCd,
    this.parentId,
    this.depthNo,
    this.sortNo,
    this.crtDtm,
    this.likeCnt,
    this.likeYn,
  });

  BoardCommentResData copyWith({
    int? boardId,
    String? subject,
    String? contents,
    String? custId,
    String? custNm,
    String? nickNm,
    String? selfId,
    String? profilePath,
    String? typeCd,
    String? typeDtCd,
    String? parentId,
    int? depthNo,
    int? sortNo,
    String? crtDtm,
    int? likeCnt,
    String? likeYn,
  }) {
    return BoardCommentResData(
      boardId: boardId ?? this.boardId,
      subject: subject ?? this.subject,
      contents: contents ?? this.contents,
      custId: custId ?? this.custId,
      custNm: custNm ?? this.custNm,
      nickNm: nickNm ?? this.nickNm,
      selfId: selfId ?? this.selfId,
      profilePath: profilePath ?? this.profilePath,
      typeCd: typeCd ?? this.typeCd,
      typeDtCd: typeDtCd ?? this.typeDtCd,
      parentId: parentId ?? this.parentId,
      depthNo: depthNo ?? this.depthNo,
      sortNo: sortNo ?? this.sortNo,
      crtDtm: crtDtm ?? this.crtDtm,
      likeCnt: likeCnt ?? this.likeCnt,
      likeYn: likeYn ?? this.likeYn,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'boardId': boardId,
      'subject': subject,
      'contents': contents,
      'custId': custId,
      'custNm': custNm,
      'nickNm': nickNm,
      'selfId': selfId,
      'profilePath': profilePath,
      'typeCd': typeCd,
      'typeDtCd': typeDtCd,
      'parentId': parentId,
      'depthNo': depthNo,
      'sortNo': sortNo,
      'crtDtm': crtDtm,
      'likeCnt': likeCnt,
      'likeYn': likeYn,
    };
  }

  factory BoardCommentResData.fromMap(Map<String, dynamic> map) {
    return BoardCommentResData(
      boardId: map['boardId'] != null ? map['boardId'] as int : null,
      subject: map['subject'] != null ? map['subject'] as String : null,
      contents: map['contents'] != null ? map['contents'] as String : null,
      custId: map['custId'] != null ? map['custId'] as String : null,
      custNm: map['custNm'] != null ? map['custNm'] as String : null,
      nickNm: map['nickNm'] != null ? map['nickNm'] as String : null,
      selfId: map['selfId'] != null ? map['selfId'] as String : null,
      profilePath: map['profilePath'] != null ? map['profilePath'] as String : null,
      typeCd: map['typeCd'] != null ? map['typeCd'] as String : null,
      typeDtCd: map['typeDtCd'] != null ? map['typeDtCd'] as String : null,
      parentId: map['parentId'] != null ? map['parentId'] as String : null,
      depthNo: map['depthNo'] != null ? map['depthNo'] as int : null,
      sortNo: map['sortNo'] != null ? map['sortNo'] as int : null,
      crtDtm: map['crtDtm'] != null ? map['crtDtm'] as String : null,
      likeCnt: map['likeCnt'] != null ? map['likeCnt'] as int : null,
      likeYn: map['likeYn'] != null ? map['likeYn'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardCommentResData.fromJson(String source) => BoardCommentResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardCommentResData(boardId: $boardId, subject: $subject, contents: $contents, custId: $custId, custNm: $custNm, nickNm: $nickNm, selfId: $selfId, profilePath: $profilePath, typeCd: $typeCd, typeDtCd: $typeDtCd, parentId: $parentId, depthNo: $depthNo, sortNo: $sortNo, crtDtm: $crtDtm, likeCnt: $likeCnt, likeYn: $likeYn)';
  }

  @override
  bool operator ==(covariant BoardCommentResData other) {
    if (identical(this, other)) return true;

    return other.boardId == boardId &&
        other.subject == subject &&
        other.contents == contents &&
        other.custId == custId &&
        other.custNm == custNm &&
        other.nickNm == nickNm &&
        other.selfId == selfId &&
        other.profilePath == profilePath &&
        other.typeCd == typeCd &&
        other.typeDtCd == typeDtCd &&
        other.parentId == parentId &&
        other.depthNo == depthNo &&
        other.sortNo == sortNo &&
        other.crtDtm == crtDtm &&
        other.likeCnt == likeCnt &&
        other.likeYn == likeYn;
  }

  @override
  int get hashCode {
    return boardId.hashCode ^
        subject.hashCode ^
        contents.hashCode ^
        custId.hashCode ^
        custNm.hashCode ^
        nickNm.hashCode ^
        selfId.hashCode ^
        profilePath.hashCode ^
        typeCd.hashCode ^
        typeDtCd.hashCode ^
        parentId.hashCode ^
        depthNo.hashCode ^
        sortNo.hashCode ^
        crtDtm.hashCode ^
        likeCnt.hashCode ^
        likeYn.hashCode;
  }
}
