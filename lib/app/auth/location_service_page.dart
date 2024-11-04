import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LocatinServicePage extends StatefulWidget {
  const LocatinServicePage({super.key});

  @override
  State<LocatinServicePage> createState() => _LocatinServicePageState();
}

class _LocatinServicePageState extends State<LocatinServicePage> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://skysnap.co.kr/location_service.html'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위치기반서비스 이용약관'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
