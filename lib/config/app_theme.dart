import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/config/app_color.dart';
import 'package:project1/repo/weather/data/Sys.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        primaryColor: AppColor.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          background: Colors.white,
        ),
        secondaryHeaderColor: AppColor.primaryColorLight,
        primarySwatch: Colors.red,
        highlightColor: Colors.white,
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
        // appBarTheme: const AppBarTheme(
        //   //     backgroundColor: Colors.white,
        //   //    foregroundColor: Colors.black,
        //   // systemOverlayStyle: SystemUiOverlayStyle(
        //   //   statusBarColor: Colors.white,
        //   //   statusBarIconBrightness: Brightness.dark,
        //   // ),
        //   elevation: 0,
        //   iconTheme: IconThemeData(color: Colors.black),
        //   titleTextStyle: TextStyle(
        //     color: Colors.black,
        //     fontSize: 18,
        //     fontWeight: FontWeight.w700,
        //   ),
        // ),
      );
}
