# 비디오 피드 디코더 윈도우 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 비디오 피드에서 동시에 살아 있는 `VideoPlayerController`를 최대 11개에서 7개로 줄여 OOM 크래시를 없앤다.

**Architecture:** 페이지 위젯은 지금처럼 앞뒤 5장을 미리 빌드하되(레이아웃·썸네일 즉시 표시), **네이티브 디코더는 현재 영상 기준 앞뒤 3장만** 물게 한다. 부모(`video_list_page`)가 현재 인덱스를 `ValueNotifier`로 들고 `videoActive` 플래그를 자식에 주입하고, 자식(`VideoScreenPage`)은 `didUpdateWidget`에서 컨트롤러를 생성/파기한다. 모모앨범 `ImmersiveMediaView`의 검증된 구조를 그대로 이식한다.

**Tech Stack:** Flutter 3.5.3+, `video_player`, `preload_page_view`, `visibility_detector`, GetX

---

## 배경 — 왜 하는가

모모앨범 `immersive_media_view.dart:31-38` 주석(실측 기록):

> PreloadPageView 는 앞뒤 5장을 미리 만든다. 그 전부가 네이티브 디코더를 하나씩 잡으면 화면은 한 장인데 플레이어가 열 개 넘게 살아 있게 된다. 실측으로도 영상 10개를 넘기면 Graphics 메모리가 계속 늘고 되돌아오지 않았다.

`album_immersive_page.dart:80-89`:

> 디코더까지 11개를 물 이유는 없다 — 실측에서 그 상태로 Java 힙이 상한 256MB 를 쳐서 앱이 죽었다.

**SkySnap은 현재 정확히 그 상태다.** `video_list_page.dart:324`의 `VideoScreenPage(key:, index:, data:)`에는 활성 플래그가 없고, `Video_screen_page.dart:105`는 `!isPhotoPost && !isVideoProcessing`이면 무조건 초기화한다. `preLoadingCount = 5`, 광고는 10장마다 1장이므로 **동시 디코더 10~11개**.

## 사전 조사로 확인된 제약 3가지

1. **`onPageChanged`가 리빌드를 일으키지 않는다.** `video_list_page.dart:306`은 `cntr.currentIndex.value`(RxInt)만 갱신하고 `setState`/`update()`를 부르지 않는다. 이를 감싼 것은 `GetBuilder`(291행)라 RxInt 변경에 반응하지 않는다. → **부모에 로컬 `ValueNotifier<int>`를 새로 두고 페이저를 그것으로 감싸야 한다.**
2. **`_controller`가 `late`다.** `Video_screen_page.dart:43`. 초기화 없이 접근하면 `LateInitializationError`. `videoActive=false` 경로가 생기면 미초기화 상태가 정상 상태가 되므로 **nullable 전환이 선행돼야 한다.**
3. **`page` ≠ `videoIndex`.** 광고가 10장마다 끼어 있다(`_adEveryNVideos = 10`, `_blockSize = 11`). 윈도우 판정은 **반드시 `videoIndex` 기준**.

## 파일 구조

| 파일 | 책임 | 변경 |
|---|---|---|
| `lib/app/videolist/video_decoder_window.dart` | 윈도우 판정 순수 함수 (테스트 대상) | **신규** |
| `lib/app/videolist/Video_screen_page.dart` | 페이지 1장 + 자기 플레이어 소유 | 수정 (Task 1~3) |
| `lib/app/videolist/video_list_page.dart` | 페이저 + 현재 인덱스 소유 | 수정 (Task 4~5) |
| `test/videolist/video_decoder_window_test.dart` | 윈도우 산술 검증 | **신규** |

## 테스트 전략 — 정직하게

이 저장소에는 `mockito`/`mocktail`이 없고 `VideoPlayerController`는 플랫폼 채널이라 **위젯 테스트로 컨트롤러 생성 여부를 검증할 수 없다.** 그래서:

- **단위 테스트**: 윈도우 판정 산술만 순수 함수로 분리해 검증 (광고 오프셋과 얽혀 있어 실수하기 쉬운 부분이라 가치가 있다)
- **정적 검증**: `flutter analyze` — nullable 전환 후 미가드 접근을 컴파일러가 잡는다
- **실측**: `adb shell dumpsys meminfo` 로 스와이프 전후 비교 (Task 6)

컨트롤러 수명주기 자체는 실측으로만 검증된다. 이 한계를 인지하고 Task 6을 건너뛰지 말 것.

---

## Task 1: `_controller`를 nullable로 전환

`videoActive=false`면 컨트롤러가 없는 게 정상 상태가 된다. `late`인 채로 두면 미가드 접근이 전부 런타임 크래시가 되므로, 컴파일러가 잡아주도록 먼저 nullable로 바꾼다. **이 태스크는 동작을 바꾸지 않는다.**

**Files:**
- Modify: `lib/app/videolist/Video_screen_page.dart:43`, `113-170`, `219-261`, `330-343`, `364-374`, `524-564`, `986-1015`, `1053-1071`

- [ ] **Step 1: 필드를 nullable로 바꾼다**

`Video_screen_page.dart:43`
```dart
// 변경 전
  late VideoPlayerController _controller;

// 변경 후
  // videoActive=false 인 먼 페이지는 컨트롤러를 아예 만들지 않는다.
  // late 로 두면 그 상태의 모든 접근이 LateInitializationError 가 되므로 nullable 로 둔다.
  VideoPlayerController? _controller;
```

- [ ] **Step 2: `flutter analyze`로 미가드 접근을 전부 드러낸다**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app && flutter analyze lib/app/videolist/Video_screen_page.dart
```
기대: `_controller`를 non-null로 쓰는 지점마다 오류. 아래 Step에서 하나씩 처리한다.

- [ ] **Step 3: `initiliazeVideo()`를 지역 변수 패턴으로 고친다**

`Video_screen_page.dart:113-170`. `_controller`에 바로 대입하지 말고 지역 `ctrl`을 쓰고, 비동기 완료 후 `identical`로 주인 확인. (모모앨범 `_initVideo` 와 동일한 방어.)

```dart
  Future<void> initiliazeVideo() async {
    try {
      Stopwatch stopwatch = Stopwatch()..start();
      lo.g("=== Video Player Initialization Started ===");
      lo.g("Video URL: ${widget.data.videoPath}");

      String finalUrl = widget.data.videoPath.toString();
      VideoFormat format = VideoFormat.hls;

      if (Platform.isAndroid) {
        finalUrl = widget.data.videoPath.toString().replaceAll('.m3u8', '.mpd');
        format = VideoFormat.dash;
        lo.g("Android: Using DASH format - $finalUrl");
      } else {
        lo.g("iOS: Using HLS format - $finalUrl");
      }

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final lastModified = _formatHttpDate(sevenDaysAgo);

      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse(finalUrl),
        httpHeaders: {
          'Connection': 'keep-alive',
          'Cache-Control': 'max-age=3600, stale-while-revalidate=86400',
          'Etg': widget.data.boardId.toString(),
          'Last-Modified': lastModified,
          'If-None-Match': widget.data.boardId.toString(),
          'If-Modified-Since': lastModified,
          'Vary': 'Accept-Encoding, User-Agent',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
        formatHint: format,
      );
      _controller = ctrl;

      await ctrl.initialize();

      // 초기화하는 동안 페이지가 멀어져 해제됐을 수 있다. 그때 _controller 는
      // null 이거나 다른 인스턴스다 — 계속하면 해제된 플레이어를 만지고,
      // 방금 만든 이 디코더는 주인 없이 남는다.
      if (!mounted || !identical(_controller, ctrl)) {
        ctrl.dispose();
        return;
      }

      lo.g('VideoScreenPage init time: ${stopwatch.elapsedMilliseconds}ms');
      timeDesc.value = '${stopwatch.elapsedMilliseconds}ms';
      ctrl.setLooping(true);
      ctrl.pause();
      initialized.value = true;
      _setupVideoListener();
    } catch (e) {
      lo.e("=== Video Player Initialization Failed ===");
      lo.e("Error: $e");
      if (mounted) {
        await _handleInitializationError(e);
      }
    }
  }
```

- [ ] **Step 4: `_handleInitializationError()`를 nullable에 맞춘다**

`Video_screen_page.dart:219-261`의 재시도 본문에서 컨트롤러를 다루는 부분만 교체한다.

```dart
    try {
      try {
        await _controller?.dispose();
      } catch (_) {}
      _controller = null;
      initialized.value = false;

      String finalUrl = widget.data.videoPath.toString();
      VideoFormat format = VideoFormat.hls;
      if (Platform.isAndroid) {
        finalUrl = finalUrl.replaceAll('.m3u8', '.mpd');
        format = VideoFormat.dash;
      }
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(finalUrl), formatHint: format);
      _controller = ctrl;
      await ctrl.initialize();
      if (!mounted || !identical(_controller, ctrl)) {
        ctrl.dispose();
        return;
      }
      ctrl.setLooping(true);
      ctrl.pause();
      initialized.value = true;
      _setupVideoListener();
      lo.g("영상 초기화 재시도 성공($_retryCount)");
    } catch (retryError) {
      if (mounted) await _handleInitializationError(retryError);
    }
```

- [ ] **Step 5: `dispose()`를 "실제로 만들었는가" 기준으로 바꾼다**

`Video_screen_page.dart:330-343`. `isPhotoPost` 조건은 이제 부정확하다 — nullable 자체가 진실이다.

```dart
  @override
  void dispose() {
    initialized.value = false;
    initialized.dispose();
    _photoController.dispose();
    _photoIndex.dispose();
    // 컨트롤러 유무가 곧 진실이다. isPhotoPost / isVideoProcessing / videoActive
    // 세 조건을 여기서 다시 조합하면 initState 조건과 어긋날 때 누수가 난다.
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
```

> `removeListener(() {})`는 원래도 무의미했다(같은 클로저가 아니라 아무것도 제거하지 않음). `dispose()`가 리스너까지 정리하므로 삭제한다.

- [ ] **Step 6: 사용자 조작 3곳에 null 가드를 넣는다**

`Video_screen_page.dart:364-374` (GestureDetector onTap):
```dart
              onTap: () {
                final ctrl = _controller;
                if (ctrl == null) return;   // 먼 페이지/사진/인코딩중 — 조작 대상 없음
                lo.g("Video tapped - current playing state: ${ctrl.value.isPlaying}");
                initPlay = true;
                if (ctrl.value.isPlaying) {
                  isPlay.value = false;
                  ctrl.pause();
                } else {
                  isPlay.value = true;
                  ctrl.play();
                }
              },
```

`Video_screen_page.dart:1006`, `1009` (buildCenterPlayButton) — 두 `onPressed`를 각각:
```dart
                      onPressed: () => _controller?.pause(),
```
```dart
                      onPressed: () => _controller?.play(),
```

`Video_screen_page.dart:1061`, `1063` (buildSoundButton) — 두 호출을:
```dart
              _controller?.setVolume(0);
```
```dart
              _controller?.setVolume(1);
```

- [ ] **Step 7: `buildVideoScreen()`을 지역 변수로 고친다**

`Video_screen_page.dart:524-564`. 이 메서드는 `initialized == true`일 때만 불리지만, nullable 전환 후 컴파일이 통과하려면 명시적으로 받아야 한다.

```dart
  Widget buildVideoScreen(Key key, bool init) {
    final ctrl = _controller;
    if (ctrl == null) return const SizedBox.shrink();
    return Container(
      key: key,
      child: VisibilityDetector(
        key: key,
        onVisibilityChanged: (info) {
          if (!mounted) return;
          lo.g("Video visibility changed: ${info.visibleFraction}");
          initPlay = false;
          if (info.visibleFraction > 0.1) {
            if (init) {
              lo.g("Starting video playback");
              ctrl.play();
              Get.find<VideoListCntr>().soundOff.value ? ctrl.setVolume(0) : ctrl.setVolume(1);
            }
          } else if (info.visibleFraction < 0.3) {
            if (init) {
              lo.g("Pausing video playback");
              ctrl.pause();
              ctrl.seekTo(Duration.zero);
              Get.find<VideoListCntr>().soundOff.value ? ctrl.setVolume(0) : ctrl.setVolume(1);
            }
          }
        },
        child: Center(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: ctrl.value.size.width,
                height: ctrl.value.size.height,
                child: VideoPlayer(ctrl),
              ),
            ),
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 8: `_setupVideoListener()`를 지역 변수로 고친다**

`Video_screen_page.dart:184-185`. 이 메서드는 `_controller`를 클로저 안에서 반복 참조하므로 nullable 전환 후 전부 오류가 난다. 리스너를 다는 시점의 인스턴스를 지역 변수로 잡아 쓴다 — 클로저가 나중에 실행될 때 `_controller`가 이미 다른 인스턴스이거나 null일 수 있기 때문이다.

```dart
  void _setupVideoListener() {
    // 리스너는 이 인스턴스에 붙는다. 나중에 콜백이 돌 때 _controller 가
    // 교체됐거나 해제됐을 수 있으므로 필드가 아니라 지역 변수를 캡처한다.
    final ctrl = _controller;
    if (ctrl == null) return;
    ctrl.addListener(() {
      if (!mounted) return;

      final isCurrentlyPlaying = ctrl.value.isPlaying;
      final duration = ctrl.value.duration;
      final position = ctrl.value.position;

      // 에러 체크
      if (ctrl.value.hasError) {
        lo.e("Video player error: ${ctrl.value.errorDescription}");
        return;
      }
      // ... 이하 기존 본문에서 `_controller.` 를 `ctrl.` 로 그대로 치환한다
      //     (상태 업데이트 / 진행률 계산 블록, 185~218행 범위)
    });
  }
```

⚠️ 185~218행 본문 전체에서 `_controller.`를 `ctrl.`로 치환한다. 치환 누락은 다음 Step의 `flutter analyze`가 잡는다.

- [ ] **Step 9: 정적 분석이 깨끗한지 확인**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app && flutter analyze lib/app/videolist/
```
기대: `Video_screen_page.dart` 관련 오류 0건.

- [ ] **Step 10: 커밋**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app
git add lib/app/videolist/Video_screen_page.dart
git commit -m "영상 컨트롤러를 nullable 로 전환 — 디코더 윈도우 도입 준비

late 는 '항상 초기화된다'는 전제인데, 곧 먼 페이지의 컨트롤러를 만들지 않게
바꾼다. 그 전제가 깨지면 모든 미가드 접근이 LateInitializationError 가 되므로
컴파일러가 잡아주도록 nullable 로 먼저 옮긴다.

- 비동기 초기화 완료 후 identical() 로 주인 확인(도중에 해제됐을 수 있다)
- dispose 를 '컨트롤러 유무' 기준으로 단순화(조건 조합이 어긋나면 누수가 난다)
- 사용자 조작 3곳(탭/재생버튼/음소거)에 null 가드
- 동작 변화 없음"
```

---

## Task 2: 윈도우 판정 순수 함수 + 테스트

광고 오프셋 때문에 판정이 헷갈리기 쉽다. 산술만 떼어 테스트한다.

**Files:**
- Create: `lib/app/videolist/video_decoder_window.dart`
- Create: `test/videolist/video_decoder_window_test.dart`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`test/videolist/video_decoder_window_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:project1/app/videolist/video_decoder_window.dart';

void main() {
  group('isVideoActive', () {
    test('현재 영상은 항상 활성', () {
      expect(isVideoActive(videoIndex: 7, currentVideoIndex: 7), isTrue);
    });

    test('앞뒤 3장까지 활성', () {
      expect(isVideoActive(videoIndex: 4, currentVideoIndex: 7), isTrue);
      expect(isVideoActive(videoIndex: 10, currentVideoIndex: 7), isTrue);
    });

    test('4장 이상 떨어지면 비활성 — 디코더를 놓는다', () {
      expect(isVideoActive(videoIndex: 3, currentVideoIndex: 7), isFalse);
      expect(isVideoActive(videoIndex: 11, currentVideoIndex: 7), isFalse);
      expect(isVideoActive(videoIndex: 0, currentVideoIndex: 7), isFalse);
    });

    test('피드 첫 진입(0번)에서도 앞쪽 3장이 활성', () {
      expect(isVideoActive(videoIndex: 0, currentVideoIndex: 0), isTrue);
      expect(isVideoActive(videoIndex: 3, currentVideoIndex: 0), isTrue);
      expect(isVideoActive(videoIndex: 4, currentVideoIndex: 0), isFalse);
    });

    test('동시 활성 개수는 최대 7개 — preloadPagesCount=5(11장)보다 적어야 의미가 있다', () {
      const current = 20;
      final active = List.generate(40, (i) => i)
          .where((i) => isVideoActive(videoIndex: i, currentVideoIndex: current))
          .length;
      expect(active, 7);
    });
  });

  group('videoWindowSize', () {
    test('윈도우는 프리로드 페이지 수보다 작아야 한다 — 같으면 줄이는 의미가 없다', () {
      expect(kVideoWindow, lessThan(5));
    });
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app && flutter test test/videolist/video_decoder_window_test.dart
```
기대: FAIL — `Target of URI doesn't exist: 'package:project1/app/videolist/video_decoder_window.dart'`

- [ ] **Step 3: 최소 구현**

`lib/app/videolist/video_decoder_window.dart`
```dart
/// 비디오 피드에서 **네이티브 디코더를 실제로 물고 있을 범위.**
///
/// 페이지 위젯은 `preLoadingCount`(5)만큼 앞뒤로 미리 만들어야 넘길 때 레이아웃이
/// 끊기지 않는다. 하지만 디코더까지 그만큼 물 이유는 없다 — 자매 앱(모모앨범)
/// 실측에서 그 상태로 Java 힙이 상한 256MB 를 쳐서 앱이 죽었다.
///
/// 3으로 둔 이유: 2도 바로 다음 장은 항상 준비되지만, 연속으로 빠르게 넘길 때
/// 여유가 한 장뿐이라 버퍼링이 보일 여지가 있다. 3이면 두 장을 앞서 준비하고
/// 디코더는 여전히 절반 아래다(동시 7개 < 프리로드 11장).
const int kVideoWindow = 3;

/// 이 영상이 지금 디코더를 물고 있어야 하는지.
///
/// ⚠️ 반드시 **영상 데이터 인덱스**로 판정한다. 피드에는 광고 페이지가 10장마다
/// 끼어 있어 PageView 의 물리적 page 와 영상 인덱스가 어긋난다
/// (`_pageToVideoIndex` 참고).
bool isVideoActive({required int videoIndex, required int currentVideoIndex}) {
  return (videoIndex - currentVideoIndex).abs() <= kVideoWindow;
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app && flutter test test/videolist/video_decoder_window_test.dart
```
기대: `All tests passed!` (6개)

- [ ] **Step 5: 커밋**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app
git add lib/app/videolist/video_decoder_window.dart test/videolist/video_decoder_window_test.dart
git commit -m "디코더 윈도우 판정 함수 추가 — 광고 오프셋과 얽혀 실수하기 쉬운 산술을 고정

피드에는 광고가 10장마다 끼어 page 와 영상 인덱스가 어긋난다. 윈도우 판정을
순수 함수로 떼어 테스트로 고정한다. 동시 활성 7개(< 프리로드 11장)를
불변식으로 못박아 두었다."
```

---

## Task 3: `VideoScreenPage`에 `videoActive` 도입

**Files:**
- Modify: `lib/app/videolist/Video_screen_page.dart:32-40`, `97-111`, `330-343`, `388-409`

- [ ] **Step 1: 생성자에 파라미터를 추가한다**

`Video_screen_page.dart:32-40`
```dart
class VideoScreenPage extends StatefulWidget {
  const VideoScreenPage({
    super.key,
    required this.index,
    required this.data,
    this.videoActive = true,
  });

  final BoardWeatherListData data;
  final int index;

  /// 이 페이지가 **지금 네이티브 디코더를 물고 있을지.**
  ///
  /// 페이지 위젯은 앞뒤 5장을 미리 만들지만 영상은 가까운 3장만 준비한다.
  /// 멀어지면 놓고, 되돌아오면 다시 만든다. 버퍼링 동안 썸네일(buildLoading)이
  /// 깔리므로 넘길 때 빈 화면이 보이지 않는다.
  final bool videoActive;

  @override
  State<VideoScreenPage> createState() => VideoScreenPageState();
}
```

- [ ] **Step 2: `initState` 조건에 추가한다**

`Video_screen_page.dart:105`
```dart
    if (!isPhotoPost && !isVideoProcessing && widget.videoActive) {
      initiliazeVideo();
    }
```

- [ ] **Step 3: `didUpdateWidget`을 추가한다 (핵심)**

`Video_screen_page.dart`의 `initState()` 바로 아래에 삽입.
```dart
  /// 부모가 현재 페이지를 옮기면 이 값이 바뀐다.
  /// 멀어지면 디코더를 놓고, 돌아오면 다시 만든다.
  @override
  void didUpdateWidget(covariant VideoScreenPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isPhotoPost || isVideoProcessing) return;
    if (widget.videoActive == oldWidget.videoActive) return;

    if (widget.videoActive) {
      // 멀어졌다 돌아왔다. 재시도 횟수도 초기화한다 — 아까 실패한 이유가
      // 인코딩 지연이었다면 그새 끝났을 수 있다.
      if (_controller == null) {
        _retryCount = 0;
        initiliazeVideo();
      }
    } else {
      _releaseVideo();
    }
  }

  /// 멀어진 페이지의 디코더를 놓는다. 화면은 initialized=false 가 되면서
  /// buildLoading()(썸네일)으로 자동 전환된다.
  void _releaseVideo() {
    final ctrl = _controller;
    if (ctrl == null) return;
    _controller = null;
    initialized.value = false;
    initPlay = false;
    ctrl.dispose();
  }
```

- [ ] **Step 4: 비동기 도중 멀어진 경우를 막는다**

`initiliazeVideo()` 최상단(Task 1 Step 3에서 만든 `try {` 바로 다음 줄)에 가드를 넣는다.
```dart
      // 재시도 대기 중에 멀어졌을 수도 있다.
      if (!widget.videoActive) return;
```

그리고 `_handleInitializationError()`의 `await Future.delayed(delay);` 다음 줄 `if (!mounted) return;`을 다음으로 교체한다.
```dart
    if (!mounted || !widget.videoActive) return;
```

- [ ] **Step 5: 분석 + 기존 테스트 회귀 확인**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app && flutter analyze lib/app/videolist/ && flutter test
```
기대: analyze 오류 0건, 기존 테스트 전부 통과.

- [ ] **Step 6: 커밋**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app
git add lib/app/videolist/Video_screen_page.dart
git commit -m "VideoScreenPage 에 videoActive 도입 — 멀어진 페이지는 디코더를 놓는다

didUpdateWidget 에서 true->false 면 컨트롤러를 파기하고 false->true 면 다시
만든다. initialized=false 가 되면 기존 buildLoading()(썸네일)으로 자동
전환되므로 빈 화면은 없다.

비동기 초기화·재시도 대기 도중 멀어졌을 수 있어 진입 시점과 재시도 직전에
videoActive 를 다시 확인한다. 아직 부모가 값을 주입하지 않으므로(기본 true)
동작 변화는 없다 — 주입은 다음 커밋."
```

---

## Task 4: `video_list_page`에서 윈도우 주입

**Files:**
- Modify: `lib/app/videolist/video_list_page.dart:100-122`, `140-145`, `290-330`

- [ ] **Step 1: import와 현재 인덱스 필드를 추가한다**

`video_list_page.dart` 상단 import 블록에 추가:
```dart
import 'package:project1/app/videolist/video_decoder_window.dart';
```

`video_list_page.dart:104` 아래에 필드 추가:
```dart
  /// 현재 보고 있는 **영상 데이터 인덱스**(광고 페이지 제외).
  ///
  /// `VideoListCntr.currentIndex`(RxInt)와 같은 값이지만 별도로 둔다 —
  /// 그쪽은 GetBuilder 가 구독하지 않아 값이 바뀌어도 itemBuilder 가 다시
  /// 돌지 않는다. 디코더 윈도우는 페이지를 넘길 때마다 재판정돼야 하므로
  /// 페이저를 직접 리빌드할 수 있는 알림원이 필요하다.
  final ValueNotifier<int> _currentVideoIndex = ValueNotifier<int>(0);
```

- [ ] **Step 2: dispose에 추가한다**

`video_list_page.dart:140-145`
```dart
  @override
  void dispose() {
    _controller.dispose();
    scrollController.dispose();
    _currentVideoIndex.dispose();
    super.dispose();
  }
```

- [ ] **Step 3: 페이저를 `ValueListenableBuilder`로 감싸고 플래그를 주입한다**

`video_list_page.dart:290-330`의 `buildVideoBody` 전체를 교체한다.
```dart
  Widget buildVideoBody(List<BoardWeatherListData> data, BuildContext context) {
    return GetBuilder<VideoListCntr>(
      builder: (cntr) {
        // 페이지를 넘길 때마다 itemBuilder 를 다시 돌려야 videoActive 가 재판정된다.
        // GetBuilder 는 update() 에만 반응하므로 여기서 한 겹 더 감싼다.
        return ValueListenableBuilder<int>(
          valueListenable: _currentVideoIndex,
          builder: (context, currentVideoIndex, _) {
            return PreloadPageView.builder(
              key: const PageStorageKey("tigerBkPageView"),
              controller: _controller,
              preloadPagesCount: cntr.preLoadingCount,
              scrollDirection: Axis.vertical,
              itemCount: _pageCount(data.length),
              physics: const FastPageScrollPhysics(),
              onPageChanged: (int page) {
                RootCntr.to.bottomBarStreamController.sink.add(true);
                // 광고 페이지면 현재영상 인덱스/페이징을 건드리지 않는다(list[currentIndex] 정합 유지).
                if (_isAdPage(page)) return;
                final int videoIndex = _pageToVideoIndex(page);
                // 좋아요/팔로우가 현재 영상을 정확히 가리키도록 '데이터 인덱스'를 저장.
                cntr.currentIndex.value = videoIndex;
                // 디코더 윈도우 재판정을 유발한다(위 ValueListenableBuilder).
                _currentVideoIndex.value = videoIndex;
                if (videoIndex >= cntr.list.length - (cntr.preLoadingCount + 1)) {
                  cntr.getDataWithPagination();
                }
              },
              itemBuilder: (context, page) {
                // 10장마다 끼워넣는 틱톡형 인라인 광고 페이지
                if (_isAdPage(page)) {
                  return const SizedBox.expand(child: NativeFeedAdPage());
                }
                final int videoIndex = _pageToVideoIndex(page);
                if (videoIndex < 0 || videoIndex >= data.length) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: VideoScreenPage(
                    // 인덱스가 아니라 boardId 로 고정한다. 앞쪽에 항목이 끼거나
                    // 빠지면 인덱스 기준 키는 다른 영상의 State 를 재사용한다.
                    key: ValueKey('video_${data[videoIndex].boardId}'),
                    index: videoIndex,
                    data: data[videoIndex],
                    videoActive: isVideoActive(
                      videoIndex: videoIndex,
                      currentVideoIndex: currentVideoIndex,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
```

> `PageStorageKey('key_$videoIndex')` → `ValueKey('video_${boardId}')` 교체가 함께 들어간다. 모모앨범도 `ValueKey('sa_immersive_${boardId}')`를 쓴다.

- [ ] **Step 4: 분석 + 테스트**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app && flutter analyze lib/app/videolist/ && flutter test
```
기대: analyze 오류 0건, 테스트 전부 통과.

- [ ] **Step 5: 커밋**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app
git add lib/app/videolist/video_list_page.dart
git commit -m "비디오 피드에 디코더 윈도우 적용 — 동시 플레이어 11개에서 7개로

preloadPagesCount=5 라 앞뒤 5장(광고 포함 최대 11페이지)이 각자 디코더를
물고 있었다. 자매 앱(모모앨범)이 같은 구성에서 Java 힙 256MB 상한을 쳐서
죽은 것과 동일한 조건이다.

- 로컬 ValueNotifier<int> 로 현재 영상 인덱스를 들고 페이저를 감싼다.
  VideoListCntr.currentIndex(RxInt)는 GetBuilder 가 구독하지 않아
  값이 바뀌어도 itemBuilder 가 다시 돌지 않는다.
- videoActive 는 광고 오프셋을 걷어낸 videoIndex 기준으로 판정한다.
- 페이지 키를 인덱스에서 boardId 로 바꾼다. 앞쪽 항목이 바뀌면 인덱스 기준
  키는 다른 영상의 State 를 재사용한다."
```

---

## Task 5: `initialize()` 타임아웃

인코딩 지연이나 네트워크 문제로 `initialize()`가 무기한 대기하면 재시도 경로조차 타지 않는다.

**Files:**
- Modify: `lib/app/videolist/Video_screen_page.dart` (`_retryDelays` 선언부, `initiliazeVideo`)

- [ ] **Step 1: 상수를 추가한다**

`Video_screen_page.dart:227`의 `_retryDelays` 선언 바로 아래:
```dart
  /// 인접 페이지가 인코딩 지연이나 네트워크 문제로 무기한 대기하지 않게 한다.
  /// 타임아웃이 없으면 실패로 떨어지지 않아 재시도 경로조차 타지 않는다.
  static const Duration _initializeTimeout = Duration(seconds: 15);
```

- [ ] **Step 2: 두 초기화 지점에 적용한다**

`initiliazeVideo()`의 `await ctrl.initialize();` →
```dart
      await ctrl.initialize().timeout(_initializeTimeout);
```

`_handleInitializationError()`의 `await ctrl.initialize();` →
```dart
      await ctrl.initialize().timeout(_initializeTimeout);
```

- [ ] **Step 3: 분석 + 테스트**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app && flutter analyze lib/app/videolist/ && flutter test
```

- [ ] **Step 4: 커밋**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app
git add lib/app/videolist/Video_screen_page.dart
git commit -m "영상 initialize 에 15초 타임아웃 — 무한 로딩과 재시도 불발 제거

타임아웃이 없으면 매니페스트가 안 오는 영상에서 initialize 가 영원히 대기하고,
실패로 떨어지지 않아 이미 있는 재시도 경로(2/4/7/12초)조차 타지 않는다."
```

---

## Task 6: 메모리 실측 검증 — 건너뛰지 말 것

단위 테스트로는 디코더 개수를 확인할 수 없다. **이 태스크가 유일한 실증이다.**

**Files:** 없음 (측정만)

- [ ] **Step 1: 변경 전 기준값을 잡는다**

```bash
cd /Users/bumkyuchun/work/app/skysnap/skysnap_app
git stash                       # 변경분을 잠시 치운다
flutter build apk --debug
flutter install
```
앱에서 비디오 피드를 열고 **영상 15개를 연속으로 빠르게 스와이프**한 뒤:
```bash
adb shell dumpsys meminfo com.codelabtiger.skysnap | head -25
```
`Java Heap`, `Graphics`, `TOTAL PSS` 세 값을 기록한다.

- [ ] **Step 2: 변경 후를 같은 방법으로 측정한다**

```bash
git stash pop
flutter build apk --debug
flutter install
```
**동일한 조작**(영상 15개 연속 스와이프)을 반복하고 같은 명령으로 측정한다.

- [ ] **Step 3: 판정**

기대: `Graphics`가 눈에 띄게 낮고, 스와이프를 멈춘 뒤 값이 **되돌아온다**(변경 전에는 계속 늘고 안 돌아왔다).

⚠️ 개선이 안 보이면 **다음으로 넘어가지 말고** `didUpdateWidget`이 실제로 불리는지부터 확인한다. `_releaseVideo()`에 로그를 넣고 `adb logcat`으로 스와이프 시 해제가 찍히는지 본다. 안 찍히면 `ValueListenableBuilder` 리빌드가 자식까지 닿지 않는 것이므로 Task 4를 재검토한다.

- [ ] **Step 4: 체감 확인**

- 빠르게 연속 스와이프 → 버퍼링으로 빈 화면이 뜨지 않는지(썸네일이 깔려야 한다)
- 4장 이상 넘겼다가 되돌아오기 → 영상이 다시 재생되는지
- 사진 게시물·인코딩 중 게시물이 섞인 구간 → 크래시 없는지
- 먼 페이지에서 음소거·재생 버튼 탭 → 크래시 없는지(Task 1 Step 6 가드 확인)

- [ ] **Step 5: 측정값을 기록으로 남긴다**

`LOG.md`에 변경 전/후 수치를 적는다. 다음에 누가 `kVideoWindow`를 건드릴 때 근거가 된다.

---

## 완료 기준

- [ ] `flutter analyze lib/app/videolist/` 오류 0건
- [ ] `flutter test` 전부 통과 (기존 4개 파일 + 신규 1개)
- [ ] 영상 15개 연속 스와이프 후 Graphics 메모리가 변경 전보다 낮고 되돌아온다
- [ ] 빠른 스와이프에서 빈 화면 없음(썸네일 표시)
- [ ] 되돌아온 페이지에서 영상 재생 복구
- [ ] 사진/인코딩중 게시물 혼재 구간 크래시 없음

## 범위 밖 (별도 계획)

- 업로드 영속 큐(`PendingUploadStore`) — 독립 서브시스템, 2~3일
- 서버 소유 업로드 세션 — 백엔드 신규 도메인 필요, 1~2주
- `_activeVideo` 패턴(스크러버용) — 이 계획의 윈도우와 무관, 별도 개선
