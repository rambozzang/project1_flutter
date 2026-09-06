import 'package:flutter/foundation.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 영상 음소거 상태. 화면·페이지를 넘어 하나만 존재한다.
///
/// 세로 스와이프로 영상을 넘겨 보는 화면에서 음소거는 "이 영상 하나"가 아니라
/// "지금 소리를 듣고 싶지 않다"는 뜻이다. 그래서 다음 영상에도, 앱을 다시 켜도
/// 이어진다. 재생 중인 플레이어들은 [muted] 를 구독해 즉시 반영한다.
///
/// 기존 피드(`VideoListCntr.soundOff`)는 컨트롤러마다 따로 들고 있어 화면을
/// 옮기면 초기화된다. 새 화면은 이 클래스를 쓴다.
class VideoMute {
  VideoMute._();

  static const String _key = 'video_muted';

  /// 재생 중인 플레이어가 구독한다. 값이 바뀌면 각자 볼륨을 맞춘다.
  static final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  static bool get isMuted => muted.value;

  /// 음소거 상태에 맞는 볼륨. `setVolume` 에 그대로 넣는다.
  static double get volume => muted.value ? 0.0 : 1.0;

  /// 저장된 값을 불러온다. 실패해도 앱을 막지 않는다(소리 켜짐이 기본).
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      muted.value = prefs.getBool(_key) ?? false;
    } catch (e) {
      lo.g('음소거 설정 불러오기 실패(무시): $e');
    }
  }

  /// 토글 후 저장. 저장 실패해도 이번 실행 동안의 상태는 유지된다.
  static Future<void> toggle() => set(!muted.value);

  static Future<void> set(bool value) async {
    muted.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (e) {
      lo.g('음소거 설정 저장 실패(무시): $e');
    }
  }

  /// 테스트 전용 초기화.
  @visibleForTesting
  static void resetForTest() => muted.value = false;
}
