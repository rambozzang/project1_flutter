import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/list/cntr/video_list_cntr.dart';
import 'package:project1/app/list/video_list_page.dart';
import 'package:project1/common/life_cycle_getx.dart';
import 'package:project1/config/app_theme.dart';
import 'package:project1/route/app_route.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project1/utils/log_utils.dart';
import 'firebase_options.dart';

// fcm 배경 처리 (종료되어있거나, 백그라운드에 경우)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("#### _firebaseMessagingBackgroundHandler : ");
}

@pragma('vm:entry-point')
void backgroundHandler(NotificationResponse details) {
  debugPrint("#### backgroundHandler :  ${details.payload!.toString()}");
}

//FCM 위젯
void showFcmNoti(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  // AndroidNotification? android = message.notification?.android;
  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'high_importance_channel', 'high_importance_notification',
      priority: Priority.max,
      importance: Importance.max,
      channelDescription: "KOS Importance notification",
      icon: '@mipmap/ic_launcher',
      showWhen: false);

  if (notification != null && !kIsWeb) {
    // var seq = message.data["seq"];
    Lo.g("### main_page  showFlutterNotification :  notification.hashCode : ${notification.hashCode}");
    // 웹이 아니면서 안드로이드이고, 알림이 있는경우
    FlutterLocalNotificationsPlugin().show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidNotificationDetails, iOS: DarwinNotificationDetails(badgeNumber: 1)),
    );
  }
}

void initializeFCM() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
          const AndroidNotificationChannel('high_importance_channel', 'high_importance_notification', importance: Importance.max));

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

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
      debugPrint("onDidReceiveNotificationResponse : ${details.payload}");
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

  // foreground 수신처리
  FirebaseMessaging.onMessage.listen((message) {
    Lo.g("onMessage");
    RemoteNotification? notification = message.notification;

    Lo.g("onMessage : ${message.notification.toString()}");

    Lo.g("onMessage : ${message.notification?.title.toString()}");
    Lo.g("onMessage : ${message.notification?.body.toString()}");
    Lo.g("onMessage : ${message.data.toString()}");

    if (notification != null) {
      showFcmNoti(message); // 로컬노티
    }
  });

  // 알림 클릭시
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint("onMessageOpenedApp");
    if (message.notification != null) {
      final routeFromMessage = message.data["url"];
      debugPrint("onMessageOpenedApp : $routeFromMessage");
      Get.toNamed("/demo");
    }
  });
  //앱이 완전히 종료된 상태에서 클릭시
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    debugPrint("getInitialMessage");
    // 로컬노티
    if (message != null) {
      debugPrint("getInitialMessage : $message}");
      //   showFlutterNotification(message);
      final routeFromMessage = message.data["url"];
      debugPrint("getInitialMessage : $routeFromMessage");
      Get.toNamed("/demo");
    }
  });
  // String? firebaseToken = await FirebaseMessaging.instance.getToken();
  // debugPrint("firebaseToken : $firebaseToken");
}

// Future<void> initGet() async {
//   Get.put(() => LifeCycleGetx());
//   Get.put(() => AuthCntr());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //fcm Setting
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  initializeFCM();

  KakaoSdk.init(
    nativeAppKey: '257e56e034badf50ce13baaa28018e7d',
    loggingEnabled: true,
  );

  // ...
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    lo.g("main.dart >   Firebase.initializeApp 성공!!!");
  });

  // 안드로이드  : Network : CERTIFICATE_VERIFY_FAILED 오류 수정
  HttpOverrides.global = MyHttpOverrides();

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
        Get.put(LifeCycleGetx());
        Get.put(AuthCntr());
      }),
      getPages: AppPages.routes,
    );
  }
}
