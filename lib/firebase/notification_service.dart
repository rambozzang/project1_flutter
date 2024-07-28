// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static final NotificationService _notificationService = NotificationService._internal();

//   factory NotificationService() {
//     return _notificationService;
//   }

//   NotificationService._internal();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   final List<String> _messages = [];

//   Future<void> init() async {
//     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }

//   Future<void> showGroupedNotifications(String title, String body) async {
//     _messages.add(body);

//     const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
//       'grouped channel id',
//       'grouped channel name',
//       importance: Importance.max,
//       priority: Priority.high,
//       groupKey: 'com.codelabtiger.skysnap.chatting',
//       setAsGroupSummary: true,
//     );

//     const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

//     await flutterLocalNotificationsPlugin.show(
//       0,
//       title,
//       'You have ${_messages.length} new messages',
//       platformChannelSpecifics,
//     );

//     for (int i = 0; i < _messages.length; i++) {
//       await flutterLocalNotificationsPlugin.show(
//         i + 1,
//         'Message ${i + 1}',
//         _messages[i],
//         platformChannelSpecifics,
//       );
//     }
//   }
// }
