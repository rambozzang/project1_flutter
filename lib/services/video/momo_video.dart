import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'momo_video_native.dart';

/// 재생 상태. `VideoPlayerValue` 에서 **몰입뷰가 실제로 쓰는 것만** 추렸다.
@immutable
class MomoVideoValue {
  const MomoVideoValue({
    this.isInitialized = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.size = Size.zero,
  });

  final bool isInitialized;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Size size;

  MomoVideoValue copyWith({
    bool? isInitialized,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    Size? size,
  }) =>
      MomoVideoValue(
        isInitialized: isInitialized ?? this.isInitialized,
        isPlaying: isPlaying ?? this.isPlaying,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        size: size ?? this.size,
      );
}

/// 몰입뷰가 쓰는 영상 플레이어.
///
/// 플랫폼마다 속을 다르게 쓴다 — [MomoVideo.network] 가 알아서 고른다.
///
/// * **안드로이드**: 우리가 만든 네이티브 풀([MomoVideoNative]).
///   플레이어를 돌려쓰고 버퍼를 줄인다. 기본 플러그인은 페이지마다 플레이어를
///   새로 만들고 버리며, 메모리를 먹는 앞 버퍼(기본 50초·플레이어당 최대
///   125MB)를 조절할 방법을 열어 주지 않는다 — 실기기에서 자바 힙 상한
///   256MB 를 쳐서 앱이 두 번 죽었다(2026-09-16, 09-19).
/// * **그 외(iOS)**: `video_player` 를 그대로 쓴다. `AVPlayer` 는 버퍼를 OS 가
///   알아서 줄이고 늘리며, iOS 에서는 같은 크래시가 없었다. 문제가 없는 쪽까지
///   새로 만들면 유지할 코드만 두 배가 된다.
abstract class MomoVideo implements ValueListenable<MomoVideoValue> {
  /// 네트워크 영상을 연다. [formatHint] 는 HLS/DASH 판별용(플러그인 경로에서만 쓴다).
  factory MomoVideo.network(Uri uri, {VideoFormat? formatHint}) {
    if (Platform.isAndroid) return MomoVideoNative(uri);
    return MomoVideoPlugin(uri, formatHint: formatHint);
  }

  /// 몰입뷰 화면을 **완전히 떠날 때** 부른다.
  ///
  /// 풀은 슬롯을 반납해도 플레이어를 세워만 둔다 — 다시 들어올 때 바로 틀기
  /// 위해서다. 그런데 화면 자체를 나가면 그 셋이 그대로 메모리를 잡고 있다
  /// (실측 ~20MB). 앨범 목록으로 돌아간 뒤까지 들고 있을 이유는 없다.
  ///
  /// 다시 들어오면 새로 만들지만, 그건 화면 전환이라 한 번의 준비 비용을
  /// 감당할 수 있다. 스와이프 중에는 절대 일어나지 않는다.
  static Future<void> releasePool() async {
    if (!Platform.isAndroid) return;
    await MomoVideoNative.releaseAll();
  }

  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setLooping(bool looping);
  Future<void> setVolume(double volume);
  Future<void> dispose();

  /// 화면에 그릴 위젯. 준비 전이면 빈 위젯을 준다.
  Widget buildView();
}

/// `video_player` 를 감싼 기본 구현 — iOS 및 그 밖의 플랫폼.
class MomoVideoPlugin extends ValueNotifier<MomoVideoValue> implements MomoVideo {
  MomoVideoPlugin(Uri uri, {VideoFormat? formatHint})
      : _inner = VideoPlayerController.networkUrl(
          uri,
          formatHint: formatHint,
          videoPlayerOptions:
              VideoPlayerOptions(mixWithOthers: true, allowBackgroundPlayback: false),
        ),
        super(const MomoVideoValue()) {
    _inner.addListener(_sync);
  }

  final VideoPlayerController _inner;

  void _sync() {
    final v = _inner.value;
    value = MomoVideoValue(
      isInitialized: v.isInitialized,
      isPlaying: v.isPlaying,
      position: v.position,
      duration: v.duration,
      size: v.size,
    );
  }

  @override
  Future<void> initialize() => _inner.initialize();

  @override
  Future<void> play() => _inner.play();

  @override
  Future<void> pause() => _inner.pause();

  @override
  Future<void> seekTo(Duration position) => _inner.seekTo(position);

  @override
  Future<void> setLooping(bool looping) => _inner.setLooping(looping);

  @override
  Future<void> setVolume(double volume) => _inner.setVolume(volume);

  @override
  Future<void> dispose() async {
    _inner.removeListener(_sync);
    await _inner.dispose();
    super.dispose();
  }

  @override
  Widget buildView() => ValueListenableBuilder<MomoVideoValue>(
        // 네이티브 쪽과 같은 이유로 구독한다(momo_video_native.buildView 주석).
        valueListenable: this,
        builder: (context, v, _) =>
            v.isInitialized ? VideoPlayer(_inner) : const SizedBox.shrink(),
      );
}
