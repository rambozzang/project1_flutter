// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ChallengeMeData {
  int? challengeId;
  String? challengeNm;
  int? monthCompleteCount;
  int? totalCompleteCount;
  List<DateTime>? recentCompleteDates;

  ChallengeMeData({
    this.challengeId,
    this.challengeNm,
    this.monthCompleteCount,
    this.totalCompleteCount,
    this.recentCompleteDates,
  });

  ChallengeMeData copyWith({
    int? challengeId,
    String? challengeNm,
    int? monthCompleteCount,
    int? totalCompleteCount,
    List<DateTime>? recentCompleteDates,
  }) {
    return ChallengeMeData(
      challengeId: challengeId ?? this.challengeId,
      challengeNm: challengeNm ?? this.challengeNm,
      monthCompleteCount: monthCompleteCount ?? this.monthCompleteCount,
      totalCompleteCount: totalCompleteCount ?? this.totalCompleteCount,
      recentCompleteDates: recentCompleteDates ?? this.recentCompleteDates,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'challengeId': challengeId,
      'challengeNm': challengeNm,
      'monthCompleteCount': monthCompleteCount,
      'totalCompleteCount': totalCompleteCount,
      'recentCompleteDates': recentCompleteDates?.map((x) => x.toIso8601String()).toList(),
    };
  }

  factory ChallengeMeData.fromMap(Map<String, dynamic> map) {
    return ChallengeMeData(
      challengeId: map['challengeId'] != null ? map['challengeId'] as int : null,
      challengeNm: map['challengeNm'] != null ? map['challengeNm'] as String : null,
      monthCompleteCount: map['monthCompleteCount'] != null ? (map['monthCompleteCount'] as num).toInt() : null,
      totalCompleteCount: map['totalCompleteCount'] != null ? (map['totalCompleteCount'] as num).toInt() : null,
      recentCompleteDates: map['recentCompleteDates'] != null
          ? List<DateTime>.from(
              (map['recentCompleteDates'] as List<dynamic>).map(
                (x) => DateTime.tryParse(x.toString()) ?? DateTime.now(),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChallengeMeData.fromJson(String source) =>
      ChallengeMeData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ChallengeMeData(challengeId: $challengeId, challengeNm: $challengeNm, monthCompleteCount: $monthCompleteCount)';
}
