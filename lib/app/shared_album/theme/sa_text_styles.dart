import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';

/// 공유앨범 디자인 토큰 — 타이포그래피.
/// 본문/UI = Pretendard(앱 번들 폰트), 수치·메타·태그 = Space Mono(google_fonts).
/// 출처: design_handoff_shared_album/README.md (Typography)
class SaText {
  SaText._();

  static const String _family = 'Pretendard';

  /// 커버 히어로 타이틀 (1b) — 800/34
  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w800,
    fontSize: 34,
    height: 1.15,
    color: SaColors.textPrimary,
  );

  /// 홈 헤더 "우리의 앨범" — 800/28
  static const TextStyle titleL = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 1.2,
    color: SaColors.textPrimary,
  );

  /// 앨범 카드 제목 — 800/22
  static const TextStyle titleM = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w800,
    fontSize: 22,
    height: 1.25,
    color: SaColors.textPrimary,
  );

  /// 앱바 제목, 리스트 제목 — 700/16.5
  static const TextStyle titleS = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w700,
    fontSize: 16.5,
    height: 1.3,
    color: SaColors.textPrimary,
  );

  /// 설명/소개 — 400/14.5 (secondary 기본)
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w400,
    fontSize: 14.5,
    height: 1.45,
    color: SaColors.textSecondary,
  );

  /// 본문 강조 — 500/14.5
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w500,
    fontSize: 14.5,
    height: 1.45,
    color: SaColors.textPrimary,
  );

  /// 스탯 라벨 — 600/12.5
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w600,
    fontSize: 12.5,
    height: 1.35,
    color: SaColors.textSecondary,
  );

  /// 수치/태그/타임스탬프 — Space Mono 600~800 / 10~12
  /// (google_fonts는 최초 사용 시 폰트를 로드하므로 const 불가)
  static TextStyle mono({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w700,
    Color color = SaColors.textTertiary,
    double letterSpacingEm = 0.06,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: fontSize * letterSpacingEm,
    );
  }
}
