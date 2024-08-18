import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:project1/app/webview/common_webview.dart';
import 'package:project1/utils/log_utils.dart';

class NaverScrappingPage extends StatefulWidget {
  const NaverScrappingPage({Key? key}) : super(key: key);

  @override
  State<NaverScrappingPage> createState() => _NaverScrappingPageState();
}

class _NaverScrappingPageState extends State<NaverScrappingPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<NewsItem> news = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  Future<void> loadNews() async {
    setState(() {
      isLoading = true;
    });
    try {
      news = await scrapeNews();
    } catch (e) {
      lo.g("뉴스 스크래핑 중 오류 발생: $e");
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<List<NewsItem>> scrapeNews() async {
    const url = 'https://weather.naver.com/today/09440121?cpName=KMA';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': 'https://weather.naver.com/',
          'Accept': 'application/json',
          'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
        },
      );

      lo.g("Response status: ${response.statusCode}");
      lo.g("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newsList = jsonData['newsList'] as List<dynamic>? ?? [];

        lo.g("Found ${newsList.length} news items");

        return newsList.map((item) {
          return NewsItem(
            title: item['title'] ?? '',
            imageUrl: item['imageUrl'] ?? '',
            source: item['officeNameKorean'] ?? '',
            time: item['datetime'] ?? '',
            link: item['linkUrl'] ?? '',
            isVideo: item['isVideo'] ?? false,
          );
        }).toList();
      } else {
        throw Exception('Failed to load news. Status code: ${response.statusCode}');
      }
    } catch (e) {
      lo.e("네이버 뉴스 API 호출 오류: $e");
      return [];
    }
  }

  // Helper function to get the minimum of two integers
  int min(int a, int b) {
    return (a < b) ? a : b;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('네이버 날씨 뉴스'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadNews,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : news.isEmpty
              ? Center(child: Text('뉴스를 불러올 수 없습니다.'))
              : ListView.builder(
                  itemCount: news.length,
                  itemBuilder: (context, index) {
                    final item = news[index];
                    return NewsItemTile(item: item);
                  },
                ),
    );
  }
}

class NewsItemTile extends StatelessWidget {
  final NewsItem item;

  const NewsItemTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: item.imageUrl.isNotEmpty
          ? Stack(
              children: [
                Image.network(
                  item.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.error, size: 100),
                ),
                if (item.isVideo)
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Icon(Icons.play_circle_outline, color: Colors.white),
                  ),
              ],
            )
          : null,
      title: Text(item.title),
      subtitle: Text('${item.source} • ${item.time}'),
      onTap: () => _launchURL(item.link),
    );
  }

  void _launchURL(String urlPath) {
    // Get.to(() => CommonWebView(
    //       isBackBtn: false,
    //       url: urlPath,
    //     ));
  }
}

class NewsItem {
  final String title;
  final String imageUrl;
  final String source;
  final String time;
  final String link;
  final bool isVideo;

  NewsItem({
    required this.title,
    required this.imageUrl,
    required this.source,
    required this.time,
    required this.link,
    this.isVideo = false,
  });
}
