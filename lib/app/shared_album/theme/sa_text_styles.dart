import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';

/// 공유앨범 디자인 토큰 — 타이포그래피.
/// 본문/UI = Pretendard(앱 번들 폰트), 수치·메타·태그 = Space Mono(google_fonts).
/// 출처: design_handoff_shared_album/README.md (Typography)
///
/// 색이 다크/라이트 모드에 따라 달라지므로 const 상수가 아닌 getter로 제공한다.
/// (SaColors가 현재 모드 팔레트를 반환 — 사용법은 기존과 동일하게 `SaText.body`)
class SaText {
  SaText._();

  static const String _family = 'Pretendard';

  /// 커버 히어로 타이틀 (1b) — 800/34
  static TextStyle get display => TextStyle(
        fontFamily: _family,
        fontWeight: FontWeight.w800,
        fontSize: 34,
        height: 1.15,
        color: SaColors.textPrimary,
      );

  /// 홈 헤더 "우리의 앨범" — 800/28
  static TextStyle get titleL => TextStyle(
        fontFamily: _family,
        fontWeight: FontWeight.w800,
        fontSize: 28,
        height: 1.2,
        color: SaColors.textPrimary,
      );

  /// 앨범 카드 제목 — 800/22
  static TextStyle get titleM => TextStyle(
        fontFamily: _family,
        fontWeight: FontWeight.w800,
        fontSize: 22,
        height: 1.25,
        color: SaColors.textPrimary,
      );

  /// 앱바 제목, 리스트 제목 — 700/16.5
  static TextStyle get titleS => TextStyle(
        fontFamily: _family,
        fontWeight: FontWeight.w700,
        fontSize: 16.5,
        height: 1.3,
        color: SaColors.textPrimary,
      );

  /// 설명/소개 — 400/14.5 (secondary 기본)
  static TextStyle get body => TextStyle(
        fontFamily: _family,
        fontWeight: FontWeight.w400,
        fontSize: 14.5,
        height: 1.45,
        color: SaColors.textSecondary,
      );

  /// 본문 강조 — 500/14.5
  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _family,
        fontWeight: FontWeight.w500,
        fontSize: 14.5,
        height: 1.45,
        color: SaColors.textPrimary,
      );

  /// 스탯 라벨 — 600/12.5
  static TextStyle get caption => TextStyle(
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
    Color? color,
    double letterSpacingEm = 0.06,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? SaColors.textTertiary,
      letterSpacing: fontSize * letterSpacingEm,
    );
  }
}
