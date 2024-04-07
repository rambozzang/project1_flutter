// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BoardMastInData {
  String? typeCd;
  String? typeDtCd;
  String? notiStAt;
  String? notiEdAt;
  String? subject;
  String? contents;
  String? depthNo;
  BoardMastInData({
    this.typeCd,
    this.typeDtCd,
    this.notiStAt,
    this.notiEdAt,
    this.subject,
    this.contents,
    this.depthNo,
  });

  BoardMastInData copyWith({
    String? typeCd,
    String? typeDtCd,
    String? notiStAt,
    String? notiEdAt,
    String? subject,
    String? contents,
    String? depthNo,
  }) {
    return BoardMastInData(
      typeCd: typeCd ?? this.typeCd,
      typeDtCd: typeDtCd ?? this.typeDtCd,
      notiStAt: notiStAt ?? this.notiStAt,
      notiEdAt: notiEdAt ?? this.notiEdAt,
      subject: subject ?? this.subject,
      contents: contents ?? this.contents,
      depthNo: depthNo ?? this.depthNo,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'typeCd': typeCd,
      'typeDtCd': typeDtCd,
      'notiStAt': notiStAt,
      'notiEdAt': notiEdAt,
      'subject': subject,
      'contents': contents,
      'depthNo': depthNo,
    };
  }

  factory BoardMastInData.fromMap(Map<String, dynamic> map) {
    return BoardMastInData(
      typeCd: map['typeCd'] != null ? map['typeCd'] as String : null,
      typeDtCd: map['typeDtCd'] != null ? map['typeDtCd'] as String : null,
      notiStAt: map['notiStAt'] != null ? map['notiStAt'] as String : null,
      notiEdAt: map['notiEdAt'] != null ? map['notiEdAt'] as String : null,
      subject: map['subject'] != null ? map['subject'] as String : null,
      contents: map['contents'] != null ? map['contents'] as String : null,
      depthNo: map['depthNo'] != null ? map['depthNo'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardMastInData.fromJson(String source) => BoardMastInData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardMastInData(typeCd: $typeCd, typeDtCd: $typeDtCd, notiStAt: $notiStAt, notiEdAt: $notiEdAt, subject: $subject, contents: $contents, depthNo: $depthNo)';
  }

  @override
  bool operator ==(covariant BoardMastInData other) {
    if (identical(this, other)) return true;

    return other.typeCd == typeCd &&
        other.typeDtCd == typeDtCd &&
        other.notiStAt == notiStAt &&
        other.notiEdAt == notiEdAt &&
        other.subject == subject &&
        other.contents == contents &&
        other.depthNo == depthNo;
  }

  @override
  int get hashCode {
    return typeCd.hashCode ^
        typeDtCd.hashCode ^
        notiStAt.hashCode ^
        notiEdAt.hashCode ^
        subject.hashCode ^
        contents.hashCode ^
        depthNo.hashCode;
  }
}