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
          foregroundColor: SaColorsLight.textPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: SaColorsLight.textPrimary),
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
