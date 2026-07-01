class AchievementData {
  final String achievementId;
  final String achievementNm;
  final String achievementDesc;
  final String achievementIcon;
  final String category;
  final bool achieved;
  final DateTime? achievedDtm;
  final int totalAchievers;

  AchievementData({
    required this.achievementId,
    required this.achievementNm,
    required this.achievementDesc,
    required this.achievementIcon,
    required this.category,
    required this.achieved,
    this.achievedDtm,
    required this.totalAchievers,
  });

  factory AchievementData.fromMap(Map<String, dynamic> map) => AchievementData(
        achievementId: map['achievementId'] ?? '',
        achievementNm: map['achievementNm'] ?? '',
        achievementDesc: map['achievementDesc'] ?? '',
        achievementIcon: map['achievementIcon'] ?? '🏆',
        category: map['category'] ?? '',
        achieved: _asBool(map['achieved']),
        achievedDtm: map['achievedDtm'] != null
            ? DateTime.tryParse(map['achievedDtm'].toString())
            : null,
        totalAchievers: map['totalAchievers'] ?? 0,
      );

  /// 서버가 bool / int(0,1) / 문자열("Y","N","true","1") 중 무엇으로 보내도
  /// 안전하게 bool 로 변환한다. (타입 불일치로 파싱 전체가 실패하던 문제 방지)
  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'y' || s == 'true' || s == '1';
    }
    return false;
  }
}

class MyAchievementsData {
  final List<AchievementData> achievements;
  final int totalCount;
  final int achievedCount;

  MyAchievementsData({
    required this.achievements,
    required this.totalCount,
    required this.achievedCount,
  });

  factory MyAchievementsData.fromMap(Map<String, dynamic> map) {
    return MyAchievementsData(
      achievements: (map['achievements'] as List? ?? [])
          .map((e) => AchievementData.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalCount: map['totalCount'] ?? 0,
      achievedCount: map['achievedCount'] ?? 0,
    );
  }

  double get progress => totalCount > 0 ? achievedCount / totalCount : 0.0;
}
