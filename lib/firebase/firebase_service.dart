import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:project1/app/chatting/chat_room_page.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:project1/app/chatting/lib/flutter_supabase_chat_core.dart';
import 'package:project1/firebase_options.dart';
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

  // 대화하기인 경우
  if (messageData["alramCd"] == '07') {
    types.User otherUser = types.User(
      id: messageData["senderCustId"].toString(),
      firstName: messageData["senderNickNm"].toString(),
      imageUrl: messageData["senderProfilePath"].toString(),
    );

    final room = await SupabaseChatCore.instance.createRoom(otherUser);

    Future.delayed(const Duration(milliseconds: 300), () async => Get.to(ChatPage(room: room)));
  }

  if (boardId == "" || boardId == null || boardId == 'null') {
    return;
  }

  Future.delayed(
      const Duration(milliseconds: 300),
      () async =>
          Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()}));
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
        android: const AndroidInitializationSettings("@mipmap/skysnap"),
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
    // 채팅중인 경우는 노티를 띄우지 않는다. - 보낸사람과 채팅중일때로 수정이 필요함.
    // #### 07번일때는 senderCustId 는 chatId 로 넘어온다. ####
    if (alramCd == '07' && Get.currentRoute == '/ChatPage' && message.data["senderCustId"] == AuthCntr.to.currentChatId) {
      return;
    }
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

      largeIcon: message.data["senderProfilePath"] != null
          ? FilePathAndroidBitmap(await downloadAndSaveFile(message.data["senderProfilePath"], 'largeIcon'))
          : null,
    );
    Lo.g("onMessage body 3");

    // Ios specific settings
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(badgeNumber: 1, threadIdentifier: 'com.skysnap.skysnap');
    Lo.g("onMessage body 4");

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification!.title,
      notification.body,
      NotificationDetails(android: androidNotificationDetails, iOS: iOSPlatformChannelSpecifics),
      payload: jsonEncode(message.data),
    );
  }

  void backgroundMessageclick(RemoteMessage message) async {
    Lo.g("onMessageOpenedApp");
    Lo.g("onMessage : ${message.data.toString()}");
    if (message.notification != null) {
      final boardId = message.data["boardId"];
      final receiveCustId = message.data["receiveCustId"];

      // 대화하기인 경우
      if (message.data["alramCd"] == '07') {
        types.User otherUser = types.User(
          id: message.data["senderCustId"].toString(),
          firstName: message.data["senderNickNm"].toString(),
          imageUrl: message.data["senderProfilePath"].toString(),
        );

        final room = await SupabaseChatCore.instance.createRoom(otherUser);
        Get.to(ChatPage(room: room));
      }

      if (boardId == "" || boardId == null || boardId == 'null') {
        return;
      }

      Future.delayed(
          const Duration(milliseconds: 800),
          () async =>
              Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()}));
    }
  }

  void terminatedMessageclick(RemoteMessage? message) async {
    Lo.g("getInitialMessage");
    Lo.g("onMessage : ${message?.data.toString()}");

    final boardId = message!.data["boardId"];
    final receiveCustId = message.data["receiveCustId"];

    // 대화하기인 경우
    if (message.data["alramCd"] == '07') {
      types.User otherUser = types.User(
        id: message.data["senderCustId"].toString(),
        firstName: message.data["senderNickNm"].toString(),
        imageUrl: message.data["senderProfilePath"].toString(),
      );

      final room = await SupabaseChatCore.instance.createRoom(otherUser);

      Future.delayed(const Duration(milliseconds: 3000), () async => Get.to(ChatPage(room: room)));
    }

    if (boardId == "" || boardId == null || boardId == 'null') {
      return;
    }

    Future.delayed(
        const Duration(milliseconds: 3000),
        () async =>
            Get.toNamed('/VideoMyinfoListPage', arguments: {'datatype': 'ONE', 'custId': receiveCustId, 'boardId': boardId.toString()}));
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
