import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
// import 'package:media_kit/media_kit.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/app/achievement/service/achievement_service.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/config/app_theme.dart';
import 'package:project1/firebase/firebase_service.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/route/app_route.dart';
import 'package:project1/services/deep_link_service.dart';
import 'package:project1/services/weather_notification_service.dart';
import 'package:project1/subscript_service.dart';
import 'package:project1/utils/WeatherLottie.dart';
import 'package:project1/widget/global_upload_indicator.dart';
import 'package:workmanager/workmanager.dart';
// import 'package:project1/theme/app_theme.dart';

// import com.kakao.sdk.common.util.Utility

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 전체 세로 화면 고정(가로 회전 비활성화)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 하단 시스템 내비게이션 바를 불투명 흰색으로(앱 콘텐츠 비침 방지).
  // Android 14 이하는 이 색상이 그대로 적용되고, Android 15/16(targetSdk 36)에선
  // OS가 색상을 무시하므로 GetMaterialApp.builder 에서 내비바 뒤에 흰 배경을 직접 깐다.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarDividerColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // MediaKit.ensureInitialized();

  // 카카오개발자센터 네이티브 앱키
  KakaoSdk.init(nativeAppKey: 'd0023f080e59afd633bc19e469ed4a73');
  // KakaoSdk.init(nativeAppKey: 'e94966b7ae7e09c06d47e9d9fa580f4c');

  // // 광고 init — 시작(첫 화면)을 막지 않도록 백그라운드로. 광고는 피드 진입 시점엔 이미 준비됨.
  unawaited(AdManager.initialize(targetPlatform: Platform.isIOS ? TargetPlatform.iOS : TargetPlatform.android));

  // 날씨 상태바 알림(Android): WorkManager 백그라운드 콜백 등록. 시작을 막지 않도록 비대기.
  if (Platform.isAndroid) {
    unawaited(Workmanager().initialize(weatherNotiDispatcher));
  }

  // 날씨 Lottie 아이콘 사전 로딩(백그라운드) — 24시·주간 진입 시 첫 파싱 지연 완화. 시작을 막지 않도록 비대기.
  unawaited(WeatherLottie.precacheAllAnimations());

  /// flutter run --dart-define=apiKey='Your Api Key'
//  Gemini.init(  apiKey: const String.fromEnvironment('apiKey'), enableDebugging: true);

  //v100004v@gmail.com
  // Gemini.init(apiKey: 'AIzaSyDSLGJFE9yZTeVt2xrtgnp6MTkE3LdYrCI', enableDebugging: true);

  // 안드로이드  : Network : CERTIFICATE_VERIFY_FAILED 오류 수정
  HttpOverrides.global = MyHttpOverrides();

  // Get.put(ThemeController());

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
      builder: (context, child) {
        // 1) bot_toast 초기화 유지
        final Widget content = BotToastInit()(context, child);
        // 2) [Android 전용] Android 15/16(targetSdk 36)은 edge-to-edge 강제 + 내비바 색 무시 →
        //    하단 시스템 내비게이션 바 높이만큼 불투명 흰 배경을 직접 깔아 앱이 비치는 것을 막는다.
        //    iOS는 홈 인디케이터가 하단 탭바와 겹쳐 문제가 되므로 적용하지 않는다(iOS엔 이 문제 자체가 없음).
        final double navBarInset = Platform.isAndroid ? MediaQuery.of(context).viewPadding.bottom : 0;
        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            Positioned.fill(child: content),
            if (navBarInset > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: navBarInset,
                child: const IgnorePointer(child: ColoredBox(color: Colors.white)),
              ),
            // 3) 업로드 전역 인디케이터 — 루트 위에 푸시된 화면(앨범 상세/몰입 등)에서도 보이도록
            //    Navigator보다 위(모든 라우트 위)에 얹는다. (기존 root_page Stack 위치에서 승격)
            const Positioned(top: 100, right: 20, child: GlobalUploadIndicator()),
          ],
        );
      },
      theme: AppTheme.theme,
      // theme: AppTheme.light,
      // darkTheme: AppTheme.dark,
      // themeMode: _.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppPages.INITIAL,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthCntr());
        // 업적 알림 루프(업로드/로그인 시 새 업적 감지 → 다이얼로그/배지). 앱 전역 상주.
        Get.put(AchievementService(), permanent: true);
        // Get.put(LifeCycleGetx());
        Get.put(WeatherGogoCntr());
        // 프리미엄 구독(IAP) 상태 관리 — 앱 전역 상주.
        Get.put(SubscriptionService.instance, permanent: true);
        // 앨범(커뮤니티) 초대 딥링크 - AuthCntr 등록 이후 초기화(로그인 상태 리스닝 필요).
        DeepLinkService.instance.initialize();
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
