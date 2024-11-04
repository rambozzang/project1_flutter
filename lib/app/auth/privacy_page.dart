import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivecyPage extends StatefulWidget {
  const PrivecyPage({super.key});

  @override
  State<PrivecyPage> createState() => _PrivecyPageState();
}

class _PrivecyPageState extends State<PrivecyPage> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://skysnap.co.kr/privacy.html'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
