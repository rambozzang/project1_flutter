import 'package:flutter/material.dart';

/// 공유앨범 디자인 토큰 — 날씨 그라디언트(angle 155deg).
/// 미디어 썸네일 로딩 전 플레이스홀더/무드 배경 및 대문 테마 컬러 스와치(1f)로 사용.
/// 출처: design_handoff_shared_album/README.md (Weather Gradients)
class SaWeatherGradients {
  SaWeatherGradients._();

  // CSS 155deg → Flutter Alignment 근사
  static const Alignment _begin = Alignment(-0.42, -0.91);
  static const Alignment _end = Alignment(0.42, 0.91);

  /// 비
  static const LinearGradient rain = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFF5A9FE8), Color(0xFF2B5FB0), Color(0xFF243B73)],
    stops: [0.0, 0.55, 1.0],
  );

  /// 노을
  static const LinearGradient sunset = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFFFF9A5A), Color(0xFFFF5F6D), Color(0xFF7B3FA0)],
    stops: [0.0, 0.48, 1.0],
  );

  /// 폭풍
  static const LinearGradient storm = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFF4A5C82), Color(0xFF222C48), Color(0xFF5B3B7A)],
    stops: [0.0, 0.55, 1.0],
  );

  /// 밤/맑음
  static const LinearGradient night = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFF2A3F82), Color(0xFF2D1E5F), Color(0xFF0E1330)],
    stops: [0.0, 0.60, 1.0],
  );

  /// 오로라
  static const LinearGradient aurora = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFF1FD6A6), Color(0xFF2B8FF0), Color(0xFF7B5BF0)],
    stops: [0.0, 0.52, 1.0],
  );

  /// 골든아워
  static const LinearGradient golden = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFFFFD15A), Color(0xFFFF8A3C), Color(0xFFFF5F8F)],
    stops: [0.0, 0.50, 1.0],
  );

  /// 안개
  static const LinearGradient fog = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFF9AA7C7), Color(0xFF6D7BA0), Color(0xFFB9A7D6)],
    stops: [0.0, 0.55, 1.0],
  );

  /// 눈
  static const LinearGradient snow = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFFDBEEFF), Color(0xFFA9C8EC), Color(0xFFAAB8D8)],
    stops: [0.0, 0.55, 1.0],
  );

  /// 키 기반 조회(서버 저장값 ↔ 그라디언트 매핑, 1f 테마 컬러 스와치 순서 겸용)
  static const Map<String, LinearGradient> byKey = {
    'rain': rain,
    'sunset': sunset,
    'storm': storm,
    'night': night,
    'aurora': aurora,
    'golden': golden,
    'fog': fog,
    'snow': snow,
  };

  static List<String> get keys => byKey.keys.toList();

  /// 알 수 없는 키는 night로 폴백
  static LinearGradient of(String? key) => byKey[key] ?? night;
}
