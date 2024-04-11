// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BoardDetailData {
  String? isTop;
  String? isNew;
  String? typeCd;
  String? typeDtCd;
  int? depthNo;
  String? parentId;
  int? boardId;
  String? notiStAt;
  String? notiEdAt;
  String? subject;
  String? contents;
  String? regDate;
  String? crtDtm;
  BoardDetailData({
    this.isTop,
    this.isNew,
    this.typeCd,
    this.typeDtCd,
    this.depthNo,
    this.parentId,
    this.boardId,
    this.notiStAt,
    this.notiEdAt,
    this.subject,
    this.contents,
    this.regDate,
    this.crtDtm,
  });

  BoardDetailData copyWith({
    String? isTop,
    String? isNew,
    String? typeCd,
    String? typeDtCd,
    int? depthNo,
    String? parentId,
    int? boardId,
    String? notiStAt,
    String? notiEdAt,
    String? subject,
    String? contents,
    String? regDate,
    String? crtDtm,
  }) {
    return BoardDetailData(
      isTop: isTop ?? this.isTop,
      isNew: isNew ?? this.isNew,
      typeCd: typeCd ?? this.typeCd,
      typeDtCd: typeDtCd ?? this.typeDtCd,
      depthNo: depthNo ?? this.depthNo,
      parentId: parentId ?? this.parentId,
      boardId: boardId ?? this.boardId,
      notiStAt: notiStAt ?? this.notiStAt,
      notiEdAt: notiEdAt ?? this.notiEdAt,
      subject: subject ?? this.subject,
      contents: contents ?? this.contents,
      regDate: regDate ?? this.regDate,
      crtDtm: crtDtm ?? this.crtDtm,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isTop': isTop,
      'isNew': isNew,
      'typeCd': typeCd,
      'typeDtCd': typeDtCd,
      'depthNo': depthNo,
      'parentId': parentId,
      'boardId': boardId,
      'notiStAt': notiStAt,
      'notiEdAt': notiEdAt,
      'subject': subject,
      'contents': contents,
      'regDate': regDate,
      'crtDtm': crtDtm,
    };
  }

  factory BoardDetailData.fromMap(Map<String, dynamic> map) {
    return BoardDetailData(
      isTop: map['isTop'] != null ? map['isTop'] as String : null,
      isNew: map['isNew'] != null ? map['isNew'] as String : null,
      typeCd: map['typeCd'] != null ? map['typeCd'] as String : null,
      typeDtCd: map['typeDtCd'] != null ? map['typeDtCd'] as String : null,
      depthNo: map['depthNo'] != null ? map['depthNo'] as int : null,
      parentId: map['parentId'] != null ? map['parentId'] as String : null,
      boardId: map['boardId'] != null ? map['boardId'] as int : null,
      notiStAt: map['notiStAt'] != null ? map['notiStAt'] as String : null,
      notiEdAt: map['notiEdAt'] != null ? map['notiEdAt'] as String : null,
      subject: map['subject'] != null ? map['subject'] as String : null,
      contents: map['contents'] != null ? map['contents'] as String : null,
      regDate: map['regDate'] != null ? map['regDate'] as String : null,
      crtDtm: map['crtDtm'] != null ? map['crtDtm'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardDetailData.fromJson(String source) => BoardDetailData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardDetailData(isTop: $isTop, isNew: $isNew, typeCd: $typeCd, typeDtCd: $typeDtCd, depthNo: $depthNo, parentId: $parentId, boardId: $boardId, notiStAt: $notiStAt, notiEdAt: $notiEdAt, subject: $subject, contents: $contents, regDate: $regDate, crtDtm: $crtDtm)';
  }

  @override
  bool operator ==(covariant BoardDetailData other) {
    if (identical(this, other)) return true;

    return other.isTop == isTop &&
        other.isNew == isNew &&
        other.typeCd == typeCd &&
        other.typeDtCd == typeDtCd &&
        other.depthNo == depthNo &&
        other.parentId == parentId &&
        other.boardId == boardId &&
        other.notiStAt == notiStAt &&
        other.notiEdAt == notiEdAt &&
        other.subject == subject &&
        other.contents == contents &&
        other.regDate == regDate &&
        other.crtDtm == crtDtm;
  }

  @override
  int get hashCode {
    return isTop.hashCode ^
        isNew.hashCode ^
        typeCd.hashCode ^
        typeDtCd.hashCode ^
        depthNo.hashCode ^
        parentId.hashCode ^
        boardId.hashCode ^
        notiStAt.hashCode ^
        notiEdAt.hashCode ^
        subject.hashCode ^
        contents.hashCode ^
        regDate.hashCode ^
        crtDtm.hashCode;
  }
}
