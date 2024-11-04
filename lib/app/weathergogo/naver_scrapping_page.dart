import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/webview/common_news_webview.dart';
import 'package:project1/repo/common/code_data.dart';

class NaverNewPage extends StatefulWidget {
  const NaverNewPage({super.key});

  @override
  State<NaverNewPage> createState() => _NaverNewPageState();
}

class _NaverNewPageState extends State<NaverNewPage> {
  final cntr = Get.find<WeatherGogoCntr>();
  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final naverNewsList = cntr.naverNewsList;
        if (cntr.naverNewsList.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  PhosphorIcon(PhosphorIconsRegular.newspaper, color: Colors.white),
                  SizedBox(width: 4.0),
                  Text(
                    '오늘의 방송예보',
                    style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                ],
              ),
              const SizedBox(height: 10),
              ListView.builder(
                itemCount: cntr.naverNewsList.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return _buildNaverNews(context, cntr.naverNewsList[index]);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNaverNews(BuildContext context, CodeRes codeRes) {
    return Material(
      color: Colors.transparent, //Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  fullscreenDialog: false,
                  builder: (context) => CommonNewsWebView(
                        isBackBtn: true,
                        url: codeRes.grpDesc ?? '',
                      )),
            );
          },
          child: SizedBox(
            height: 95,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                    flex: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: CachedNetworkImage(
                        height: 95,
                        // placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        fadeInDuration: const Duration(milliseconds: 100),
                        fadeOutDuration: const Duration(milliseconds: 100),
                        imageUrl: codeRes.etc1 ?? '',
                        fit: BoxFit.cover,
                      ),
                    )),
                const SizedBox(width: 10),
                Flexible(
                  flex: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        codeRes.codeNm?.replaceAll('[날씨] ', '').replaceAll('[날씨]', '') ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      // const Spacer(),
                      Row(
                        children: [
                          Text(
                            codeRes.grpNm ?? '',
                            style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                          const Text(' · ', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(
                            codeRes.etc2 ?? '',
                            style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
