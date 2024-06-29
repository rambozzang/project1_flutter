import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/chatting/supabase_options.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:project1/common/life_cycle_getx.dart';
import 'package:project1/config/app_theme.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/route/app_route.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project1/utils/log_utils.dart';
import 'firebase_options.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// final StreamController<ReceivedNotification> didReceiveLocalNotificationStream = StreamController<ReceivedNotification>.broadcast();

// fcm 배경 처리 (종료되어있거나, 백그라운드에 경우)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Lo.g("#### _firebaseMessagingBackgroundHandler : ");
}

@pragma('vm:entry-point')
void backgroundHandler(NotificationResponse details) {
  Lo.g("#### backgroundHandler :  ${details.payload!.toString()}");
}

void initializeFCM() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
          const AndroidNotificationChannel('high_importance_channel', 'high_importance_notification', importance: Importance.max));

  final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
      // didReceiveLocalNotificationStream.add(
      //   ReceivedNotification(
      //     id: id,
      //     title: title,
      //     body: body,
      //     payload: payload,
      //   ),
      // );
    },
    // notificationCategories: darwinNotificationCategories,
  );

  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(
      android: const AndroidInitializationSettings("@mipmap/ic_launcher"),
      iOS: initializationSettingsDarwin,
    ),
    onDidReceiveNotificationResponse: (details) {
      // 액션 추가...
      Lo.g("onDidReceiveNotificationResponse : ${details.payload}");
      Get.toNamed("/demo");
    },
    onDidReceiveBackgroundNotificationResponse: backgroundHandler,
  );

  if (Platform.isIOS) {
    // iOS foreground notification 권한
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // IOS background 권한 체킹 , 요청
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // String? firebaseToken = await FirebaseMessaging.instance.getToken();
  // Lo.g("firebaseToken : $firebaseToken");
}

Future<String> downloadAndSaveFile(String url, String fileName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/$fileName';
  final http.Response response = await http.get(Uri.parse(url));
  final File file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  //fcm Setting
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    lo.g("main.dart >   Firebase.initializeApp 성공!!!");
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  initializeFCM();

  // 카카오개발자센터 네이티브 앱키
  KakaoSdk.init(
    nativeAppKey: 'd0023f080e59afd633bc19e469ed4a73',
    loggingEnabled: true,
  );

  // 광고 init
  if (Platform.isIOS) {
    AdManager.init(targetPlatform: TargetPlatform.iOS);
  } else if (Platform.isAndroid) {
    AdManager.init(targetPlatform: TargetPlatform.android);
  }
  //  MobileAds.instance.initialize();

  // supabase
  await Supabase.initialize(
    url: supabaseOptions.url,
    anonKey: supabaseOptions.anonKey,
    debug: true,
  ).then((onValue) {
    lo.g("main.dart >   Supabase.initialize 성공!!!");
  });

  // 안드로이드  : Network : CERTIFICATE_VERIFY_FAILED 오류 수정
  HttpOverrides.global = MyHttpOverrides();

  // foreground 수신처리
  FirebaseMessaging.onMessage.listen((message) async {
    RemoteNotification? notification = message.notification;
    Lo.g("=======================================================");
    Lo.g("======. foreground 수신처리. =========");
    Lo.g("=======================================================");
    Lo.g("onMessage : ${message.notification.toString()}");
    Lo.g("onMessage : ${message.notification?.title.toString()}");
    Lo.g("onMessage : ${message.notification?.body.toString()}");
    Lo.g("onMessage : ${message.data.toString()}");
    Lo.g("onMessage : ${message.data["senderProfilePath"]}");

    if (notification != null) {
      // AndroidNotification? android = message.notification?.android;
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'high_importance_notification',
        priority: Priority.max,
        importance: Importance.max,
        channelDescription: "KOS Importance notification",
        icon: '@mipmap/skysnap',
        showWhen: false,
        largeIcon: message.data["senderProfilePath"] != ""
            ? FilePathAndroidBitmap(await downloadAndSaveFile(message.data["senderProfilePath"], 'largeIcon'))
            : null,
      );

      if (notification != null && !kIsWeb) {
        // var seq = message.data["seq"];
        Lo.g("### main_page  showFlutterNotification :  notification.hashCode : ${notification.hashCode}");
        // 웹이 아니면서 안드로이드이고, 알림이 있는경우
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(android: androidNotificationDetails, iOS: DarwinNotificationDetails(badgeNumber: 1)),
        );
      }
    }
  });

  // 알림 클릭시
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    Lo.g("onMessageOpenedApp");
    if (message.notification != null) {
      final boardId = message.data["boardId"];
      final senderCustId = message.data["senderCustId"];
      final followCustId = message.data["followCustId"];
      final receiveCustId = message.data["receiveCustId"];
      if (boardId == "" || boardId == null) {
        return;
      }
      Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()});
    }
  });
  //앱이 완전히 종료된 상태에서 클릭시
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    Lo.g("getInitialMessage");

    // 로컬노티
    if (message != null) {
      final boardId = message.data["boardId"];
      final senderCustId = message.data["senderCustId"];
      final followCustId = message.data["followCustId"];
      final receiveCustId = message.data["receiveCustId"];
      if (boardId == "" || boardId == null) {
        return;
      }

      Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()});
    }
  });
  FlutterNativeSplash.remove();
  runApp(const TigerBk());
}

// 안드로이드  : Network CERTIFICATE_VERIFY_FAILED 오류 수정
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
      title: "Application",
      useInheritedMediaQuery: true,
      debugShowCheckedModeBanner: false,
      builder: BotToastInit(),
      theme: AppTheme.theme,
      initialRoute: AppPages.INITIAL,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthCntr());
        Get.put(LifeCycleGetx());
        Get.put(WeatherCntr());
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

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}
