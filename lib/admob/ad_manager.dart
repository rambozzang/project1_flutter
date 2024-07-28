import 'dart:async';
import 'dart:io';
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

  static Future<void> initialize({required TargetPlatform targetPlatform}) async {
    await MobileAds.instance.initialize();
    _instance._adUnitIds = Platform.isIOS ? AdUnitIds.ios : AdUnitIds.android;
  }

  Future<void> loadBannerAd(String screenName) async {
    if (!_bannerAds.containsKey(screenName)) {
      await _createAndLoadBannerAd(screenName);
    }
  }

  Future<void> _createAndLoadBannerAd(String screenName) async {
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
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          lo.g('$AdManagerBannerAd failedToLoad for $screenName: $error');
          Get.find<RootCntr>().updateAdLoadingStatus(screenName, false);
          ad.dispose();
          _bannerAds.remove(screenName);
        },
        onAdOpened: (Ad ad) => lo.g('$AdManagerBannerAd onAdOpened for $screenName.'),
        onAdClosed: (Ad ad) => lo.g('$AdManagerBannerAd onAdClosed for $screenName.'),
      ),
    );

    await ad.load();
    _bannerAds[screenName] = ad;
  }

  AdManagerBannerAd? getBannerAd(String screenName) {
    return _bannerAds[screenName];
  }

  void disposeBannerAd(String screenName) {
    _bannerAds[screenName]?.dispose();
    _bannerAds.remove(screenName);
    Get.find<RootCntr>().updateAdLoadingStatus(screenName, false);
  }

  void disposeAllAds() {
    for (var ad in _bannerAds.values) {
      ad.dispose();
    }
    _bannerAds.clear();
    Get.find<RootCntr>().adLoadingStatus.clear();
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
