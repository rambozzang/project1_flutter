import 'dart:io';

import 'package:flutter/src/foundation/platform.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';

class AdManager {
  AdManager(
      {this.myCafeScreenBannerAd,
      this.challengeScreenBannerAd,
      this.myPageScreenBannerAd,
      this.shopScreenBannerAd,
      this.notificationScreenBannerAd,
      this.bottomFullSheetBannerAd});

  // singleton instance
  static AdManager instance = AdManager();

  // 스크린 별로 사용될 AdManagerBannerAd 객체들
  AdManagerBannerAd? myCafeScreenBannerAd;
  AdManagerBannerAd? challengeScreenBannerAd;
  AdManagerBannerAd? myPageScreenBannerAd;
  AdManagerBannerAd? shopScreenBannerAd;
  AdManagerBannerAd? notificationScreenBannerAd;
  AdManagerBannerAd? bottomFullSheetBannerAd;

  // AdManager 객체 초기화
  factory AdManager.init({required TargetPlatform targetPlatform}) => instance = AdManager(
        myCafeScreenBannerAd: _loadBannerAd(),
        challengeScreenBannerAd: _loadBannerAd(),
        myPageScreenBannerAd: _loadBannerAd(),
        shopScreenBannerAd: _loadBannerAd(),
        notificationScreenBannerAd: _loadBannerAd(),
        bottomFullSheetBannerAd: _loadBannerAd(),
      );
}

// AdManagerBannerAd 객체를 로드하는 함수
AdManagerBannerAd _loadBannerAd() {
  const String androidBannerAdUnitId = 'ca-app-pub-7861255216779015/5865639305';
  // const String iosBannerAdUnitId = 'ca-app-pub-7861255216779015/2265105950';
  const String iosBannerAdUnitId = 'ca-app-pub-7861255216779015/6643334668';

  String adUnitId = androidBannerAdUnitId;
  if (Platform.isIOS) adUnitId = iosBannerAdUnitId;

  return AdManagerBannerAd(
    adUnitId: adUnitId,
    request: const AdManagerAdRequest(nonPersonalizedAds: true),
    sizes: [AdSize.banner],
    listener: AdManagerBannerAdListener(
      onAdLoaded: (Ad ad) {
        lo.g('$AdManagerBannerAd loaded.');
        Get.find<RootCntr>().isAdLoading.value = true;
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        lo.g('$AdManagerBannerAd failedToLoad: $error');
        ad.dispose();
      },
      onAdOpened: (Ad ad) => lo.g('$AdManagerBannerAd onAdOpened.'),
      onAdClosed: (Ad ad) => lo.g('$AdManagerBannerAd onAdClosed.'),
    ),
  )..load();
}
