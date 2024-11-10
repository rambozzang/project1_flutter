// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BoardUpdateData {
  String? boardId;
  String? delYn;
  String? hideYn;
  String? anonyYn;
  String? contents;
  BoardUpdateData({
    this.boardId,
    this.delYn,
    this.hideYn,
    this.anonyYn,
    this.contents,
  });

  BoardUpdateData copyWith({
    String? boardId,
    String? delYn,
    String? hideYn,
    String? anonyYn,
    String? contents,
  }) {
    return BoardUpdateData(
      boardId: boardId ?? this.boardId,
      delYn: delYn ?? this.delYn,
      hideYn: hideYn ?? this.hideYn,
      anonyYn: anonyYn ?? this.anonyYn,
      contents: contents ?? this.contents,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'boardId': boardId,
      'delYn': delYn,
      'hideYn': hideYn,
      'anonyYn': anonyYn,
      'contents': contents,
    };
  }

  factory BoardUpdateData.fromMap(Map<String, dynamic> map) {
    return BoardUpdateData(
      boardId: map['boardId'] != null ? map['boardId'] as String : null,
      delYn: map['delYn'] != null ? map['delYn'] as String : null,
      hideYn: map['hideYn'] != null ? map['hideYn'] as String : null,
      anonyYn: map['anonyYn'] != null ? map['anonyYn'] as String : null,
      contents: map['contents'] != null ? map['contents'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardUpdateData.fromJson(String source) => BoardUpdateData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardUpdateData(boardId: $boardId, delYn: $delYn, anonyYn: $anonyYn, hideYn: $hideYn, contents: $contents)';
  }

  @override
  bool operator ==(covariant BoardUpdateData other) {
    if (identical(this, other)) return true;

    return other.boardId == boardId &&
        other.delYn == delYn &&
        other.hideYn == hideYn &&
        other.anonyYn == anonyYn &&
        other.contents == contents;
  }

  @override
  int get hashCode {
    return boardId.hashCode ^ delYn.hashCode ^ hideYn.hashCode ^ anonyYn.hashCode ^ contents.hashCode;
  }
}
