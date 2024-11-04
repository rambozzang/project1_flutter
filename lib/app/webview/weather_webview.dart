// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:get/get.dart';
// import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
// import 'package:project1/utils/log_utils.dart';
// import 'package:project1/utils/utils.dart';

// class WeatherWebView extends StatefulWidget {
//   const WeatherWebView({super.key, required this.isBackBtn});
//   final bool isBackBtn;

//   @override
//   State<WeatherWebView> createState() => _WeatherWebViewState();
// }

// class _WeatherWebViewState extends State<WeatherWebView> with AutomaticKeepAliveClientMixin<WeatherWebView> {
//   final GlobalKey webViewKey = GlobalKey();

//   @override
//   bool get wantKeepAlive => true;

//   late final InAppWebViewController webViewController;
//   late final InAppWebViewSettings settings;

//   final String baseUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=127.20,36.33,2780/loc=';
//   String? openUrl;

//   @override
//   void initState() {
//     super.initState();
//     _initializeSettings();
//     _androidCheck();
//   }

//   void _initializeSettings() {
//     settings = InAppWebViewSettings(
//       isInspectable: kDebugMode,
//       useHybridComposition: true,
//       mediaPlaybackRequiresUserGesture: false,
//       allowsInlineMediaPlayback: true,
//       iframeAllow: "camera; microphone",
//       iframeAllowFullscreen: true,
//       useOnLoadResource: true,
//       useShouldOverrideUrlLoading: true,
//       javaScriptEnabled: true,
//       cacheEnabled: true,
//       clearCache: true,
//       transparentBackground: true,
//       allowsAirPlayForMediaPlayback: true,
//       javaScriptCanOpenWindowsAutomatically: true, // 팝업 여부
//       supportMultipleWindows: true, // 멀티 윈도우 허용
//       allowsBackForwardNavigationGestures: true,
//       limitsNavigationsToAppBoundDomains: false,
//       applePayAPIEnabled: false,
//       useShouldInterceptAjaxRequest: true,
//       useShouldInterceptFetchRequest: true,
//       contentBlockers: [
//         ContentBlocker(
//           trigger: ContentBlockerTrigger(
//             urlFilter: ".*",
//           ),
//           action: ContentBlockerAction(type: ContentBlockerActionType.CSS_DISPLAY_NONE, selector: ".selector-to-block"),
//         ),
//       ],
//     );
//   }

//   Future<void> _androidCheck() async {
//     if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
//       await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
//     }
//   }

//   @override
//   void dispose() {
//     webViewController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return Scaffold(
//       key: GlobalKey(),
//       backgroundColor: const Color(0xFF262B49),
//       body: Stack(
//         children: [
//           _buildWebView(),
//           if (widget.isBackBtn) _buildBackButton(),
//         ],
//       ),
//     );
//   }

//   Widget _buildWebView() {
//     return GetBuilder<WeatherGogoCntr>(
//       builder: (weatherProv) {
//         if (weatherProv.currentLocation.value.latLng.longitude == 0.0) {
//           return Center(child: Utils.progressbar(color: Colors.white));
//         }

//         final openUrl =
//             WebUri('$baseUrl${weatherProv.currentLocation.value?.latLng.longitude},${weatherProv.currentLocation.value?.latLng.latitude}');

//         openUrl.forceToStringRawValue = true;

//         return InAppWebView(
//           key: webViewKey,
//           initialUrlRequest: URLRequest(url: openUrl),
//           initialSettings: settings,
//           onWebViewCreated: (controller) {
//             webViewController = controller;
//           },
//           onLoadStart: (controller, url) {
//             Utils.progressbar();
//           },
//           onLoadStop: (controller, url) {
//             // 로딩 완료 시 처리
//             lo.e("WebView 시작");
//           },
//           onReceivedError: (controller, request, error) {
//             lo.e("WebView Error: $error");
//             lo.e("Error URL: ${request.url}");
//             lo.e("Error Description: ${error.description}");
//             // 에러 처리 로직 추가
//           },
//           // gestureRecognizers: Set()..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer())),
//         );
//       },
//     );
//   }

//   Widget _buildBackButton() {
//     return Positioned(
//       top: 45,
//       left: 10,
//       child: IconButton(
//         icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24.0),
//         onPressed: () => Get.back(),
//       ),
//     );
//   }
// }
