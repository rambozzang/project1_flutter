import 'package:flutter/material.dart';

/// 공유앨범 디자인 토큰 — 색상. (다크/라이트 2팔레트)
/// 출처: design_handoff_shared_album/README.md (Design Tokens > Colors)
///
/// 사용법은 기존과 동일하게 `SaColors.bgBase` — 내부에서 현재 모드에 맞는 팔레트를 반환한다.
/// 모드는 시스템 밝기를 따르며, 각 앨범 페이지 build 최상단에서 `SaColors.syncWith(context)`를
/// 호출해 동기화한다(플랫폼 밝기를 읽으므로 시스템 테마 변경 시 자동 rebuild).
/// 몰입뷰(영상 전체화면)처럼 항상 어두워야 하는 화면은 [SaColorsDark]를 직접 참조한다.
class SaColors {
  SaColors._();

  /// 현재 라이트 모드 여부. 페이지 build에서 [syncWith]로 갱신된다.
  static bool isLight = false;

  /// 시스템 밝기와 동기화 — 앨범 각 페이지 build 최상단에서 호출.
  static void syncWith(BuildContext context) {
    isLight = MediaQuery.platformBrightnessOf(context) == Brightness.light;
  }

  // ── 표면 ──────────────────────────────────────────────
  /// 앱/화면 기본 배경
  static Color get bgBase => isLight ? const Color(0xFFF4F7FB) : SaColorsDark.bgBase;

  /// 카드/셀 배경
  static Color get surface => isLight ? Colors.white : SaColorsDark.surface;

  /// 썸네일 플레이스홀더 등 한 단계 밝은 표면
  static Color get surfaceElevated => isLight ? const Color(0xFFEAF0F7) : SaColorsDark.surfaceElevated;

  /// 카드 외곽선 (다크: white 7% / 라이트: ink 8%)
  static Color get border => isLight ? const Color(0x14263C50) : SaColorsDark.border;

  /// 인풋/버튼 외곽선 (다크: white 10% / 라이트: ink 13%)
  static Color get borderStrong => isLight ? const Color(0x21263C50) : SaColorsDark.borderStrong;

  // ── 액센트 ────────────────────────────────────────────
  /// Primary — 주요 액션, 선택 상태, 링크 (라이트는 흰 배경 대비를 위해 딥 틸)
  static Color get accentTeal => isLight ? const Color(0xFF00B3A4) : SaColorsDark.accentTeal;

  /// 그라디언트 짝 (teal→blue)
  static Color get accentBlue => isLight ? const Color(0xFF1F7AE0) : SaColorsDark.accentBlue;

  /// "안 본 새 콘텐츠" 뱃지/점, 좋아요
  static Color get accentPink => isLight ? const Color(0xFFE9346B) : SaColorsDark.accentPink;

  /// 대기 중 초대 등
  static Color get warn => isLight ? const Color(0xFFDE8A2E) : SaColorsDark.warn;

  // ── 텍스트 ────────────────────────────────────────────
  static Color get textPrimary => isLight ? const Color(0xFF17222E) : SaColorsDark.textPrimary;

  /// 보조 텍스트 (다크: white 55% / 라이트: 딥 슬레이트)
  static Color get textSecondary => isLight ? const Color(0xFF5C6C7E) : SaColorsDark.textSecondary;

  /// 메타/타임스탬프 (다크: white 40% / 라이트: 연한 슬레이트)
  static Color get textTertiary => isLight ? const Color(0xFF93A2B2) : SaColorsDark.textTertiary;

  /// accent(teal/그라디언트) 버튼 위 텍스트 — 라이트의 딥 틸 위에는 흰색이 정답
  static Color get onAccent => isLight ? Colors.white : SaColorsDark.onAccent;

  /// 주요 액션(버튼·FAB·아이콘칩) 그라디언트: linear-gradient(145deg, teal, blue)
  static LinearGradient get primaryGradient => LinearGradient(
        begin: const Alignment(-0.57, -0.82),
        end: const Alignment(0.57, 0.82),
        colors: [accentTeal, accentBlue],
      );
}

/// 다크 팔레트 원본 상수 — 몰입뷰(영상 전체화면) 등 모드와 무관하게
/// 항상 어두워야 하는 화면에서 직접 참조한다.
class SaColorsDark {
  SaColorsDark._();

  static const Color bgBase = Color(0xFF0C0D11);
  static const Color surface = Color(0xFF15171D);
  static const Color surfaceElevated = Color(0xFF1A1D24);
  static const Color border = Color(0x12FFFFFF);
  static const Color borderStrong = Color(0x1AFFFFFF);
  static const Color accentTeal = Color(0xFF00E5D0);
  static const Color accentBlue = Color(0xFF2B8FF0);
  static const Color accentPink = Color(0xFFFF3D77);
  static const Color warn = Color(0xFFFFB75E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0x8CFFFFFF);
  static const Color textTertiary = Color(0x66FFFFFF);
  static const Color onAccent = Color(0xFF04121A);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-0.57, -0.82),
    end: Alignment(0.57, 0.82),
    colors: [accentTeal, accentBlue],
  );
}
