import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/utils.dart';

class WeatherWebView extends StatefulWidget {
  const WeatherWebView({super.key, required this.isBackBtn});
  final bool isBackBtn;

  @override
  State<WeatherWebView> createState() => _WeatherWebViewState();
}

class _WeatherWebViewState extends State<WeatherWebView> with AutomaticKeepAliveClientMixin<WeatherWebView> {
  final GlobalKey webViewKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  InAppWebViewController? webViewController;
  late final InAppWebViewSettings settings;

  final String baseUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=127.20,36.33,2780/loc=';
  String? openUrl;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _androidCheck();
  }

  void _initializeSettings() {
    settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true,
      useOnLoadResource: true,
      useShouldOverrideUrlLoading: true,
      javaScriptEnabled: true,
      cacheEnabled: true,
      transparentBackground: true,
    );
  }

  Future<void> _androidCheck() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
    }
  }

  @override
  void dispose() {
    webViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFF262B49),
      body: Stack(
        children: [
          _buildWebView(),
          if (widget.isBackBtn) _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return GetBuilder<WeatherGogoCntr>(
      builder: (weatherProv) {
        if (weatherProv.currentLocation.value?.latLng.longitude == null) {
          return Center(child: Utils.progressbar(color: Colors.white));
        }

        openUrl = '$baseUrl${weatherProv.currentLocation.value?.latLng.longitude},${weatherProv.currentLocation.value?.latLng.latitude}';

        return InAppWebView(
          key: webViewKey,
          initialUrlRequest: URLRequest(url: WebUri(openUrl!)),
          initialSettings: settings,
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onLoadStart: (controller, url) {
            Utils.progressbar();
          },
          onLoadStop: (controller, url) {
            // 로딩 완료 시 처리
          },
          onReceivedError: (controller, request, error) {
            print("WebView Error: $error");
            // 에러 처리 로직 추가
          },
          // gestureRecognizers: Set()..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer())),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 45,
      left: 10,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24.0),
        onPressed: () => Get.back(),
      ),
    );
  }
}
