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
        achieved: map['achieved'] ?? false,
        achievedDtm: map['achievedDtm'] != null
            ? DateTime.tryParse(map['achievedDtm'].toString())
            : null,
        totalAchievers: map['totalAchievers'] ?? 0,
      );
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
