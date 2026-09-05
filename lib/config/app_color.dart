import 'package:flutter/material.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';

class AppColor {
// 레거시 화면도 같은 민트 포인트를 공유한다.
  static const Color primaryColor = SaColorsLight.accentTeal;
  static const Color primaryColorLight = SaColorsLight.accentTeal;

// 진한색
  static const Color primaryColorDark = SaColorsLight.accentBlue;

// 컨테이너 색상
  static const Color containerColor = SaColorsLight.accentTeal;
  static const Color containerColorDark = SaColorsLight.accentBlue;
  static const Color containerColorLight = SaColorsLight.accentTeal;
}
