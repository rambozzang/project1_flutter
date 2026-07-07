import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:project1/firebase_options.dart';
import 'package:project1/route/app_route.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 백그라운드 클릭시
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Lo.g("_firebaseMessagingBackgroundHandler");
}

// 포그라운 클릭시
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) async {
  Lo.g("notificationTapBackground");

  var message = jsonDecode(details.payload!);
  _processMessageData(message);
}

@pragma('vm:entry-point')
void backgroundHandler(NotificationResponse details) {
  Lo.g("backgroundHandler");
  var message = jsonDecode(details.payload!);
}

void _processMessageData(Map<String, dynamic> messageData) async {
  Lo.g("getInitialMessage");
  Lo.g("onMessage : ${messageData.toString()}");
  final boardId = messageData["boardId"];
  final receiveCustId = messageData["receiveCustId"];
  final reportId = messageData["reportId"]?.toString();

  // 앨범 초대: communityId로 앨범 페이지 이동
  if (messageData["type"] == "COMMUNITY_INVITE") {
    final communityId = messageData["communityId"];
    Lo.g("COMMUNITY_INVITE: communityId=$communityId");
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.toNamed('/CommunityHomePage', arguments: {'communityId': communityId});
    });
    return;
  }

  // 날씨 이벤트(20): boardId가 없으므로 아래 가드보다 먼저 처리(칼메라 진입).
  if (messageData["alramCd"] == '20') {
    Future.delayed(const Duration(milliseconds: 300), () => AppPages.goRoute('20', '', null));
    return;
  }

  // 기상 특보(30): reportId로 특보 상세 페이지 이동.
  if (messageData["alramCd"] == '30') {
    Future.delayed(const Duration(milliseconds: 300), () => AppPages.goRoute('30', '', null, reportId: reportId));
    return;
  }

  if (boardId == "" || boardId == null || boardId == 'null') {
    return;
  }
  Future.delayed(const Duration(milliseconds: 300), () async => AppPages.goRoute(messageData["alramCd"], receiveCustId, boardId.toString())
      //Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()})
      );
  // Future.delayed(
  //     const Duration(milliseconds: 300),
  //     () async =>
  //         Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()}));
}

class FirebaseService {
  late DarwinInitializationSettings initializationSettingsDarwin;
  Future<void> initialize() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    _setupFirebaseMessaging();
    initializeLocalNotifications();
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    initializationSettingsDarwin = DarwinInitializationSettings(
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

    //  terminated 상태에서 클릭시
    // FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) async {
    //   Future.delayed(const Duration(seconds: 3)).then((value) => terminatedMessageclick(message));
    // });
    // 바로 위 형태로는 안되고 아래 형태로 구현해야함.
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 400)).then((value) => terminatedMessageclick(initialMessage));
    }

    // foreground 상태에서 메시지를 수신할 때
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (Platform.isIOS) {
        return;
      }
      forgroundMessage(message);
    });

    // background 상태에서 클릭시
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      backgroundMessageclick(message);
    });

    // forgraound 에서 클릭시
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings("@mipmap/ic_launcher"),
        iOS: initializationSettingsDarwin,
      ),
      onDidReceiveNotificationResponse: notificationTapBackground,
      // onDidReceiveBackgroundNotificationResponse: backgroundHandler,
    );
  }

  void initializeLocalNotifications() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
        ));

    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
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
  }

  void forgroundMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    Lo.g("=======================================================");
    Lo.g("======. foreground 수신처리. =========");
    Lo.g("=======================================================");
    Lo.g("onMessage : ${message.notification.toString()}");
    Lo.g("onMessage : ${message.data.toString()}");
    Lo.g("onMessage title: ${notification?.title.toString()}");
    Lo.g("onMessage body: ${notification?.body.toString()}");

    if (notification == null) {
      Lo.g("onMessage null : ${message.notification}");
      return;
    }
    Lo.g("onMessage body 1");

    String alramCd = message.data["alramCd"] ?? '99';
    Lo.g("onMessage body 2");

    // 포그라운드에서 알람 07 일때 채널명을 완전 썡뚱맞는걸로 하니 노티가 안뜨고 상태바에서만 들어옴.
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      alramCd == '07' ? 'tigerbk_channel' : 'high_importance_channel',
      'high_importance_notification',
      priority: alramCd == '07' ? Priority.low : Priority.high,
      importance: alramCd == '07' ? Importance.low : Importance.high,
      channelDescription: "Skysanp Importance notification",
      icon: '@mipmap/ic_launcher',
      showWhen: alramCd == '07' ? false : true,
      groupKey: 'com.skysnap.skysnap',
      // groupKey: alramCd == '07' ? 'com.skysnap.skysnap' : null,
      groupAlertBehavior: GroupAlertBehavior.all,
      onlyAlertOnce: alramCd == '07' ? true : false,
      setAsGroupSummary: alramCd == '07' ? true : false,
      styleInformation: InboxStyleInformation(
        [], // Add lines for each message
        contentTitle: '새로운 메세지들이 있습니다.',
        summaryText: '${message.notification?.title}: ${message.notification?.body}',
      ),

      largeIcon: StringUtils.isEmpty(message.data["senderProfilePath"])
          ? null
          : FilePathAndroidBitmap(await downloadAndSaveFile(message.data["senderProfilePath"], 'largeIcon')),
    );
    Lo.g("onMessage body 3");

    // Ios specific settings
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(badgeNumber: 1, threadIdentifier: 'com.skysnap.skysnap');
    Lo.g("onMessage body 4");

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidNotificationDetails, iOS: iOSPlatformChannelSpecifics),
      payload: jsonEncode(message.data),
    );
  }

  void backgroundMessageclick(RemoteMessage message) async {
    Lo.g("onMessageOpenedApp");
    Lo.g("onMessage : ${message.data.toString()}");

    // 앨범 초대
    if (message.data["type"] == "COMMUNITY_INVITE") {
      final communityId = message.data["communityId"];
      Lo.g("COMMUNITY_INVITE (background): communityId=$communityId");
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.toNamed('/CommunityHomePage', arguments: {'communityId': communityId});
      });
      return;
    }

    if (message.notification != null) {
      final boardId = message.data["boardId"];
      final receiveCustId = message.data["receiveCustId"];
      final reportId = message.data["reportId"]?.toString();

      // 날씨 이벤트(20): boardId 없이 칼메라 진입(가드보다 먼저).
      if (message.data["alramCd"] == '20') {
        Future.delayed(const Duration(milliseconds: 500), () => AppPages.goRoute('20', '', null));
        return;
      }

      // 기상 특보(30): reportId로 특보 상세 페이지 이동.
      if (message.data["alramCd"] == '30') {
        Future.delayed(const Duration(milliseconds: 500), () => AppPages.goRoute('30', '', null, reportId: reportId));
        return;
      }

      if (boardId == "" || boardId == null || boardId == 'null') {
        return;
      }

      Future.delayed(
          const Duration(milliseconds: 800), () async => AppPages.goRoute(message.data["alramCd"], receiveCustId, boardId.toString())
          //Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()})
          );
    }
  }

  void terminatedMessageclick(RemoteMessage? message) async {
    Lo.g("getInitialMessage");
    Lo.g("onMessage : ${message?.data.toString()}");

    // 앨범 초대
    if (message?.data["type"] == "COMMUNITY_INVITE") {
      final communityId = message!.data["communityId"];
      Lo.g("COMMUNITY_INVITE (terminated): communityId=$communityId");
      Future.delayed(const Duration(milliseconds: 1500), () {
        Get.toNamed('/CommunityHomePage', arguments: {'communityId': communityId});
      });
      return;
    }

    final boardId = message!.data["boardId"];
    final receiveCustId = message.data["receiveCustId"];
    final reportId = message.data["reportId"]?.toString();

    // 날씨 이벤트(20): boardId 없이 칼메라 진입(가드보다 먼저).
    if (message.data["alramCd"] == '20') {
      Future.delayed(const Duration(milliseconds: 1500), () => AppPages.goRoute('20', '', null));
      return;
    }

    // 기상 특보(30): reportId로 특보 상세 페이지 이동.
    if (message.data["alramCd"] == '30') {
      Future.delayed(const Duration(milliseconds: 1500), () => AppPages.goRoute('30', '', null, reportId: reportId));
      return;
    }

    if (boardId == "" || boardId == null || boardId == 'null') {
      return;
    }
    Future.delayed(
        const Duration(milliseconds: 3000), () async => AppPages.goRoute(message.data["alramCd"], receiveCustId, boardId.toString())
        //Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()})
        );
    // Future.delayed(
    //     const Duration(milliseconds: 3000),
    //     () async =>
    //         Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()}));
  }

  Future<String> downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
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
