import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/utils/log_utils.dart';

/// 영상 피드(틱톡형)에 5장마다 끼워넣는 풀스크린 네이티브 광고 페이지.
/// 다른 영상 페이지처럼 위/아래로 스와이프해 넘길 수 있다.
///
/// 광고 유닛: 현재는 Google 테스트 네이티브 ID. 운영 수익화 시
/// AdMob에서 "네이티브 광고" 유닛을 발급받아 [_adUnitId]를 교체할 것.
class NativeFeedAdPage extends StatefulWidget {
  const NativeFeedAdPage({super.key});

  @override
  State<NativeFeedAdPage> createState() => _NativeFeedAdPageState();
}

class _NativeFeedAdPageState extends State<NativeFeedAdPage> with AutomaticKeepAliveClientMixin {
  NativeAd? _nativeAd;
  bool _loaded = false;

  // Google 공식 테스트 네이티브 광고 유닛 ID (운영 발급 후 교체)
  static String get _adUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/3986624511'
      : 'ca-app-pub-3940256099942544/2247696110';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 14.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF8C83DD),
          size: 16.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _loaded = true);
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          lo.g('NativeFeedAd 로드 실패: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 상단 'AD' 라벨
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Sponsored',
                style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
            ),
            // 네이티브 광고 본문 (medium 템플릿 = 높이 ~320 카드)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _loaded && _nativeAd != null
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 320, maxHeight: 360, maxWidth: 400),
                      child: AdWidget(ad: _nativeAd!),
                    )
                  : const SizedBox(
                      height: 320,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
                      ),
                    ),
            ),
            // 하단 스와이프 안내
            const Padding(
              padding: EdgeInsets.only(top: 28),
              child: Column(
                children: [
                  Icon(Icons.keyboard_arrow_up, color: Colors.white38, size: 26),
                  Text('위로 넘겨 계속 보기', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
