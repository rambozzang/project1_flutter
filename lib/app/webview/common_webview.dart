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
      this.touchToggleOutside = false});
  final bool isBackBtn;
  final String url;
  // 페이지 로드 완료 후 실행할 JS(예: 특정 요소만 남기기). null이면 미실행.
  final String? injectJs;
  // true면 웹 위치권한(navigator.geolocation) 프롬프트를 자동 거부(예: RainViewer 현재위치 요청).
  final bool denyLocation;
  // true면 기본은 포인터 무시(부모 스크롤 통과)하고 하단 버튼으로 지도 조작 on/off.
  final bool touchToggle;
  // true면 지도 조작 버튼을 WebView 위가 아닌 바로 아래 별도 영역에 표시.
  final bool touchToggleOutside;

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
  bool _retried = false; // 메인 프레임 로드 실패 시 1회만 자동 재시도(무한 루프 방지)

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
          onWebResourceError: (WebResourceError error) {
            // 그동안 에러를 삼켜, 실패해도 원인 없이 빈 화면이 됐다 → 로그로 노출 + 1회 자동 재시도.
            debugPrint('[CommonWebView] error url=${widget.url} code=${error.errorCode} '
                'type=${error.errorType} mainFrame=${error.isForMainFrame} desc=${error.description}');
            if ((error.isForMainFrame ?? false) && !_retried && mounted) {
              _retried = true;
              Future.delayed(const Duration(milliseconds: 1200), () {
                if (mounted) {
                  isLoading.value = true;
                  controller.loadRequest(Uri.parse(widget.url));
                }
              });
            }
          },
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
    controller.clearCache();
    super.dispose();
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
      backgroundColor: Colors.transparent,
      body: widget.touchToggle && widget.touchToggleOutside
          ? Column(
              children: [
                Expanded(child: _buildWebViewStack(showTouchToggle: false)),
                const SizedBox(height: 8),
                _touchToggleButton(),
              ],
            )
          : _buildWebViewStack(showTouchToggle: widget.touchToggle),
    );
  }

  Widget _buildWebViewStack({required bool showTouchToggle}) {
    return Stack(
        children: [
          // touchToggle: 기본은 포인터 무시(부모 스크롤 통과) → 버튼으로 켜면 지도 조작(줌/이동) 가능.
          IgnorePointer(
            ignoring: widget.touchToggle && !_touchOn,
            // iOS 플랫폼 뷰는 같은 controller의 WebViewWidget을 제거 후 재생성하면
            // recreating_view 예외가 발생한다. 로딩 중에도 WebView를 항상 유지한다.
            child: WebViewWidget(key: webViewKey, controller: controller),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, loading, child) {
              if (!loading) return const SizedBox.shrink();
              return const Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            },
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
          if (showTouchToggle)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(child: _touchToggleButton()),
            ),
        ],
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
