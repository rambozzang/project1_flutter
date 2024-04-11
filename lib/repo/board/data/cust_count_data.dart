// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CustCountData {
  int? followCnt;
  int? followerCnt;
  int? boardCnt;
  int? likeCnt;
  String? selfId;
  String? selfIntro;
  CustCountData({
    this.followCnt,
    this.followerCnt,
    this.boardCnt,
    this.likeCnt,
    this.selfId,
    this.selfIntro,
  });

  CustCountData copyWith({
    int? followCnt,
    int? followerCnt,
    int? boardCnt,
    int? likeCnt,
    String? selfId,
    String? selfIntro,
  }) {
    return CustCountData(
      followCnt: followCnt ?? this.followCnt,
      followerCnt: followerCnt ?? this.followerCnt,
      boardCnt: boardCnt ?? this.boardCnt,
      likeCnt: likeCnt ?? this.likeCnt,
      selfId: selfId ?? this.selfId,
      selfIntro: selfIntro ?? this.selfIntro,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'followCnt': followCnt,
      'followerCnt': followerCnt,
      'boardCnt': boardCnt,
      'likeCnt': likeCnt,
      'selfId': selfId,
      'selfIntro': selfIntro,
    };
  }

  factory CustCountData.fromMap(Map<String, dynamic> map) {
    return CustCountData(
      followCnt: map['followCnt'] != null ? map['followCnt'] as int : null,
      followerCnt: map['followerCnt'] != null ? map['followerCnt'] as int : null,
      boardCnt: map['boardCnt'] != null ? map['boardCnt'] as int : null,
      likeCnt: map['likeCnt'] != null ? map['likeCnt'] as int : null,
      selfId: map['selfId'] != null ? map['selfId'] as String : null,
      selfIntro: map['selfIntro'] != null ? map['selfIntro'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustCountData.fromJson(String source) => CustCountData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CustCountData(followCnt: $followCnt, followerCnt: $followerCnt, boardCnt: $boardCnt, likeCnt: $likeCnt, selfId: $selfId, selfIntro: $selfIntro)';
  }

  @override
  bool operator ==(covariant CustCountData other) {
    if (identical(this, other)) return true;

    return other.followCnt == followCnt &&
        other.followerCnt == followerCnt &&
        other.boardCnt == boardCnt &&
        other.likeCnt == likeCnt &&
        other.selfId == selfId &&
        other.selfIntro == selfIntro;
  }

  @override
  int get hashCode {
    return followCnt.hashCode ^ followerCnt.hashCode ^ boardCnt.hashCode ^ likeCnt.hashCode ^ selfId.hashCode ^ selfIntro.hashCode;
  }
}
