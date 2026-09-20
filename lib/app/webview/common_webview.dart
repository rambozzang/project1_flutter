import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS/macOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';

class CommonWebView extends StatefulWidget {
  const CommonWebView(
      {super.key,
      required this.isBackBtn,
      required this.url,
      this.injectJs,
      this.denyLocation = false,
      this.touchToggle = false,
      this.externalTouchEnabled,
      this.loadingBackground});
  final bool isBackBtn;
  final String url;
  // 페이지 로드 완료 후 실행할 JS(예: 특정 요소만 남기기). null이면 미실행.
  final String? injectJs;
  // true면 웹 위치권한(navigator.geolocation) 프롬프트를 자동 거부(예: RainViewer 현재위치 요청).
  final bool denyLocation;
  // true면 기본은 포인터 무시(부모 스크롤 통과)하고 하단 버튼으로 지도 조작 on/off.
  final bool touchToggle;
  // null이 아니면 외부 버튼이 지도 조작 상태를 제어한다(내부 토글 버튼은 숨김).
  final ValueNotifier<bool>? externalTouchEnabled;

  /// 로딩 동안 스피너 뒤에 깔 그림. 안 주면 검은 배경.
  ///
  /// 검은 화면 + 스피너는 **같은 대기 시간도 더 길게 느껴지게 한다.** 들어오기
  /// 직전에 보던 카드 그림을 그대로 깔면 화면이 이어져 보이고, 그 위로 실제
  /// 지도가 채워진다.
  final Widget? loadingBackground;

  @override
  State<CommonWebView> createState() => _CommonWebView2State();
}

class _CommonWebView2State extends State<CommonWebView>
    with AutomaticKeepAliveClientMixin<CommonWebView>, WidgetsBindingObserver {
  final GlobalKey webViewKey = GlobalKey();
  late final WebViewController controller;
  late final PlatformWebViewControllerCreationParams params;

  ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  bool _isFirstResumed = true;
  bool _touchOn = false; // touchToggle 활성 시 지도 조작 on/off 상태(기본 off=스크롤 통과)

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _touchOn = widget.externalTouchEnabled?.value ?? false;
    widget.externalTouchEnabled?.addListener(_onExternalTouchChanged);

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    controller = WebViewController.fromPlatformCreationParams(params);
// ···
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      // 위치 권한 프롬프트 자동 거부 — 지도는 loc 파라미터로 중심을 잡으므로 현재위치가 불필요.
      if (widget.denyLocation) {
        (controller.platform as AndroidWebViewController).setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async =>
              const GeolocationPermissionsResponse(allow: false, retain: true),
        );
      }
    }

    // #docregion webview_controller
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // **다 로드될 때까지 기다리지 않는다.**
          //
          // 예전에는 `onPageFinished` 에서만 스피너를 내렸다. 웹페이지는
          // 점진적으로 그려지는데 다 될 때까지 가려 둔 셈이라, 레이더를 열면
          // **3.5초 동안 빈 화면**이었다(2026-09-20 실측: 0~2.8초 스피너,
          // 3.5초에 지도 등장).
          //
          // 60% 면 문서와 주요 리소스가 올라와 지도 바탕이 그려지기 시작한다.
          // 그때 내려 주면 사용자는 타일이 채워지는 걸 보게 된다 — 같은 시간이
          // 걸려도 '멈춰 있다' 가 아니라 '오고 있다' 로 보인다.
          onProgress: (int progress) {
            // 60 에서 걷었더니 **빈 화면이 한 번 깜빡였다** — 문서는 올라왔는데
            // 지도가 아직 안 그려진 구간이 있다(2026-09-20 실측: 1.4초에 빈
            // 화면, 2.1초에 지도). 85 면 타일까지 대체로 그려져 있다.
            // 어차피 뒤에 미리보기 그림이 깔려 있으니 조금 더 두는 편이 낫다.
            if (progress >= 85) isLoading.value = false;
          },
          onPageStarted: (String url) {
            isLoading.value = true;
          },
          onPageFinished: (String url) {
            isLoading.value = false;
            final js = widget.injectJs;
            if (js != null && js.isNotEmpty) {
              // 렌더 직후 DOM이 아직 안 붙었을 수 있어, JS 내부에서 폴링/재적용까지 처리한다.
              controller.runJavaScript(js).catchError((_) {});
            }
          },
          onHttpError: (HttpResponseError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(Uri.parse(widget.url));
    // #enddocregion webview_controller
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.externalTouchEnabled?.removeListener(_onExternalTouchChanged);
    controller.clearCache();
    super.dispose();
  }

  void _onExternalTouchChanged() {
    if (mounted) {
      setState(() => _touchOn = widget.externalTouchEnabled?.value ?? false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isFirstResumed) {
        _isFirstResumed = false;
        return;
      }
      try {
        controller.reload();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          // touchToggle: 기본은 포인터 무시(부모 스크롤 통과) → 버튼으로 켜면 지도 조작(줌/이동) 가능.
          // 웹뷰는 **늘 트리에 둔다.** 스피너는 그 위에 얹었다가 걷는다.
          // 예전처럼 AnimatedSwitcher 로 갈아끼우면 로드가 끝난 뒤에야 웹뷰가
          // 만들어져, 화면에 나타나는 시점이 그만큼 더 늦는다.
          IgnorePointer(
            ignoring: widget.touchToggle && !_touchOn,
            child: WebViewWidget(controller: controller),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, loading, _) => IgnorePointer(
              ignoring: !loading,
              child: AnimatedOpacity(
                opacity: loading ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.loadingBackground ??
                        const ColoredBox(color: Colors.black),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
          if (widget.isBackBtn)
            Positioned(
              top: 40,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          if (widget.touchToggle && widget.externalTouchEnabled == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(child: _touchToggleButton()),
            ),
        ],
      ),
    );
  }

  // 지도 조작 on/off 토글 버튼 — 하단 중앙. 기본(off)은 스크롤 통과, on이면 줌·이동 가능.
  Widget _touchToggleButton() {
    final bool on = _touchOn;
    return GestureDetector(
      onTap: () => setState(() => _touchOn = !_touchOn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // 켜짐 상태 = 브랜드 페리윙클(어두운 웹뷰 위이므로 다크 명도). 이전: 임의 Colors.teal
          color: (on ? SaColorsDark.accentTeal : Colors.black).withOpacity(0.62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(on ? Icons.lock_open_rounded : Icons.touch_app, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(on ? '조작 켜짐 · 탭하여 잠금' : '지도 조작하기 (탭)',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
