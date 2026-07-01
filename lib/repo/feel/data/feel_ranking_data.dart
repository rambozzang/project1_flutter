class FeelRankingData {
  final int rank;
  final String custId;
  final String nickNm;
  final String? profilePath;
  final int feelCount;
  final String topFeelCd;

  FeelRankingData({
    required this.rank,
    required this.custId,
    required this.nickNm,
    this.profilePath,
    required this.feelCount,
    required this.topFeelCd,
  });

  factory FeelRankingData.fromMap(Map<String, dynamic> map) => FeelRankingData(
        rank: map['rank'] ?? 0,
        custId: map['custId'] ?? '',
        nickNm: map['nickNm'] ?? '',
        profilePath: map['profilePath'],
        feelCount: map['feelCount'] ?? 0,
        topFeelCd: map['topFeelCd'] ?? '',
      );
}

/// 지역별 체감 통계 한 건 (best-effort).
class AreaFeelStat {
  final String feelCd;
  final int count;

  const AreaFeelStat({required this.feelCd, required this.count});
}

class FeelCode {
  static const Map<String, Map<String, String>> codes = {
    'HELL':   {'name': '찜통더위',     'emoji': '🌋'},
    'HOT':    {'name': '너무더워',     'emoji': '🥵'},
    'WARM':   {'name': '따뜻해',       'emoji': '☀️'},
    'GOOD':   {'name': '딱좋아',       'emoji': '😊'},
    'COOL':   {'name': '선선해',       'emoji': '🌤️'},
    'COLD':   {'name': '추워',         'emoji': '🧥'},
    'FROZEN': {'name': '얼어죽겠어',   'emoji': '🥶'},
    'RAINY':  {'name': '비맞는중',     'emoji': '🌧️'},
    'SNOWY':  {'name': '눈맞는중',     'emoji': '❄️'},
    'WINDY':  {'name': '바람장난아님', 'emoji': '💨'},
  };

  static String getEmoji(String? code) => codes[code]?['emoji'] ?? '🌡️';
  static String getName(String? code) => codes[code]?['name'] ?? '';
}
