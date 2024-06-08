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
    bannerAd!.load();

    return Obx(() => Get.find<RootCntr>().isAdLoading.value
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            height: bannerAd!.sizes.first.height.toDouble(),
            child: AdWidget(ad: bannerAd!))
        : const SizedBox(width: 0, height: 0));
    // } else {
    //   return const SizedBox(width: 0, height: 0);
    // }
  }
}
