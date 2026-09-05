import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:project1/utils/log_utils.dart';

/// 게시 완료를 기기 알림으로 알린다.
///
/// 파일 전송은 OS가 백그라운드에서 끝내고, 게시는 Dart 가 전송 완료를 폴링해 서버에
/// 저장한다. 이 마지막 단계가 사용자가 앱을 떠난 뒤 끝나면 알 길이 없었다 — 서버에는
/// 작성자 본인에게 가는 푸시가 없고(알림 코드표 ALRAM 에 없음), 앱에도 완료 알림이 없었다.
///
/// 전면(resumed)에 있을 때는 전역 인디케이터가 이미 보여주므로 띄우지 않는다.
/// 플러그인 초기화(탭 핸들러 등)는 `firebase_service.dart` 가 이미 해 두었고,
/// [FlutterLocalNotificationsPlugin] 은 싱글턴이라 여기서 새로 만들어도 같은 인스턴스다.
class UploadNotifier {
  UploadNotifier._();

  static const String channelId = 'skysnap_upload_result';
  static const String channelName = '업로드 완료';
  static const String channelDescription = '사진·영상 게시가 끝나면 알려드려요';

  /// 고정 ID — 연속으로 게시해도 알림이 쌓이지 않고 마지막 것으로 갱신된다.
  static const int notificationId = 0x5B10AD;

  static const String title = '게시가 완료됐어요';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 전면이 아닐 때만 알린다. null 은 첫 프레임 전이거나 OS 가 백그라운드에서 깨운
  /// 직후라 화면이 없는 상태이므로 알린다.
  static bool shouldNotify(AppLifecycleState? state) =>
      state != AppLifecycleState.resumed;

  /// 알림 본문. [count] 는 올린 파일 수(사진 묶음).
  static String body({required bool isVideo, required int count}) {
    if (isVideo) return '영상이 올라갔어요. 피드에서 확인해보세요.';
    if (count > 1) return '사진 $count장이 올라갔어요. 피드에서 확인해보세요.';
    return '사진이 올라갔어요. 피드에서 확인해보세요.';
  }

  /// 게시 성공 직후 부른다. 알림 실패가 게시 성공을 되돌리면 안 되므로 예외는 삼킨다.
  static Future<void> notifyPublished({
    required bool isVideo,
    required int count,
  }) async {
    if (!shouldNotify(WidgetsBinding.instance.lifecycleState)) return;
    try {
      await _plugin.show(
        notificationId,
        title,
        body(isVideo: isVideo, count: count),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.status,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            threadIdentifier: 'com.skysnap.upload',
          ),
        ),
        // 탭 핸들러(firebase_service.notificationTapBackground)는 payload 를 jsonDecode 한 뒤
        // boardId 가 없으면 아무 화면으로도 가지 않는다. 서버 게시 응답에 boardId 가 없어
        // 아직 해당 글로는 못 간다 — 앱만 연다. payload 가 null 이면 핸들러가 `!` 로 죽는다.
        payload: jsonEncode({'type': 'UPLOAD_PUBLISHED'}),
      );
    } catch (e) {
      lo.g('게시 완료 알림 실패(무시): $e');
    }
  }

  /// Android 13+ 는 앱이 알림 권한을 직접 물어야 한다. FCM 쪽 `requestPermission` 은
  /// iOS 에서만 불리고 있어 Android 는 한 번도 묻지 않았을 수 있다. 게시 버튼을 누른
  /// 전면 시점에 한 번 묻는다 — 게시가 끝나는 백그라운드 시점에는 물을 수 없다.
  static Future<void> ensureAndroidPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      if (await android.areNotificationsEnabled() ?? true) return;
      final granted = await android.requestNotificationsPermission();
      lo.g('알림 권한 요청 결과: $granted');
    } catch (e) {
      lo.g('알림 권한 확인 실패(무시): $e');
    }
  }
}
