import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS/macOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class CommonWebView extends StatefulWidget {
  const CommonWebView(
      {super.key,
      required this.isBackBtn,
      required this.url,
      this.injectJs,
      this.denyLocation = false,
      this.touchToggle = false,
      this.externalTouchEnabled});
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
          onProgress: (int progress) {},
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
          IgnorePointer(
            ignoring: widget.touchToggle && !_touchOn,
            child: ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, value, snapshot) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeIn,
                    child: value
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : WebViewWidget(controller: controller),
                  );
                }),
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
          color: (on ? Colors.teal.shade600 : Colors.black).withOpacity(0.62),
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
