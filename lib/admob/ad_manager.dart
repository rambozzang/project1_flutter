import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/admob/ad_unit_ids.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  final Map<String, AdManagerBannerAd> _bannerAds = {};
  late final Map<String, String> _adUnitIds;
  final Map<String, Timer> _adTimers = {}; // 광고 갱신을 위한 타이머

  static Future<void> initialize({required TargetPlatform targetPlatform}) async {
    await MobileAds.instance.initialize();
    _instance._adUnitIds = Platform.isIOS ? AdUnitIds.ios : AdUnitIds.android;
  }

  bool isTestMode() {
    if (kDebugMode) {
      return true;
    } else {
      // In a real app, you might want to use a more sophisticated method
      // to determine if it's in test mode, such as checking for specific device IDs
      return false;
    }
  }

  Future<void> loadBannerAd(String screenName) async {
    if (!_bannerAds.containsKey(screenName)) {
      await _createAndLoadBannerAd(screenName);
    }
  }

  void _startAdTimer(String screenName) {
    _adTimers[screenName]?.cancel(); // 기존 타이머가 있으면 취소
    _adTimers[screenName] = Timer.periodic(const Duration(minutes: 5), (timer) {
      _createAndLoadBannerAd(screenName); // 5분마다 광고 갱신
    });
  }

  Future<void> _createAndLoadBannerAd(String screenName) async {
    try {
      final adUnitId = _adUnitIds[screenName];
      if (adUnitId == null) {
        throw Exception('Ad unit ID not found for screen: $screenName');
      }

      final ad = AdManagerBannerAd(
        adUnitId: adUnitId,
        request: const AdManagerAdRequest(nonPersonalizedAds: true),
        sizes: [AdSize.banner],
        listener: AdManagerBannerAdListener(
          onAdLoaded: (Ad ad) {
            lo.g('$AdManagerBannerAd loaded for $screenName.');
            Get.find<RootCntr>().updateAdLoadingStatus(screenName, true);
            _startAdTimer(screenName);
            _handleAdRetry(screenName, reset: true); // 재시도 카운터 리셋
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            lo.g('$AdManagerBannerAd failedToLoad for $screenName: $error');
            Get.find<RootCntr>().updateAdLoadingStatus(screenName, false);
            ad.dispose();
            _bannerAds.remove(screenName);
            _handleAdRetry(screenName); // 재시도 로직 호출
          },
          onAdOpened: (Ad ad) => lo.g('$AdManagerBannerAd onAdOpened for $screenName.'),
          onAdClosed: (Ad ad) => lo.g('$AdManagerBannerAd onAdClosed for $screenName.'),
        ),
      );

      await ad.load();
      _bannerAds[screenName] = ad;
    } catch (e) {
      lo.g('Error creating banner ad for $screenName: $e');
      Get.find<RootCntr>().updateAdLoadingStatus(screenName, false);
    }
  }

  final Map<String, int> _retryAttempts = {};
  final int maxRetryAttempts = 3;

  void _handleAdRetry(String screenName, {bool reset = false}) {
    if (reset) {
      _retryAttempts.remove(screenName);
      return;
    }

    _retryAttempts[screenName] = (_retryAttempts[screenName] ?? 0) + 1;

    if (_retryAttempts[screenName]! <= maxRetryAttempts) {
      final delay = Duration(seconds: pow(2, _retryAttempts[screenName]!).toInt()); // 지수 백오프
      Future.delayed(delay, () {
        if (_bannerAds[screenName] == null) {
          _createAndLoadBannerAd(screenName);
        }
      });
    }
  }

  void _cleanupAd(String screenName) {
    _bannerAds[screenName]?.dispose();
    _bannerAds.remove(screenName);
    _adTimers[screenName]?.cancel();
    _adTimers.remove(screenName);
    _retryAttempts.remove(screenName);
  }

  void disposeAllAds() {
    for (final screenName in _bannerAds.keys.toList()) {
      _cleanupAd(screenName);
    }
    disposeInterstitialAd();
    Get.find<RootCntr>().adLoadingStatus.clear();
  }

  AdManagerBannerAd? getBannerAd(String screenName) {
    return _bannerAds[screenName];
  }

  void disposeBannerAd(String screenName) {
    _bannerAds[screenName]?.dispose();
    _bannerAds.remove(screenName);
    _adTimers[screenName]?.cancel(); // 타이머 취소
    _adTimers.remove(screenName);
    Get.find<RootCntr>().updateAdLoadingStatus(screenName, false);
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: _adUnitIds['interstitial'] ?? '',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          Get.find<RootCntr>().updateInterstitialAdStatus(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          lo.g('InterstitialAd failed to load: $error');
          _isInterstitialAdReady = false;
          Get.find<RootCntr>().updateInterstitialAdStatus(false);
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_isInterstitialAdReady) {
      _interstitialAd?.show();
      _isInterstitialAdReady = false;
      Get.find<RootCntr>().updateInterstitialAdStatus(false);
    }
  }

  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
    Get.find<RootCntr>().updateInterstitialAdStatus(false);
  }
}
