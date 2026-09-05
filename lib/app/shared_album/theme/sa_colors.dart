import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 앨범 테마 모드 — 설정에서 사용자가 선택(기본: 시스템 따름).
enum SaThemeMode { system, light, dark }

/// 공유앨범 디자인 토큰 — 색상. (다크/라이트 2팔레트)
/// 출처: design_handoff_shared_album/README.md (Design Tokens > Colors)
///
/// 사용법은 기존과 동일하게 `SaColors.bgBase` — 내부에서 현재 모드에 맞는 팔레트를 반환한다.
/// 모드는 사용자 선택([themeMode], 기본=시스템 밝기 추종)을 따르며, 각 앨범 페이지 build
/// 최상단에서 `SaColors.syncWith(context)`를 호출해 동기화한다.
/// 몰입뷰(영상 전체화면)처럼 항상 어두워야 하는 화면은 [SaColorsDark]를 직접 참조한다.
class SaColors {
  SaColors._();

  /// 현재 라이트 모드 여부. 페이지 build에서 [syncWith]로 갱신된다. 기본=라이트.
  static bool isLight = true;

  /// 사용자가 선택한 테마 모드(설정 > 앨범 테마). 앱 재시작 후에도 유지. 기본=라이트(최초 진입 시 라이트).
  static SaThemeMode themeMode = SaThemeMode.light;

  /// 모드 변경 알림 — 탭에 살아있는 앨범 페이지가 구독해 즉시 다시 그린다.
  static final ValueNotifier<int> themeTick = ValueNotifier<int>(0);

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const String _kThemeKey = 'SA_THEME_MODE';
  static bool _loaded = false;

  /// 저장된 테마 모드 복원(1회만 실제 조회) — 앨범 홈/설정 진입 시 호출.
  static Future<void> loadSavedMode() async {
    if (_loaded) return;
    _loaded = true;
    final v = await _storage.read(key: _kThemeKey);
    if (v == 'light') {
      themeMode = SaThemeMode.light;
    } else if (v == 'dark') {
      themeMode = SaThemeMode.dark;
    } else if (v == 'system') {
      themeMode = SaThemeMode.system;
    } else {
      themeMode = SaThemeMode.light; // 저장값 없으면 라이트 기본
    }
    themeTick.value++;
  }

  /// 테마 모드 변경 + 저장 + 구독 페이지 갱신 통지.
  static Future<void> saveMode(SaThemeMode mode) async {
    themeMode = mode;
    themeTick.value++;
    await _storage.write(key: _kThemeKey, value: mode.name);
  }

  /// 현재 모드와 동기화 — 앨범 각 페이지 build 최상단에서 호출.
  /// (system 모드는 플랫폼 밝기를 읽으므로 시스템 테마 변경 시 자동 rebuild)
  static void syncWith(BuildContext context) {
    switch (themeMode) {
      case SaThemeMode.light:
        isLight = true;
        break;
      case SaThemeMode.dark:
        isLight = false;
        break;
      case SaThemeMode.system:
        isLight = MediaQuery.platformBrightnessOf(context) == Brightness.light;
        break;
    }
  }

  // ── 표면 ──────────────────────────────────────────────
  /// 앱/화면 기본 배경
  static Color get bgBase =>
      isLight ? SaColorsLight.bgBase : SaColorsDark.bgBase;

  /// 카드/셀 배경
  static Color get surface =>
      isLight ? SaColorsLight.surface : SaColorsDark.surface;

  /// 썸네일 플레이스홀더 등 한 단계 밝은 표면
  static Color get surfaceElevated =>
      isLight ? SaColorsLight.surfaceElevated : SaColorsDark.surfaceElevated;

  /// 카드 외곽선 (다크: white 7% / 라이트: ink 8%)
  static Color get border =>
      isLight ? SaColorsLight.border : SaColorsDark.border;

  /// 인풋/버튼 외곽선 (다크: white 10% / 라이트: ink 13%)
  static Color get borderStrong =>
      isLight ? SaColorsLight.borderStrong : SaColorsDark.borderStrong;

  // ── 액센트 ────────────────────────────────────────────
  /// 주요 액션, 선택 상태, 링크에만 쓰는 민트 포인트.
  ///
  /// 필드명은 초기 앨범 목업의 "teal"이 남은 것이므로 API 호환을 위해 유지한다.
  /// 배경은 중립색으로 두고 액션에만 색을 사용한다.
  static Color get accentTeal =>
      isLight ? SaColorsLight.accentTeal : SaColorsDark.accentTeal;

  /// 레거시 그라디언트 API용 같은 색상군의 보조색.
  static Color get accentBlue =>
      isLight ? SaColorsLight.accentBlue : SaColorsDark.accentBlue;

  /// "안 본 새 콘텐츠" 뱃지/점, 좋아요
  static Color get accentPink =>
      isLight ? SaColorsLight.accentPink : SaColorsDark.accentPink;

  /// 대기 중 초대 등
  static Color get warn => isLight ? SaColorsLight.warn : SaColorsDark.warn;

  // ── 텍스트 ────────────────────────────────────────────
  static Color get textPrimary =>
      isLight ? SaColorsLight.textPrimary : SaColorsDark.textPrimary;

  /// 보조 텍스트 (다크: white 55% / 라이트: 딥 슬레이트)
  static Color get textSecondary =>
      isLight ? SaColorsLight.textSecondary : SaColorsDark.textSecondary;

  /// 메타/타임스탬프 (다크: white 40% / 라이트: 연한 슬레이트)
  static Color get textTertiary =>
      isLight ? SaColorsLight.textTertiary : SaColorsDark.textTertiary;

  /// 포인트 버튼 위 텍스트
  static Color get onAccent =>
      isLight ? SaColorsLight.onAccent : SaColorsDark.onAccent;

  /// 시간대별 하늘을 쓰는 레거시 화면 위에 얹는 포인트 색.
  ///
  /// [nightFactor] 는 `SkyGradient.nightFactor(DateTime.now())` 값(밤 1.0 ~ 낮 0.0)이다.
  /// 낮에는 진한 민트로 내려가 밝은 하늘과 분리되고, 밤에는 밝은 민트로 올라가
  /// 어두운 하늘에서 떠오른다. 현재 홈·하단 탭은 밝은 표면용 토큰을 직접 쓴다.
  ///
  /// ⚠️ 일몰 구간(주황 하늘)은 어떤 포인트 색을 써도 대비가 낮아질 수 있다. 그 구간까지 확실히
  /// 하려면 색만 바꾸지 말고 칩·배지에 표면(흰색 또는 어두운 반투명)을 깔아야 한다.
  static Color accentOnSky(double nightFactor) => Color.lerp(
      accentSkyDay, SaColorsDark.accentTeal, nightFactor.clamp(0.0, 1.0))!;

  /// 밝은 표면 위 포인트 색.
  /// [accentOnSky]의 낮 끝점이며, 그라디언트용 [accentBlue]와 값이 같더라도 **의도가 다르므로**
  /// 따로 둔다(그라디언트 튜닝이 하늘 색을 흔들지 않게).
  static const Color accentSkyDay = SaColorsLight.accentTeal;

  /// 레거시 그라디언트 호출부도 단색 액션으로 표시한다.
  static LinearGradient get primaryGradient => LinearGradient(
        begin: const Alignment(-0.57, -0.82),
        end: const Alignment(0.57, 0.82),
        colors: [accentTeal, accentTeal],
      );
}

/// 라이트 팔레트 원본 상수 — 앨범 다크모드와 무관하게 항상 밝아야 하는 앱 전역 크롬
/// (전역 ThemeData, 하단 탭바, 공통 AppBar 등)에서 [SaColors]의 mutable `isLight` 상태를
/// 거치지 않고 직접 참조한다. `SaColors`의 라이트 분기와 값이 항상 동일해야 한다.
class SaColorsLight {
  SaColorsLight._();

  // 화이트 바탕 + 미세한 중립색 차이. 화면 전체를 포인트 색으로 물들이지 않는다.
  static const Color bgBase = Color(0xFFF6F8F8);
  static const Color surface = Color(0xFFFEFFFF);
  static const Color surfaceElevated = Color(0xFFEDF2F1);
  static const Color border = Color(0xFFE2E8E6);
  static const Color borderStrong = Color(0xFFCAD4D0);
  static const Color accentTeal = Color(0xFF00A26E);
  static const Color accentBlue = Color(0xFF008A62);
  static const Color accentSoft = Color(0xFFE4F6EF);
  static const Color accentPink = Color(0xFFC94361);
  static const Color warn = Color(0xFF995C14);
  static const Color textPrimary = Color(0xFF202725);
  static const Color textSecondary = Color(0xFF596560);
  static const Color textTertiary = Color(0xFF6A7670);
  static const Color onAccent = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-0.57, -0.82),
    end: Alignment(0.57, 0.82),
    colors: [accentTeal, accentTeal],
  );
}

/// 다크 팔레트 원본 상수 — 몰입뷰(영상 전체화면) 등 모드와 무관하게
/// 항상 어두워야 하는 화면에서 직접 참조한다.
class SaColorsDark {
  SaColorsDark._();

  // 영상 몰입 화면의 표면은 색기 없는 차콜로 유지한다.
  static const Color bgBase = Color(0xFF171B19);
  static const Color surface = Color(0xFF232925);
  static const Color surfaceElevated = Color(0xFF303832);
  static const Color border = Color(0x12FFFFFF);
  static const Color borderStrong = Color(0x1AFFFFFF);
  static const Color accentTeal = Color(0xFF64DDB3);
  static const Color accentBlue = Color(0xFF91E8CA);
  static const Color accentPink = Color(0xFFFF8CA4);
  static const Color warn = Color(0xFFFFC36E);
  static const Color textPrimary = Color(0xFFF4F8F5);
  static const Color textSecondary = Color(0x8CFFFFFF);
  static const Color textTertiary = Color(0x66FFFFFF);
  static const Color onAccent = Color(0xFF12382A);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-0.57, -0.82),
    end: Alignment(0.57, 0.82),
    colors: [accentTeal, accentTeal],
  );
}
