import 'package:flutter/material.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'dart:math';

class VideoAdScreenPage extends StatefulWidget {
  final int index;

  const VideoAdScreenPage({Key? key, required this.index}) : super(key: key);

  @override
  State<VideoAdScreenPage> createState() => _VideoAdPageState();
}

class _VideoAdPageState extends State<VideoAdScreenPage> {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _getInterstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  // String _getInterstitialAdUnitId() {
  //   if (Platform.isAndroid) {
  //     return 'ca-app-pub-3940256099942544/1033173712'; // Android test ad unit ID
  //   } else if (Platform.isIOS) {
  //     return 'ca-app-pub-3940256099942544/4411468910'; // iOS test ad unit ID
  //   }
  //   throw UnsupportedError('Unsupported platform');
  // }
  String _getInterstitialAdUnitId() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7861255216779015/9035579155'; // Android test ad unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7861255216779015/8309654992'; // iOS test ad unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _showInterstitialAd() {
    // if (_isInterstitialAdLoaded && _random.nextDouble() < 0.3) {
    // 30% 확률로 광고 표시
    _interstitialAd?.show();
    _isInterstitialAdLoaded = false;
    _loadInterstitialAd(); // 새 광고 로드
    // }
  }

  @override
  Widget build(BuildContext context) {
    // 페이지가 보일 때마다 광고 표시 시도
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInterstitialAd();
    });

    return Container(
      color: Colors.primaries[widget.index % Colors.primaries.length],
      child: Stack(
        children: [
          // 여기에 실제 비디오 플레이어나 콘텐츠를 추가하세요
          Center(
            child: Text(
              'Video ${widget.index + 1}',
              style: TextStyle(fontSize: 30, color: Colors.white),
            ),
          ),
          // 배너 광고를 추가하고 싶다면 여기에 추가할 수 있습니다
        ],
      ),
    );
  }
}
