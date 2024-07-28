import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/root/cntr/root_cntr.dart';

class BannerAdWidget extends StatelessWidget {
  final String screenName;

  const BannerAdWidget({Key? key, required this.screenName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoaded = Get.find<RootCntr>().isAdLoaded(screenName);
      final ad = AdManager().getBannerAd(screenName);

      if (isLoaded && ad != null) {
        return Container(
          alignment: Alignment.center,
          width: ad.sizes[0].width.toDouble(),
          height: ad.sizes[0].height.toDouble(),
          child: AdWidget(ad: ad),
        );
      } else {
        return SizedBox.shrink(); // 광고가 로드되지 않았거나 없는 경우 빈 공간 표시
      }
    });
  }
}
