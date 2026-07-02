import 'package:flutter/material.dart';

/// 공유앨범 디자인 토큰 — 색상.
/// 출처: design_handoff_shared_album/README.md (Design Tokens > Colors)
class SaColors {
  SaColors._();

  /// 앱/화면 기본 배경 (다크)
  static const Color bgBase = Color(0xFF0C0D11);

  /// 카드/셀 배경
  static const Color surface = Color(0xFF15171D);

  /// 썸네일 플레이스홀더 등 한 단계 밝은 표면
  static const Color surfaceElevated = Color(0xFF1A1D24);

  /// 카드 외곽선 (white 7%)
  static const Color border = Color(0x12FFFFFF);

  /// 인풋/버튼 외곽선 (white 10%)
  static const Color borderStrong = Color(0x1AFFFFFF);

  /// Primary — 주요 액션, 선택 상태, 링크
  static const Color accentTeal = Color(0xFF00E5D0);

  /// 그라디언트 짝 (teal→blue)
  static const Color accentBlue = Color(0xFF2B8FF0);

  /// "안 본 새 콘텐츠" 뱃지/점, 좋아요
  static const Color accentPink = Color(0xFFFF3D77);

  /// 대기 중 초대 등
  static const Color warn = Color(0xFFFFB75E);

  static const Color textPrimary = Colors.white;

  /// 보조 텍스트 (white 55%)
  static const Color textSecondary = Color(0x8CFFFFFF);

  /// 메타/타임스탬프 (white 40%)
  static const Color textTertiary = Color(0x66FFFFFF);

  /// teal 버튼 위 텍스트 (진한 청록-검정)
  static const Color onAccent = Color(0xFF04121A);

  /// 주요 액션(버튼·FAB·아이콘칩) 그라디언트: linear-gradient(145deg, teal, blue)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-0.57, -0.82),
    end: Alignment(0.57, 0.82),
    colors: [accentTeal, accentBlue],
  );
}
