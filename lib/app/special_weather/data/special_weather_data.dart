/// 기상 특보(폭염·호우·대설·강풍 등) 데이터 모델.
/// 백엔드 연동 전까지는 mock 데이터로 동작하며, API 확정 시 fromMap/fromJson만 교체하면 된다.
class SpecialWeatherData {
  final String id;
  final String title; // 예: "폭염주의보"
  final String category; // 예: "폭염"
  final String level; // 예: "주의보" 또는 "경보"
  final String region; // 예: "서울 전역, 경기 남부"
  final String content; // 상세 특보 내용
  final DateTime? issuedAt; // 발효 시각
  final DateTime? liftedAt; // 해제 시각 (미해제 시 null)
  final String? source; // 발표 기관
  final String? actionTip; // 행동 요령

  const SpecialWeatherData({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.region,
    required this.content,
    this.issuedAt,
    this.liftedAt,
    this.source,
    this.actionTip,
  });

  bool get isActive => liftedAt == null;

  SpecialWeatherData copyWith({
    String? id,
    String? title,
    String? category,
    String? level,
    String? region,
    String? content,
    DateTime? issuedAt,
    DateTime? liftedAt,
    String? source,
    String? actionTip,
  }) {
    return SpecialWeatherData(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      level: level ?? this.level,
      region: region ?? this.region,
      content: content ?? this.content,
      issuedAt: issuedAt ?? this.issuedAt,
      liftedAt: liftedAt ?? this.liftedAt,
      source: source ?? this.source,
      actionTip: actionTip ?? this.actionTip,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'level': level,
      'region': region,
      'content': content,
      'issuedAt': issuedAt?.toIso8601String(),
      'liftedAt': liftedAt?.toIso8601String(),
      'source': source,
      'actionTip': actionTip,
    };
  }

  factory SpecialWeatherData.fromMap(Map<String, dynamic> map) {
    return SpecialWeatherData(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      level: map['level']?.toString() ?? '',
      region: map['region']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      issuedAt: map['issuedAt'] != null ? DateTime.tryParse(map['issuedAt'].toString()) : null,
      liftedAt: map['liftedAt'] != null ? DateTime.tryParse(map['liftedAt'].toString()) : null,
      source: map['source']?.toString(),
      actionTip: map['actionTip']?.toString(),
    );
  }
}
