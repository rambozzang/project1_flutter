import 'package:flutter/material.dart';
import 'package:project1/theme/color_data.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  // 기본 색상
  final Color grey50;
  final Color grey100;
  final Color grey200;
  final Color grey300;

  // 텍스트 색상
  final Color textPrimary;
  final Color textSecondary;
  final Color textWhite;
  final Color textGrey;
  final Color textAmber;
  final Color textYellow;
  final Color textGreen;
  final Color textBlue;
  final Color textPurple;

  // 아이콘 색상
  final Color iconWhite;
  final Color iconBlack;
  final Color iconGrey;
  final Color iconRed;
  final Color iconGreen;
  final Color iconAmber;
  final Color iconPurple;

  // 테두리 색상
  final Color borderGrey;
  final Color borderLight;

  // 상태 색상
  final Color success;
  final Color error;
  final Color warning;
  final Color info;

  // 컴포넌트 색상
  final Color appBarBackground;
  final Color appBarText;
  final Color appBarIcon;
  final Color buttonPrimary;
  final Color buttonText;
  final Color buttonDisabled;
  final Color inputBackground;
  final Color inputText;
  final Color inputLabel;
  final Color inputBorder;
  final Color chipBackground;
  final Color chipText;
  final Color chipBorder;

  // 로딩/인디케이터 색상
  final Color loadingIndicator;
  final Color progressBarActive;
  final Color progressBarInactive;

  // 날씨 관련 색상
  final Color weatherGood;
  final Color weatherNormal;
  final Color weatherBad;
  final Color weatherVeryBad;

  // 좋아요/댓글 색상
  final Color likeActive;
  final Color likeInactive;
  final Color commentIcon;

  // 미디어 관련 색상
  final Color youtubeRed;
  final Color imageIcon;
  final Color thumbnailOverlay;

  // 알림/경고 색상
  final Color alertBackground;
  final Color alertIcon;
  final Color alertText;

  const AppColors({
    // 기본 색상
    required this.grey50,
    required this.grey100,
    required this.grey200,
    required this.grey300,
    // 텍스트 색상
    required this.textPrimary,
    required this.textSecondary,
    required this.textWhite,
    required this.textGrey,
    required this.textAmber,
    required this.textYellow,
    required this.textGreen,
    required this.textBlue,
    required this.textPurple,
    // 아이콘 색상
    required this.iconWhite,
    required this.iconBlack,
    required this.iconGrey,
    required this.iconRed,
    required this.iconGreen,
    required this.iconAmber,
    required this.iconPurple,
    // 테두리 색상
    required this.borderGrey,
    required this.borderLight,
    // 상태 색상
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    // 컴포넌트 색상
    required this.appBarBackground,
    required this.appBarText,
    required this.appBarIcon,
    required this.buttonPrimary,
    required this.buttonText,
    required this.buttonDisabled,
    required this.inputBackground,
    required this.inputText,
    required this.inputLabel,
    required this.inputBorder,
    required this.chipBackground,
    required this.chipText,
    required this.chipBorder,
    // 로딩/인디케이터 색상
    required this.loadingIndicator,
    required this.progressBarActive,
    required this.progressBarInactive,
    // 날씨 관련 색상
    required this.weatherGood,
    required this.weatherNormal,
    required this.weatherBad,
    required this.weatherVeryBad,
    // 좋아요/댓글 색상
    required this.likeActive,
    required this.likeInactive,
    required this.commentIcon,
    // 미디어 관련 색상
    required this.youtubeRed,
    required this.imageIcon,
    required this.thumbnailOverlay,
    // 알림/경고 색상
    required this.alertBackground,
    required this.alertIcon,
    required this.alertText,
  });

  // Light Theme Colors
  static final light = AppColors(
    // 기본 색상
    grey50: ColorsData.grey50,
    grey100: ColorsData.grey100,
    grey200: ColorsData.grey200,
    grey300: ColorsData.grey300,
    // 텍스트 색상
    textPrimary: ColorsData.textPrimary,
    textSecondary: ColorsData.textSecondary,
    textWhite: ColorsData.textWhite,
    textGrey: ColorsData.textGrey,
    textAmber: ColorsData.textAmber,
    textYellow: ColorsData.textYellow,
    textGreen: ColorsData.textGreen,
    textBlue: ColorsData.textBlue,
    textPurple: ColorsData.textPurple,
    // 아이콘 색상
    iconWhite: ColorsData.iconWhite,
    iconBlack: ColorsData.iconBlack,
    iconGrey: ColorsData.iconGrey,
    iconRed: ColorsData.iconRed,
    iconGreen: ColorsData.iconGreen,
    iconAmber: ColorsData.iconAmber,
    iconPurple: ColorsData.iconPurple,
    // 테두리 색상
    borderGrey: ColorsData.borderGrey,
    borderLight: ColorsData.borderLight,
    // 상태 색상
    success: ColorsData.success,
    error: ColorsData.error,
    warning: ColorsData.warning,
    info: ColorsData.info,
    // 컴포넌트 색상
    appBarBackground: ColorsData.appBarBackground,
    appBarText: ColorsData.appBarText,
    appBarIcon: ColorsData.appBarIcon,
    buttonPrimary: ColorsData.buttonPrimary,
    buttonText: ColorsData.buttonText,
    buttonDisabled: ColorsData.buttonDisabled,
    inputBackground: ColorsData.inputBackground,
    inputText: ColorsData.inputText,
    inputLabel: ColorsData.inputLabel,
    inputBorder: ColorsData.inputBorder,
    chipBackground: ColorsData.chipBackground,
    chipText: ColorsData.chipText,
    chipBorder: ColorsData.chipBorder,
    // 로딩/인디케이터 색상
    loadingIndicator: ColorsData.loadingIndicator,
    progressBarActive: ColorsData.progressBarActive,
    progressBarInactive: ColorsData.progressBarInactive,
    // 날씨 관련 색상
    weatherGood: ColorsData.weatherGood,
    weatherNormal: ColorsData.weatherNormal,
    weatherBad: ColorsData.weatherBad,
    weatherVeryBad: ColorsData.weatherVeryBad,
    // 좋아요/댓글 색상
    likeActive: ColorsData.likeActive,
    likeInactive: ColorsData.likeInactive,
    commentIcon: ColorsData.commentIcon,
    // 미디어 관련 색상
    youtubeRed: ColorsData.youtubeRed,
    imageIcon: ColorsData.imageIcon,
    thumbnailOverlay: ColorsData.thumbnailOverlay,
    // 알림/경고 색상
    alertBackground: ColorsData.alertBackground,
    alertIcon: ColorsData.alertIcon,
    alertText: ColorsData.alertText,
  );

  // Dark Theme Colors
  static final dark = AppColors(
    // 기본 색상
    grey50: ColorsData.darkGrey50,
    grey100: ColorsData.darkGrey100,
    grey200: ColorsData.darkGrey200,
    grey300: ColorsData.darkGrey300,
    // 텍스트 색상
    textPrimary: ColorsData.darkTextPrimary,
    textSecondary: ColorsData.darkTextSecondary,
    textWhite: ColorsData.textWhite,
    textGrey: ColorsData.darkTextGrey,
    textAmber: ColorsData.darkTextAmber,
    textYellow: ColorsData.darkTextYellow,
    textGreen: ColorsData.darkTextGreen,
    textBlue: ColorsData.darkTextBlue,
    textPurple: ColorsData.darkTextPurple,
    // 아이콘 색상
    iconWhite: ColorsData.darkIconWhite,
    iconBlack: ColorsData.iconBlack,
    iconGrey: ColorsData.darkIconGrey,
    iconRed: ColorsData.darkIconRed,
    iconGreen: ColorsData.darkIconGreen,
    iconAmber: ColorsData.darkIconAmber,
    iconPurple: ColorsData.darkIconPurple,
    // 테두리 색상
    borderGrey: ColorsData.darkBorderGrey,
    borderLight: ColorsData.darkBorderLight,
    // 상태 색상
    success: ColorsData.darkSuccess,
    error: ColorsData.darkError,
    warning: ColorsData.darkWarning,
    info: ColorsData.darkInfo,
    // 컴포넌트 색상
    appBarBackground: ColorsData.darkAppBarBackground,
    appBarText: ColorsData.darkAppBarText,
    appBarIcon: ColorsData.darkAppBarIcon,
    buttonPrimary: ColorsData.darkButtonPrimary,
    buttonText: ColorsData.darkButtonText,
    buttonDisabled: ColorsData.darkButtonDisabled,
    inputBackground: ColorsData.darkInputBackground,
    inputText: ColorsData.darkInputText,
    inputLabel: ColorsData.darkInputLabel,
    inputBorder: ColorsData.darkInputBorder,
    chipBackground: ColorsData.darkChipBackground,
    chipText: ColorsData.darkChipText,
    chipBorder: ColorsData.darkChipBorder,
    // 로딩/인디케이터 색상
    loadingIndicator: ColorsData.darkLoadingIndicator,
    progressBarActive: ColorsData.darkProgressBarActive,
    progressBarInactive: ColorsData.darkProgressBarInactive,
    // 날씨 관련 색상
    weatherGood: ColorsData.darkWeatherGood,
    weatherNormal: ColorsData.darkWeatherNormal,
    weatherBad: ColorsData.darkWeatherBad,
    weatherVeryBad: ColorsData.darkWeatherVeryBad,
    // 좋아요/댓글 색상
    likeActive: ColorsData.darkLikeActive,
    likeInactive: ColorsData.darkLikeInactive,
    commentIcon: ColorsData.darkCommentIcon,
    // 미디어 관련 색상
    youtubeRed: ColorsData.darkYoutubeRed,
    imageIcon: ColorsData.darkImageIcon,
    thumbnailOverlay: ColorsData.darkThumbnailOverlay,
    // 알림/경고 색상
    alertBackground: ColorsData.darkAlertBackground,
    alertIcon: ColorsData.darkAlertIcon,
    alertText: ColorsData.darkAlertText,
  );

  @override
  ThemeExtension<AppColors> copyWith({
    Color? grey50,
    Color? grey100,
    Color? grey200,
    Color? grey300,
    Color? textPrimary,
    Color? textSecondary,
    Color? textWhite,
    Color? textGrey,
    Color? textAmber,
    Color? textYellow,
    Color? textGreen,
    Color? textBlue,
    Color? textPurple,
    Color? iconWhite,
    Color? iconBlack,
    Color? iconGrey,
    Color? iconRed,
    Color? iconGreen,
    Color? iconAmber,
    Color? iconPurple,
    Color? borderGrey,
    Color? borderLight,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? appBarBackground,
    Color? appBarText,
    Color? appBarIcon,
    Color? buttonPrimary,
    Color? buttonText,
    Color? buttonDisabled,
    Color? inputBackground,
    Color? inputText,
    Color? inputLabel,
    Color? inputBorder,
    Color? chipBackground,
    Color? chipText,
    Color? chipBorder,
    Color? loadingIndicator,
    Color? progressBarActive,
    Color? progressBarInactive,
    Color? weatherGood,
    Color? weatherNormal,
    Color? weatherBad,
    Color? weatherVeryBad,
    Color? likeActive,
    Color? likeInactive,
    Color? commentIcon,
    Color? youtubeRed,
    Color? imageIcon,
    Color? thumbnailOverlay,
    Color? alertBackground,
    Color? alertIcon,
    Color? alertText,
  }) {
    return AppColors(
      grey50: grey50 ?? this.grey50,
      grey100: grey100 ?? this.grey100,
      grey200: grey200 ?? this.grey200,
      grey300: grey300 ?? this.grey300,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textWhite: textWhite ?? this.textWhite,
      textGrey: textGrey ?? this.textGrey,
      textAmber: textAmber ?? this.textAmber,
      textYellow: textYellow ?? this.textYellow,
      textGreen: textGreen ?? this.textGreen,
      textBlue: textBlue ?? this.textBlue,
      textPurple: textPurple ?? this.textPurple,
      iconWhite: iconWhite ?? this.iconWhite,
      iconBlack: iconBlack ?? this.iconBlack,
      iconGrey: iconGrey ?? this.iconGrey,
      iconRed: iconRed ?? this.iconRed,
      iconGreen: iconGreen ?? this.iconGreen,
      iconAmber: iconAmber ?? this.iconAmber,
      iconPurple: iconPurple ?? this.iconPurple,
      borderGrey: borderGrey ?? this.borderGrey,
      borderLight: borderLight ?? this.borderLight,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      appBarBackground: appBarBackground ?? this.appBarBackground,
      appBarText: appBarText ?? this.appBarText,
      appBarIcon: appBarIcon ?? this.appBarIcon,
      buttonPrimary: buttonPrimary ?? this.buttonPrimary,
      buttonText: buttonText ?? this.buttonText,
      buttonDisabled: buttonDisabled ?? this.buttonDisabled,
      inputBackground: inputBackground ?? this.inputBackground,
      inputText: inputText ?? this.inputText,
      inputLabel: inputLabel ?? this.inputLabel,
      inputBorder: inputBorder ?? this.inputBorder,
      chipBackground: chipBackground ?? this.chipBackground,
      chipText: chipText ?? this.chipText,
      chipBorder: chipBorder ?? this.chipBorder,
      loadingIndicator: loadingIndicator ?? this.loadingIndicator,
      progressBarActive: progressBarActive ?? this.progressBarActive,
      progressBarInactive: progressBarInactive ?? this.progressBarInactive,
      weatherGood: weatherGood ?? this.weatherGood,
      weatherNormal: weatherNormal ?? this.weatherNormal,
      weatherBad: weatherBad ?? this.weatherBad,
      weatherVeryBad: weatherVeryBad ?? this.weatherVeryBad,
      likeActive: likeActive ?? this.likeActive,
      likeInactive: likeInactive ?? this.likeInactive,
      commentIcon: commentIcon ?? this.commentIcon,
      youtubeRed: youtubeRed ?? this.youtubeRed,
      imageIcon: imageIcon ?? this.imageIcon,
      thumbnailOverlay: thumbnailOverlay ?? this.thumbnailOverlay,
      alertBackground: alertBackground ?? this.alertBackground,
      alertIcon: alertIcon ?? this.alertIcon,
      alertText: alertText ?? this.alertText,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      grey50: Color.lerp(grey50, other.grey50, t)!,
      grey100: Color.lerp(grey100, other.grey100, t)!,
      grey200: Color.lerp(grey200, other.grey200, t)!,
      grey300: Color.lerp(grey300, other.grey300, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textWhite: Color.lerp(textWhite, other.textWhite, t)!,
      textGrey: Color.lerp(textGrey, other.textGrey, t)!,
      textAmber: Color.lerp(textAmber, other.textAmber, t)!,
      textYellow: Color.lerp(textYellow, other.textYellow, t)!,
      textGreen: Color.lerp(textGreen, other.textGreen, t)!,
      textBlue: Color.lerp(textBlue, other.textBlue, t)!,
      textPurple: Color.lerp(textPurple, other.textPurple, t)!,
      iconWhite: Color.lerp(iconWhite, other.iconWhite, t)!,
      iconBlack: Color.lerp(iconBlack, other.iconBlack, t)!,
      iconGrey: Color.lerp(iconGrey, other.iconGrey, t)!,
      iconRed: Color.lerp(iconRed, other.iconRed, t)!,
      iconGreen: Color.lerp(iconGreen, other.iconGreen, t)!,
      iconAmber: Color.lerp(iconAmber, other.iconAmber, t)!,
      iconPurple: Color.lerp(iconPurple, other.iconPurple, t)!,
      borderGrey: Color.lerp(borderGrey, other.borderGrey, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      appBarBackground: Color.lerp(appBarBackground, other.appBarBackground, t)!,
      appBarText: Color.lerp(appBarText, other.appBarText, t)!,
      appBarIcon: Color.lerp(appBarIcon, other.appBarIcon, t)!,
      buttonPrimary: Color.lerp(buttonPrimary, other.buttonPrimary, t)!,
      buttonText: Color.lerp(buttonText, other.buttonText, t)!,
      buttonDisabled: Color.lerp(buttonDisabled, other.buttonDisabled, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputText: Color.lerp(inputText, other.inputText, t)!,
      inputLabel: Color.lerp(inputLabel, other.inputLabel, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      chipText: Color.lerp(chipText, other.chipText, t)!,
      chipBorder: Color.lerp(chipBorder, other.chipBorder, t)!,
      loadingIndicator: Color.lerp(loadingIndicator, other.loadingIndicator, t)!,
      progressBarActive: Color.lerp(progressBarActive, other.progressBarActive, t)!,
      progressBarInactive: Color.lerp(progressBarInactive, other.progressBarInactive, t)!,
      weatherGood: Color.lerp(weatherGood, other.weatherGood, t)!,
      weatherNormal: Color.lerp(weatherNormal, other.weatherNormal, t)!,
      weatherBad: Color.lerp(weatherBad, other.weatherBad, t)!,
      weatherVeryBad: Color.lerp(weatherVeryBad, other.weatherVeryBad, t)!,
      likeActive: Color.lerp(likeActive, other.likeActive, t)!,
      likeInactive: Color.lerp(likeInactive, other.likeInactive, t)!,
      commentIcon: Color.lerp(commentIcon, other.commentIcon, t)!,
      youtubeRed: Color.lerp(youtubeRed, other.youtubeRed, t)!,
      imageIcon: Color.lerp(imageIcon, other.imageIcon, t)!,
      thumbnailOverlay: Color.lerp(thumbnailOverlay, other.thumbnailOverlay, t)!,
      alertBackground: Color.lerp(alertBackground, other.alertBackground, t)!,
      alertIcon: Color.lerp(alertIcon, other.alertIcon, t)!,
      alertText: Color.lerp(alertText, other.alertText, t)!,
    );
  }
}
