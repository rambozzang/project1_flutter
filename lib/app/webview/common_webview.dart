import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/utils/utils.dart';

class CommonWebView extends StatefulWidget {
  const CommonWebView({super.key, required this.isBackBtn, required this.url});
  final bool isBackBtn;
  final String url;

  @override
  State<CommonWebView> createState() => _CommonWebViewState();
}

class _CommonWebViewState extends State<CommonWebView> with AutomaticKeepAliveClientMixin<CommonWebView> {
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

  late String openUrl;
  @override
  void initState() {
    super.initState();
    openUrl = widget.url;
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
        //  backgroundColor: const Color(0xFF262B49), // Colors.black54,
        body: Stack(
      children: [
        InAppWebView(
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
        ),
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
