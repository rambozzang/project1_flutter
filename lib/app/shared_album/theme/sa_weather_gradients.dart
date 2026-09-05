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
    colors: [Color(0xFF6CB9C7), Color(0xFF3F8F9E), Color(0xFF2E626D)],
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
    colors: [Color(0xFF79616F), Color(0xFF44313C), Color(0xFF6E445A)],
    stops: [0.0, 0.55, 1.0],
  );

  /// 밤/맑음
  static const LinearGradient night = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFF49324B), Color(0xFF342433), Color(0xFF1D171F)],
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
    colors: [Color(0xFFB8A6B0), Color(0xFF8E747F), Color(0xFFC9AEB7)],
    stops: [0.0, 0.55, 1.0],
  );

  /// 눈
  static const LinearGradient snow = LinearGradient(
    begin: _begin,
    end: _end,
    colors: [Color(0xFFF5DDE2), Color(0xFFD4B2BE), Color(0xFFC0A0AE)],
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
