// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ChatReqData {
  String? alramCd;
  String? custId;
  String? boardId;
  String? alramContents;
  ChatReqData({
    this.alramCd,
    this.custId,
    this.boardId,
    this.alramContents,
  });

  ChatReqData copyWith({
    String? alramCd,
    String? custId,
    String? boardId,
    String? alramContents,
  }) {
    return ChatReqData(
      alramCd: alramCd ?? this.alramCd,
      custId: custId ?? this.custId,
      boardId: boardId ?? this.boardId,
      alramContents: alramContents ?? this.alramContents,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'alramCd': alramCd,
      'custId': custId,
      'boardId': boardId,
      'alramContents': alramContents,
    };
  }

  factory ChatReqData.fromMap(Map<String, dynamic> map) {
    return ChatReqData(
      alramCd: map['alramCd'] != null ? map['alramCd'] as String : null,
      custId: map['custId'] != null ? map['custId'] as String : null,
      boardId: map['boardId'] != null ? map['boardId'] as String : null,
      alramContents: map['alramContents'] != null ? map['alramContents'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatReqData.fromJson(String source) => ChatReqData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChatReqData(alramCd: $alramCd, custId: $custId, boardId: $boardId, alramContents: $alramContents)';
  }

  @override
  bool operator ==(covariant ChatReqData other) {
    if (identical(this, other)) return true;

    return other.alramCd == alramCd && other.custId == custId && other.boardId == boardId && other.alramContents == alramContents;
  }

  @override
  int get hashCode {
    return alramCd.hashCode ^ custId.hashCode ^ boardId.hashCode ^ alramContents.hashCode;
  }
}
