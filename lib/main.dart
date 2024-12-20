import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
// import 'package:media_kit/media_kit.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/chatting/supabase_options.dart';
import 'package:project1/common/life_cycle_getx.dart';
import 'package:project1/config/app_theme.dart';
// import 'package:project1/config/app_theme.dart';
import 'package:project1/firebase/firebase_service.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/route/app_route.dart';
import 'package:project1/theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// import com.kakao.sdk.common.util.Utility

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // MediaKit.ensureInitialized();

  // 카카오개발자센터 네이티브 앱키
  KakaoSdk.init(nativeAppKey: 'd0023f080e59afd633bc19e469ed4a73');
  // KakaoSdk.init(nativeAppKey: 'e94966b7ae7e09c06d47e9d9fa580f4c');

  // 광고 init
  await AdManager.initialize(targetPlatform: Platform.isIOS ? TargetPlatform.iOS : TargetPlatform.android);

  // supabase
  await Supabase.initialize(url: supabaseOptions.url, anonKey: supabaseOptions.anonKey);

  /// flutter run --dart-define=apiKey='Your Api Key'
//  Gemini.init(  apiKey: const String.fromEnvironment('apiKey'), enableDebugging: true);

  //v100004v@gmail.com
  // Gemini.init(apiKey: 'AIzaSyDSLGJFE9yZTeVt2xrtgnp6MTkE3LdYrCI', enableDebugging: true);

  // 안드로이드  : Network : CERTIFICATE_VERIFY_FAILED 오류 수정
  HttpOverrides.global = MyHttpOverrides();

  Get.put(ThemeController());

  runApp(const TigerBk());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class TigerBk extends StatelessWidget {
  const TigerBk({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "SkySnap",
      useInheritedMediaQuery: true,
      debugShowCheckedModeBanner: false,
      builder: BotToastInit(),
      theme: AppTheme.theme,
      // theme: AppTheme.light,
      // darkTheme: AppTheme.dark,
      // themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppPages.INITIAL,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthCntr());
        // Get.put(LifeCycleGetx());
        Get.put(WeatherGogoCntr());
      }),
      locale: const Locale('ko'),
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      getPages: AppPages.routes,
    );
  }
}
