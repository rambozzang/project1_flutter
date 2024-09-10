import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as parser;

class WeatherCrawler {
  static Future<List<Map<String, dynamic>>> crawlWeatherForecast() async {
    final Completer<List<Map<String, dynamic>>> completer = Completer();

    final headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri("https://weather.naver.com/")),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
      ),
      onLoadStop: (controller, url) async {
        await Future.delayed(Duration(seconds: 5)); // 페이지 로드 후 추가 대기 시간
        final result = await controller.evaluateJavascript(source: _extractForecastsScript);

        if (result != null) {
          try {
            final forecasts = List<Map<String, dynamic>>.from(jsonDecode(result));
            completer.complete(forecasts);
          } catch (e) {
            completer.completeError('데이터 파싱 실패: $e');
          }
        } else {
          completer.completeError('데이터 추출 실패');
        }

        // await headlessWebView.dispose();
      },
    );

    await headlessWebView.run();
    return completer.future;
  }

  static Future<void> _waitForPageLoad(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      return new Promise((resolve) => {
        if (document.readyState === 'complete') {
          resolve();
        } else {
          window.addEventListener('load', resolve);
        }
      });
    ''');
  }

  static const String _extractForecastsScript = '''
    function waitForElement(selector, timeout = 30000) {
      return new Promise((resolve, reject) => {
        const startTime = Date.now();
        
        function checkElement() {
          const element = document.querySelector(selector);
          if (element) {
            resolve(element);
          } else if (Date.now() - startTime > timeout) {
            reject(new Error('요소를 찾을 수 없습니다: ' + selector));
          } else {
            setTimeout(checkElement, 100);
          }
        }
        
        checkElement();
      });
    }

    async function extractForecasts() {
      try {
        await waitForElement('.card_list_inner._newsArea');
        
        const items = document.querySelectorAll('.card_list_inner._newsArea .card_list_item._news');
        const forecasts = [];

        for (let i = 0; i < 6 && i < items.length; i++) {
          const item = items[i];
          const title = item.querySelector('.card_data_title')?.textContent.trim() || '';
          const provider = item.querySelector('.card_info_item:first-child')?.textContent.trim() || '';
          const time = item.querySelector('.card_info_item:last-child')?.textContent.trim() || '';
          const imageUrl = item.querySelector('img')?.src || '';
          const link = item.href || '';

          forecasts.push({
            title: title,
            provider: provider,
            time: time,
            imageUrl: imageUrl,
            link: link
          });
        }

        return JSON.stringify(forecasts);
      } catch (error) {
        console.error('데이터 추출 중 오류 발생:', error);
        return JSON.stringify([]);
      }
    }

    extractForecasts();
  ''';
}
