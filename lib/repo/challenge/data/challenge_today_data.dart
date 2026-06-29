// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ChallengeTodayData {
  int? challengeId;
  String? challengeNm;
  String? challengeDesc;
  String? typeCd;
  String? targetCd;
  String? rewardDesc;
  String? completeYn;
  DateTime? completeDtm;
  int? todayParticipantCount;

  ChallengeTodayData({
    this.challengeId,
    this.challengeNm,
    this.challengeDesc,
    this.typeCd,
    this.targetCd,
    this.rewardDesc,
    this.completeYn,
    this.completeDtm,
    this.todayParticipantCount,
  });

  ChallengeTodayData copyWith({
    int? challengeId,
    String? challengeNm,
    String? challengeDesc,
    String? typeCd,
    String? targetCd,
    String? rewardDesc,
    String? completeYn,
    DateTime? completeDtm,
    int? todayParticipantCount,
  }) {
    return ChallengeTodayData(
      challengeId: challengeId ?? this.challengeId,
      challengeNm: challengeNm ?? this.challengeNm,
      challengeDesc: challengeDesc ?? this.challengeDesc,
      typeCd: typeCd ?? this.typeCd,
      targetCd: targetCd ?? this.targetCd,
      rewardDesc: rewardDesc ?? this.rewardDesc,
      completeYn: completeYn ?? this.completeYn,
      completeDtm: completeDtm ?? this.completeDtm,
      todayParticipantCount: todayParticipantCount ?? this.todayParticipantCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'challengeId': challengeId,
      'challengeNm': challengeNm,
      'challengeDesc': challengeDesc,
      'typeCd': typeCd,
      'targetCd': targetCd,
      'rewardDesc': rewardDesc,
      'completeYn': completeYn,
      'completeDtm': completeDtm?.millisecondsSinceEpoch,
      'todayParticipantCount': todayParticipantCount,
    };
  }

  factory ChallengeTodayData.fromMap(Map<String, dynamic> map) {
    return ChallengeTodayData(
      challengeId: map['challengeId'] != null ? map['challengeId'] as int : null,
      challengeNm: map['challengeNm'] != null ? map['challengeNm'] as String : null,
      challengeDesc: map['challengeDesc'] != null ? map['challengeDesc'] as String : null,
      typeCd: map['typeCd'] != null ? map['typeCd'] as String : null,
      targetCd: map['targetCd'] != null ? map['targetCd'] as String : null,
      rewardDesc: map['rewardDesc'] != null ? map['rewardDesc'] as String : null,
      completeYn: map['completeYn'] != null ? map['completeYn'] as String : null,
      completeDtm: map['completeDtm'] != null
          ? DateTime.tryParse(map['completeDtm'].toString())
          : null,
      todayParticipantCount:
          map['todayParticipantCount'] != null ? (map['todayParticipantCount'] as num).toInt() : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChallengeTodayData.fromJson(String source) =>
      ChallengeTodayData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ChallengeTodayData(challengeId: $challengeId, challengeNm: $challengeNm, completeYn: $completeYn)';

  @override
  bool operator ==(covariant ChallengeTodayData other) {
    if (identical(this, other)) return true;
    return other.challengeId == challengeId && other.completeYn == completeYn;
  }

  @override
  int get hashCode => challengeId.hashCode ^ completeYn.hashCode;
}
