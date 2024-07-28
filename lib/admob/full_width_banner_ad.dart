import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/root/cntr/root_cntr.dart';

class FullWidthBannerAd extends StatelessWidget {
  final AdManagerBannerAd? bannerAd;
  final double sidePadding;

  const FullWidthBannerAd({super.key, required this.bannerAd, this.sidePadding = 0});

  @override
  Widget build(BuildContext context) {
    // if (bannerAd != null) {
    // bannerAd!.load();

    return Obx(() => (Get.find<RootCntr>().adLoadingStatus['VideoPage']?.value == true)
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: AdWidget(ad: bannerAd!))
        : Container(
            width: 500,
            height: 500,
            child: Center(
                child: Text(
              Get.find<RootCntr>().adLoadingStatus['VideoPage'] == null
                  ? '로딩중'
                  : Get.find<RootCntr>().adLoadingStatus['VideoPage']!.value.toString(),
              style: const TextStyle(color: Colors.white),
            )),
          ));
  }
}
