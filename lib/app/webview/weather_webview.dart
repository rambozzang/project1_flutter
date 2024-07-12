import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
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
  InAppWebViewSettings webViewSettings = InAppWebViewSettings(
    userAgent:
        'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.152 Mobile Safari/537.36',
  );

  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  String openUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=127.20,36.33,2780/loc=';

  // String openUrl = 'https://www.windy.com/ko/-%EB%A9%94%EB%89%B4/menu?radar,38.197,127.389,8,m:eHyajGV';

  @override
  void initState() {
    super.initState();
    // double lon = Get.arguments['lon'].toDouble();
    // double lat = Get.arguments['lat'].toDouble();
    // openUrl = 'https://www.weather.go.kr/wgis-nuri/html/map.html?location=${lon},${lat}&zoom=10';
    // openUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=127.20,36.33,2780/loc=${lon},${lat}';

    androidCheck();
  }

  Future<void> androidCheck() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
    }
  }

  @override
  void dispose() {
    // webViewController.
    // webViewController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        backgroundColor: const Color(0xFF262B49), // Colors.black54,
        body: Stack(
          children: [
            GetBuilder<WeatherCntr>(builder: (weatherProv) {
              openUrl =
                  '$openUrl${weatherProv.currentLocation.value?.latLng.longitude},${weatherProv.currentLocation.value?.latLng.latitude}';
              if (weatherProv.currentLocation.value?.latLng.longitude == null) {
                return Center(child: Utils.progressbar(color: Colors.white));
              }

              return InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(openUrl)),
                initialSettings: settings,
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  Utils.progressbar();
                },
                onLoadStop: (controller, url) {},
                onConsoleMessage: (controller, consoleMessage) {},
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
          ],
        ));
  }
}
