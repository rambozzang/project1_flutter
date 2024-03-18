import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/config/app_theme.dart';
import 'package:project1/route/app_route.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project1/utils/log_utils.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  KakaoSdk.init(
    nativeAppKey: '257e56e034badf50ce13baaa28018e7d',
    loggingEnabled: true,
  );

  // ...
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    log("main.dart >   Firebase.initializeApp 성공!!!");
  });

  // 안드로이드  : Network : CERTIFICATE_VERIFY_FAILED 오류 수정
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    GetMaterialApp(
      title: "Application",
      debugShowCheckedModeBanner: false,
      builder: BotToastInit(),
      theme: AppTheme.theme,
      initialRoute: AppPages.INITIAL,
      //initialBinding: BindingsBuilder(() {
      // Get.put(AuthCntr());
      //  Get.put(LoginController());
      //}),
      getPages: AppPages.routes,
    ),
  );
}

//   r 27, g 46, b 75

// 안드로이드  : Network CERTIFICATE_VERIFY_FAILED 오류 수정
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
