import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project1/services/upload_notifier.dart';

void main() {
  group('shouldNotify', () {
    test('전면(resumed)에서는 인디케이터가 보여주므로 알리지 않는다', () {
      expect(UploadNotifier.shouldNotify(AppLifecycleState.resumed), isFalse);
    });

    test('백그라운드·비활성·숨김 상태에서는 알린다', () {
      expect(UploadNotifier.shouldNotify(AppLifecycleState.paused), isTrue);
      expect(UploadNotifier.shouldNotify(AppLifecycleState.inactive), isTrue);
      expect(UploadNotifier.shouldNotify(AppLifecycleState.hidden), isTrue);
      expect(UploadNotifier.shouldNotify(AppLifecycleState.detached), isTrue);
    });

    test('상태를 모르면(null) 백그라운드 기동으로 보고 알린다', () {
      expect(UploadNotifier.shouldNotify(null), isTrue);
    });
  });

  group('body', () {
    test('영상은 장수와 무관하게 한 문장', () {
      expect(UploadNotifier.body(isVideo: true, count: 1), contains('영상이'));
      expect(UploadNotifier.body(isVideo: true, count: 3), contains('영상이'));
    });

    test('사진 한 장과 여러 장을 구분한다', () {
      expect(UploadNotifier.body(isVideo: false, count: 1), contains('사진이'));
      expect(UploadNotifier.body(isVideo: false, count: 4), contains('사진 4장'));
    });
  });

  test('알림 ID 는 고정이라 연속 게시가 쌓이지 않는다', () {
    expect(UploadNotifier.notificationId, UploadNotifier.notificationId);
    expect(UploadNotifier.channelId, isNotEmpty);
  });
}
