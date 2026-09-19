import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'momo_video.dart';

/// 안드로이드 네이티브 플레이어 풀에 붙는 구현.
///
/// 네이티브(`MomoVideo.kt`)는 ExoPlayer 를 **3개만** 만들어 두고 돌려쓴다.
/// 여기서는 그 중 한 슬롯을 빌려 쓰는 손잡이 역할만 한다.
///
/// 위치는 네이티브에 묻지 않고 **여기서 센다.** 매 프레임 채널을 건너가 물으면
/// 스크러버 하나 때문에 초당 수십 번 오가게 된다 — 재생 중일 때만 200ms 간격으로
/// 한 번씩 맞춘다.
class MomoVideoNative extends ValueNotifier<MomoVideoValue> implements MomoVideo {
  MomoVideoNative(this.uri) : super(const MomoVideoValue());

  final Uri uri;

  static const MethodChannel _channel =
      MethodChannel('com.codelabtiger.momoalbum/momo_video');

  /// 슬롯을 빌린 인스턴스들. 네이티브가 보내는 이벤트를 주인에게 전달한다.
  static final Map<int, MomoVideoNative> _bySlot = {};
  static bool _handlerSet = false;

  int? _slot;
  int? _textureId;
  Timer? _ticker;
  bool _disposed = false;

  /// 풀 전체를 네이티브에서 놓는다. 몰입뷰 화면을 떠날 때만 부른다.
  static Future<void> releaseAll() async {
    _bySlot.clear();
    await _channel.invokeMethod('disposeAll');
  }

  static void _ensureHandler() {
    if (_handlerSet) return;
    _handlerSet = true;
    _channel.setMethodCallHandler((call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? const {};
      final slot = (args['slot'] as num?)?.toInt();
      final owner = slot == null ? null : _bySlot[slot];
      if (owner == null) return null;
      switch (call.method) {
        case 'onReady':
          owner._onReady(args);
        case 'onPlaying':
          owner.value = owner.value.copyWith(isPlaying: true);
          owner._startTicker();
        case 'onPaused':
          owner.value = owner.value.copyWith(isPlaying: false);
          owner._stopTicker();
        case 'onEnded':
          // 반복 재생이면 네이티브가 알아서 돌린다. 여기서는 위치만 맞춘다.
          owner._syncPosition();
        case 'onSize':
          // 크기는 준비보다 늦게 올 수 있다. 오면 그때 반영한다.
          owner._onSize(args);
        case 'onEvicted':
          // 다른 페이지가 이 슬롯을 가져갔다. 우리 화면은 이제 빈 텍스처를
          // 가리키므로 **다시 잡는다** — 안 그러면 돌아왔을 때 검은 화면이다.
          owner._onEvicted();
        case 'onError':
          // 재생 실패는 조용히 넘긴다 — 다음 장으로 넘어가면 그만이다.
          owner.value = owner.value.copyWith(isPlaying: false);
      }
      return null;
    });
  }

  /// 슬롯을 뺏겼다. 표시를 지우고 **잠시 뒤 다시 잡는다.**
  ///
  /// 처음에는 다시 잡지 않고 놔뒀다. 서로 뺏고 뺏기는 싸움을 걱정해서였는데,
  /// 실제로는 **밀려난 페이지가 검은 화면으로 영영 남았다**(2026-09-19 제보:
  /// "5페이지부터 검은색"). 화면에 아무것도 없는 것보다는 한 번 더 잡아 보는
  /// 편이 낫다.
  ///
  /// 곧바로 잡지 않고 한 박자 쉬는 이유: 방금 뺏어 간 쪽이 자리를 잡는 중이다.
  /// 그 사이에 되받으면 정말로 싸움이 된다. 200ms 뒤에도 이 페이지가 여전히
  /// 살아 있다면(= 화면 근처에 있다) 그때 잡는다.
  void _onEvicted() {
    if (_disposed) return;
    final slot = _slot;
    if (slot != null) _bySlot.remove(slot);
    _slot = null;
    _stopTicker();
    value = const MomoVideoValue();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_disposed || _slot != null) return;
      initialize().catchError((_) {
        // 그래도 못 잡으면 다음 스와이프에 다시 기회가 온다.
      });
    });
  }

  void _onSize(Map<String, dynamic> args) {
    if (_disposed) return;
    final w = (args['width'] as num?)?.toDouble() ?? 0;
    final h = (args['height'] as num?)?.toDouble() ?? 0;
    if (w <= 0 || h <= 0) return;
    value = value.copyWith(size: Size(w, h));
  }

  void _onReady(Map<String, dynamic> args) {
    if (_disposed) return;
    final w = (args['width'] as num?)?.toDouble() ?? 0;
    final h = (args['height'] as num?)?.toDouble() ?? 0;
    value = value.copyWith(
      isInitialized: true,
      duration: Duration(milliseconds: (args['durationMs'] as num?)?.toInt() ?? 0),
      size: Size(w, h),
    );
  }

  @override
  Future<void> initialize() async {
    _ensureHandler();
    final res = await _channel.invokeMapMethod<String, dynamic>('acquire', {
      'url': uri.toString(),
    });
    if (res == null) throw PlatformException(code: 'no_slot');
    if (_disposed) {
      // 여는 사이에 페이지가 멀어졌다. 슬롯을 바로 돌려준다.
      final slot = (res['slot'] as num?)?.toInt();
      if (slot != null) unawaited(_channel.invokeMethod('release', {'slot': slot}));
      return;
    }
    _slot = (res['slot'] as num?)?.toInt();
    _textureId = (res['textureId'] as num?)?.toInt();
    if (_slot != null) _bySlot[_slot!] = this;

    // 이미 같은 URL 을 물고 있던 슬롯이면 준비가 끝나 있다. onReady 가 다시
    // 오지 않으므로 여기서 초기화 표시를 해 준다.
    if (res['reused'] == true) {
      value = value.copyWith(isInitialized: true);
      unawaited(_syncPosition());
    }
  }

  @override
  Future<void> play() async {
    if (_slot == null) return;
    await _channel.invokeMethod('play', {'slot': _slot});
  }

  @override
  Future<void> pause() async {
    if (_slot == null) return;
    await _channel.invokeMethod('pause', {'slot': _slot});
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_slot == null) return;
    await _channel.invokeMethod('seekTo', {
      'slot': _slot,
      'ms': position.inMilliseconds,
    });
    value = value.copyWith(position: position);
  }

  @override
  Future<void> setLooping(bool looping) async {
    if (_slot == null) return;
    await _channel.invokeMethod('setLooping', {'slot': _slot, 'looping': looping});
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_slot == null) return;
    await _channel.invokeMethod('setVolume', {'slot': _slot, 'volume': volume});
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _syncPosition(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _syncPosition() async {
    if (_disposed || _slot == null) return;
    final ms = await _channel.invokeMethod<int>('position', {'slot': _slot});
    if (_disposed || ms == null) return;
    value = value.copyWith(position: Duration(milliseconds: ms));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stopTicker();
    final slot = _slot;
    if (slot != null) {
      _bySlot.remove(slot);
      // 슬롯은 **반납만** 한다. 네이티브는 플레이어를 버리지 않고 세워 둔다 —
      // 그게 이 구조의 핵심이다.
      await _channel.invokeMethod('release', {'slot': slot});
    }
    super.dispose();
  }

  @override
  Widget buildView() {
    // ⚠️ **반드시 값 변화를 구독해야 한다.**
    //
    // 준비 완료(onReady)는 슬롯을 잡고 1초쯤 뒤에 온다. 그냥 그 순간의 값으로
    // 한 번 그리면, 준비가 끝나도 이 자리를 다시 그리지 않아 `Texture` 가
    // 영영 안 붙는다 — 소리와 스크러버는 다른 경로라 멀쩡해서 **"소리만 나고
    // 화면이 검다"** 로 보였다(2026-09-19).
    return ValueListenableBuilder<MomoVideoValue>(
      valueListenable: this,
      builder: (context, v, _) {
        final id = _textureId;
        if (id == null || !v.isInitialized) return const SizedBox.shrink();
        return Texture(textureId: id);
      },
    );
  }
}
