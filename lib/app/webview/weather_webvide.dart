import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/provider/weatherProvider.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';

class WeatherWebVidew extends StatefulWidget {
  const WeatherWebVidew({super.key, required this.isBackBtn});
  final bool isBackBtn;

  @override
  State<WeatherWebVidew> createState() => _WeatherWebVidewState();
}

class _WeatherWebVidewState extends State<WeatherWebVidew> with AutomaticKeepAliveClientMixin<WeatherWebVidew> {
  final GlobalKey webViewKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      // 플랫폼 상관없이 동작하는 옵션
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true, // URL 로딩 제어
        mediaPlaybackRequiresUserGesture: false, // 미디어 자동 재생
        javaScriptEnabled: true, // 자바스크립트 실행 여부
        javaScriptCanOpenWindowsAutomatically: true, // 팝업 여부
      ),
      // 안드로이드 옵션
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true, // 하이브리드 사용을 위한 안드로이드 웹뷰 최적화
      ),
      // iOS 옵션
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true, // 웹뷰 내 미디어 재생 허용
      ));

  String openUrl = 'https://www.weather.go.kr/wgis-nuri/html/map.html';

  @override
  void initState() {
    super.initState();
    // double lon = Get.arguments['lon'].toDouble();
    // double lat = Get.arguments['lat'].toDouble();
    // openUrl = 'https://www.weather.go.kr/wgis-nuri/html/map.html?location=${lon},${lat}&zoom=10';
    // openUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=127.20,36.33,2780/loc=${lon},${lat}';
    Lo.g('openUrl $openUrl ');
    androidCheck();
  }

  Future<void> androidCheck() async {
    if (Platform.isAndroid) {
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
  }

  @override
  void dispose() {
    // webViewController.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //   title: const Text('기상청 날씨누리'),
        // ),
        body: Stack(
      children: [
        Consumer<WeatherProvider>(builder: (context, weatherProv, _) {
          openUrl =
              'https://earth.nullschool.net/#current/wind/surface/level/orthographic=127.20,36.33,2780/loc=${weatherProv.weather.long},${weatherProv.weather.lat}';

          return InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: Uri.parse(openUrl)),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                javaScriptCanOpenWindowsAutomatically: true,
                javaScriptEnabled: true,
                useOnDownloadStart: true,
                useOnLoadResource: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                verticalScrollBarEnabled: true,
                userAgent: 'random',
              ),
              android: AndroidInAppWebViewOptions(
                  useHybridComposition: true,
                  allowContentAccess: true,
                  builtInZoomControls: true,
                  thirdPartyCookiesEnabled: true,
                  allowFileAccess: true,
                  supportMultipleWindows: true),
              ios: IOSInAppWebViewOptions(
                allowsInlineMediaPlayback: true,
                allowsBackForwardNavigationGestures: true,
              ),
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              print('onLoadStart $url');
              Utils.progressbar();
            },
            onLoadStop: (controller, url) {
              print('onLoadStop $url');
            },
            onConsoleMessage: (controller, consoleMessage) {
              print('consoleMessage $consoleMessage');
            },
          );
        }),
        widget.isBackBtn
            ? Positioned(
                top: 45,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24.0),
                  onPressed: () => Get.back(),
                ))
            : const SizedBox.shrink(),
        // Positioned(
        //     top: 45,
        //     right: 10,
        //     child: IconButton(
        //       icon: const Icon(Icons.bolt, color: Colors.amber, size: 24.0),
        //       onPressed: () => webViewController?.reload(),
        //     )),
      ],
    ));
  }
}
