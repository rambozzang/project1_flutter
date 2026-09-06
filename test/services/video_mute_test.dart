import 'package:flutter_test/flutter_test.dart';
import 'package:project1/services/video_mute.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VideoMute.resetForTest();
  });

  test('기본값은 소리 켜짐', () {
    expect(VideoMute.isMuted, isFalse);
    expect(VideoMute.volume, 1.0);
  });

  test('토글하면 음소거되고 볼륨이 0', () async {
    await VideoMute.toggle();
    expect(VideoMute.isMuted, isTrue);
    expect(VideoMute.volume, 0.0);
  });

  test('토글은 왕복한다', () async {
    await VideoMute.toggle();
    await VideoMute.toggle();
    expect(VideoMute.isMuted, isFalse);
  });

  test('구독자에게 변경이 전달된다 — 재생 중인 다음 영상이 즉시 따라간다', () async {
    final seen = <bool>[];
    void listener() => seen.add(VideoMute.muted.value);
    VideoMute.muted.addListener(listener);
    await VideoMute.set(true);
    await VideoMute.set(false);
    VideoMute.muted.removeListener(listener);
    expect(seen, [true, false]);
  });

  test('같은 값을 다시 넣으면 알림이 가지 않는다', () async {
    await VideoMute.set(true);
    var count = 0;
    void listener() => count++;
    VideoMute.muted.addListener(listener);
    await VideoMute.set(true);
    VideoMute.muted.removeListener(listener);
    expect(count, 0);
  });

  test('저장된 값을 다시 읽어온다 — 앱을 껐다 켜도 유지', () async {
    await VideoMute.set(true);
    VideoMute.resetForTest();
    expect(VideoMute.isMuted, isFalse);
    await VideoMute.load();
    expect(VideoMute.isMuted, isTrue);
  });

  test('저장된 값이 없으면 소리 켜짐으로 시작', () async {
    SharedPreferences.setMockInitialValues({});
    await VideoMute.load();
    expect(VideoMute.isMuted, isFalse);
  });
}
