import 'package:flutter/material.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';

/// 앱 전역 테마 — "우리의 앨범" 디자인 토큰([SaColorsLight])을 그대로 승격해 쓴다.
/// 앨범 탭의 다크모드 설정과 무관하게 앱 전역 크롬은 항상 라이트이므로,
/// mutable한 [SaColors] 대신 고정값인 [SaColorsLight]를 참조한다.
class AppTheme {
  static ThemeData get theme => ThemeData(
        primaryColor: SaColorsLight.accentTeal,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SaColorsLight.accentTeal,
          brightness: Brightness.light,
          surface: SaColorsLight.surface,
          primary: SaColorsLight.accentTeal,
          onPrimary: SaColorsLight.onAccent,
          primaryContainer: SaColorsLight.accentSoft,
          onPrimaryContainer: SaColorsLight.accentBlue,
          secondary: SaColorsLight.accentTeal,
          onSecondary: SaColorsLight.onAccent,
          secondaryContainer: SaColorsLight.accentSoft,
          onSecondaryContainer: SaColorsLight.accentBlue,
          onSurface: SaColorsLight.textPrimary,
          onSurfaceVariant: SaColorsLight.textSecondary,
          surfaceContainer: SaColorsLight.bgBase,
          surfaceContainerHigh: SaColorsLight.surfaceElevated,
          surfaceTint: Colors.transparent,
          outline: SaColorsLight.borderStrong,
          outlineVariant: SaColorsLight.border,
        ),
        secondaryHeaderColor: SaColorsLight.accentBlue,
        highlightColor: SaColorsLight.surfaceElevated,
        useMaterial3: true,
        fontFamily: "Pretendard",
        scaffoldBackgroundColor: SaColorsLight.bgBase,
        appBarTheme: const AppBarTheme(
          backgroundColor: SaColorsLight.surface,
          // 아이콘 색은 여기서 고정하지 않는다. AppBar 는 `widget.iconTheme ??
          // appBarTheme.iconTheme ?? 기본값.copyWith(color: foregroundColor)` 순으로
          // 고르기 때문에, 테마에 iconTheme 을 박아 두면 **페이지가 준
          // `foregroundColor` 를 이깁니다.** 그래서 검은 앱바(실시간 레이더·위성영상)에
          // 흰 제목은 나오는데 뒤로가기 화살표만 짙은 잉크색으로 그려져 배경에 묻혔다
          // (2026-09-21). 지금은 foregroundColor 가 아이콘까지 정하므로 밝은 앱바는
          // 예전과 같은 잉크색, 어두운 앱바는 흰색이 된다.
          foregroundColor: SaColorsLight.textPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: SaColorsLight.surface,
          titleTextStyle: TextStyle(
            color: SaColorsLight.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: TextStyle(
            color: SaColorsLight.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
}
