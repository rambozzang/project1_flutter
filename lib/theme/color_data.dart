import 'package:flutter/material.dart';

class ColorsData {
  // =============== 기본 테마 색상 (Light & Dark) =============== //

  // 배경 색상
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color primary = Color(0xFF262B49);
  static const Color secondary = Color(0xFFEA3799);
  static final Color grey50 = Colors.grey.shade50;
  static final Color grey100 = Colors.grey[100]!;
  static final Color grey200 = Colors.grey[200]!;
  static final Color grey300 = Colors.grey[300]!;

  // Dark 배경 색상
  static const Color darkPrimary = Color(0xFF121212);
  static const Color darkSecondary = Color(0xFF2C2C2C);
  static final Color darkGrey50 = Colors.grey.shade900;
  static final Color darkGrey100 = Colors.grey[800]!;
  static final Color darkGrey200 = Colors.grey[700]!;
  static final Color darkGrey300 = Colors.grey[600]!;

  // 텍스트 색상
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
  static const Color textAmber = Colors.amber;
  static const Color textYellow = Colors.yellow;
  static const Color textGreen = Colors.green;
  static const Color textBlue = Colors.blue;
  static const Color textPurple = Colors.purple;

  // Dark 텍스트 색상
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white70;
  static const Color darkTextGrey = Colors.grey;
  static const Color darkTextAmber = Color(0xFFFFE082); // 더 부드러운 amber
  static const Color darkTextYellow = Color(0xFFFFEE58); // 더 부드러운 yellow
  static const Color darkTextGreen = Color(0xFF81C784); // 더 부드러운 green
  static const Color darkTextBlue = Color(0xFF64B5F6); // 더 부드러운 blue
  static const Color darkTextPurple = Color(0xFFB39DDB); // 더 부드러운 purple

  // 아이콘 색상
  static const Color iconWhite = Colors.white;
  static const Color iconBlack = Colors.black;
  static const Color iconGrey = Colors.grey;
  static const Color iconRed = Colors.red;
  static const Color iconGreen = Colors.green;
  static const Color iconAmber = Colors.amber;
  static const Color iconPurple = Colors.purple;

  // Dark 아이콘 색상
  static const Color darkIconWhite = Colors.white70;
  static const Color darkIconGrey = Colors.grey;
  static const Color darkIconRed = Color(0xFFEF9A9A); // 더 부드러운 red
  static const Color darkIconGreen = Color(0xFF81C784); // 더 부드러운 green
  static const Color darkIconAmber = Color(0xFFFFE082); // 더 부드러운 amber
  static const Color darkIconPurple = Color(0xFFB39DDB); // 더 부드러운 purple

  // 테두리 색상
  static const Color borderGrey = Colors.grey;
  static const Color borderTransparent = Colors.transparent;
  static final Color borderLight = Colors.grey.withOpacity(0.5);

  // Dark 테두리 색상
  static const Color darkBorderGrey = Color(0xFF424242);
  static final Color darkBorderLight = Colors.grey.shade800;

  // 상태 색상
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  // Dark 상태 색상
  static const Color darkSuccess = Color(0xFF81C784);
  static const Color darkError = Color(0xFFEF9A9A);
  static const Color darkWarning = Color(0xFFFFB74D);
  static const Color darkInfo = Color(0xFF64B5F6);

  // 그라데이션 색상
  static const List<Color> primaryGradient = [
    Color(0xFF262B49),
    Color(0xFFEA3799),
  ];

  // Dark 그라데이션 색상
  static const List<Color> darkPrimaryGradient = [
    Color(0xFF121212),
    Color(0xFF2C2C2C),
  ];

  // =============== 공통 컴포넌트 색상 =============== //

  // 앱바 색상
  static const Color appBarBackground = Colors.white;
  static const Color appBarText = Colors.black;
  static const Color appBarIcon = Colors.black;

  // Dark 앱바 색상
  static const Color darkAppBarBackground = Color(0xFF121212);
  static const Color darkAppBarText = Colors.white;
  static const Color darkAppBarIcon = Colors.white;

  // 버튼 색상
  static const Color buttonPrimary = Colors.white12;
  static const Color buttonText = Colors.black87;
  static final Color buttonDisabled = Colors.grey[300]!;

  // Dark 버튼 색상
  static const Color darkButtonPrimary = Colors.black12;
  static const Color darkButtonText = Colors.white70;
  static final Color darkButtonDisabled = Colors.grey[800]!;

  // 입력필드 색상
  static final Color inputBackground = Colors.grey[100]!;
  static const Color inputText = Colors.black;
  static const Color inputLabel = Colors.black38;
  static const Color inputBorder = Colors.grey;

  // Dark 입력필드 색상
  static final Color darkInputBackground = Colors.grey[900]!;
  static const Color darkInputText = Colors.white;
  static const Color darkInputLabel = Colors.white38;
  static const Color darkInputBorder = Color(0xFF424242);

  // 칩/태그 색상
  static const Color chipBackground = Color.fromARGB(255, 140, 131, 221);
  static const Color chipText = Colors.white;
  static const Color chipBorder = Colors.transparent;

  // Dark 칩/태그 색상
  static const Color darkChipBackground = Color(0xFF2C2C2C);
  static const Color darkChipText = Colors.white70;
  static const Color darkChipBorder = Colors.transparent;

  // 로딩/인디케이터 색상
  static const Color loadingIndicator = Color(0xFFEA3799);
  static const Color progressBarActive = Colors.white;
  static const Color progressBarInactive = Colors.grey;

  // Dark 로딩/인디케이터 색상
  static const Color darkLoadingIndicator = Color(0xFF2C2C2C);
  static const Color darkProgressBarActive = Colors.white70;
  static const Color darkProgressBarInactive = Colors.grey;

  // 날씨 관련 색상
  static const Color weatherGood = Colors.blue;
  static const Color weatherNormal = Colors.green;
  static const Color weatherBad = Colors.orange;
  static const Color weatherVeryBad = Colors.red;

  // Dark 날씨 관련 색상
  static const Color darkWeatherGood = Color(0xFF64B5F6);
  static const Color darkWeatherNormal = Color(0xFF81C784);
  static const Color darkWeatherBad = Color(0xFFFFB74D);
  static const Color darkWeatherVeryBad = Color(0xFFEF9A9A);

  // 좋아요/댓글 색상
  static const Color likeActive = Colors.red;
  static const Color likeInactive = Colors.grey;
  static const Color commentIcon = Colors.black87;

  // Dark 좋아요/댓글 색상
  static const Color darkLikeActive = Color(0xFFEF9A9A);
  static const Color darkLikeInactive = Colors.grey;
  static const Color darkCommentIcon = Colors.white70;

  // 미디어 관련 색상
  static const Color youtubeRed = Colors.red;
  static const Color imageIcon = Colors.purple;
  static final Color thumbnailOverlay = Colors.black.withOpacity(0.5);

  // Dark 미디어 관련 색상
  static const Color darkYoutubeRed = Color(0xFFEF9A9A);
  static const Color darkImageIcon = Color(0xFFB39DDB);
  static final Color darkThumbnailOverlay = Colors.black.withOpacity(0.5);

  // 알림/경고 색상
  static final Color alertBackground = const Color.fromARGB(255, 237, 219, 240).withOpacity(0.15);
  static const Color alertIcon = Colors.red;
  static const Color alertText = Colors.yellow;

  // Dark 알림/경고 색상
  static final Color darkAlertBackground = const Color.fromARGB(255, 237, 219, 240).withOpacity(0.15);
  static const Color darkAlertIcon = Colors.red;
  static const Color darkAlertText = Colors.yellow;

  // =============== 불투명도 상수 =============== //
  static const double opacity12 = 0.12;
  static const double opacity15 = 0.15;
  static const double opacity30 = 0.3;
  static const double opacity50 = 0.5;
  static const double opacity70 = 0.7;

  // =============== 크기 상수 =============== //
  static const double iconSizeSmall = 12.0;
  static const double iconSizeMedium = 18.0;
  static const double iconSizeLarge = 24.0;

  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 20.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // =============== 애니메이션 지속 시간 =============== //
  static const Duration animationShort = Duration(milliseconds: 300);
  static const Duration animationMedium = Duration(milliseconds: 500);
  static const Duration animationLong = Duration(milliseconds: 1200);
}

extension ThemeColors on BuildContext {
  Color get grey200 => Theme.of(this).brightness == Brightness.light ? ColorsData.grey200 : ColorsData.darkGrey200;

  Color get textPrimary => Theme.of(this).brightness == Brightness.light ? ColorsData.textPrimary : ColorsData.darkTextPrimary;

  // ... 다른 색상들도 비슷하게 정의
}
