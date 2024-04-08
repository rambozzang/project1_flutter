// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BoardInfoData {
  double? boardId;
  String? typeCd;
  String? typeDtCd;
  String? notiStAt;
  String? notiEdAt;

  String? suject;
  String? contents;
  String? depthNo;
  double? parentBoradId;
  int? sortNo;
  String? delYn;
  BoardInfoData({
    this.boardId,
    this.typeCd,
    this.typeDtCd,
    this.notiStAt,
    this.notiEdAt,
    this.suject,
    this.contents,
    this.depthNo,
    this.parentBoradId,
    this.sortNo,
    this.delYn,
  });

  BoardInfoData copyWith({
    double? boardId,
    String? typeCd,
    String? typeDtCd,
    String? notiStAt,
    String? notiEdAt,
    String? suject,
    String? contents,
    String? depthNo,
    double? parentBoradId,
    int? sortNo,
    String? delYn,
  }) {
    return BoardInfoData(
      boardId: boardId ?? this.boardId,
      typeCd: typeCd ?? this.typeCd,
      typeDtCd: typeDtCd ?? this.typeDtCd,
      notiStAt: notiStAt ?? this.notiStAt,
      notiEdAt: notiEdAt ?? this.notiEdAt,
      suject: suject ?? this.suject,
      contents: contents ?? this.contents,
      depthNo: depthNo ?? this.depthNo,
      parentBoradId: parentBoradId ?? this.parentBoradId,
      sortNo: sortNo ?? this.sortNo,
      delYn: delYn ?? this.delYn,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'boardId': boardId,
      'typeCd': typeCd,
      'typeDtCd': typeDtCd,
      'notiStAt': notiStAt,
      'notiEdAt': notiEdAt,
      'suject': suject,
      'contents': contents,
      'depthNo': depthNo,
      'parentBoradId': parentBoradId,
      'sortNo': sortNo,
      'delYn': delYn,
    };
  }

  factory BoardInfoData.fromMap(Map<String, dynamic> map) {
    return BoardInfoData(
      boardId: map['boardId'] != null ? map['boardId'] as double : null,
      typeCd: map['typeCd'] != null ? map['typeCd'] as String : null,
      typeDtCd: map['typeDtCd'] != null ? map['typeDtCd'] as String : null,
      notiStAt: map['notiStAt'] != null ? map['notiStAt'] as String : null,
      notiEdAt: map['notiEdAt'] != null ? map['notiEdAt'] as String : null,
      suject: map['suject'] != null ? map['suject'] as String : null,
      contents: map['contents'] != null ? map['contents'] as String : null,
      depthNo: map['depthNo'] != null ? map['depthNo'] as String : null,
      parentBoradId: map['parentBoradId'] != null ? map['parentBoradId'] as double : null,
      sortNo: map['sortNo'] != null ? map['sortNo'] as int : null,
      delYn: map['delYn'] != null ? map['delYn'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardInfoData.fromJson(String source) => BoardInfoData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardInfoData(boardId: $boardId, typeCd: $typeCd, typeDtCd: $typeDtCd, notiStAt: $notiStAt, notiEdAt: $notiEdAt, suject: $suject, contents: $contents, depthNo: $depthNo, parentBoradId: $parentBoradId, sortNo: $sortNo, delYn: $delYn)';
  }

  @override
  bool operator ==(covariant BoardInfoData other) {
    if (identical(this, other)) return true;

    return other.boardId == boardId &&
        other.typeCd == typeCd &&
        other.typeDtCd == typeDtCd &&
        other.notiStAt == notiStAt &&
        other.notiEdAt == notiEdAt &&
        other.suject == suject &&
        other.contents == contents &&
        other.depthNo == depthNo &&
        other.parentBoradId == parentBoradId &&
        other.sortNo == sortNo &&
        other.delYn == delYn;
  }

  @override
  int get hashCode {
    return boardId.hashCode ^
        typeCd.hashCode ^
        typeDtCd.hashCode ^
        notiStAt.hashCode ^
        notiEdAt.hashCode ^
        suject.hashCode ^
        contents.hashCode ^
        depthNo.hashCode ^
        parentBoradId.hashCode ^
        sortNo.hashCode ^
        delYn.hashCode;
  }
}
