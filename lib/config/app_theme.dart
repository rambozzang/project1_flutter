import 'package:flutter/material.dart';
import 'package:project1/config/app_color.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        primaryColor: AppColor.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          background: Colors.white,
        ),
        secondaryHeaderColor: AppColor.primaryColorLight,
        primarySwatch: Colors.red,
        highlightColor: Colors.white.withOpacity(0.25),
        useMaterial3: true,
        // fontFamily: "NotoSansKR",
        fontFamily: "Pretendard",
        dialogBackgroundColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
}
