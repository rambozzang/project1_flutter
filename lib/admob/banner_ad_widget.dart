import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/root/cntr/root_cntr.dart';

class BannerAdWidget extends StatefulWidget {
  final String screenName;

  const BannerAdWidget({super.key, required this.screenName});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  /// AdWidget은 동일한 광고 인스턴스로 여러 번 build 되면 안 되므로
  /// 한 번 생성된 위젯을 캐싱해서 재사용한다.
  Widget? _adWidget;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoaded = Get.find<RootCntr>().isAdLoaded(widget.screenName);
      final ad = AdManager().getBannerAd(widget.screenName);

      if (!isLoaded || ad == null) {
        return const SizedBox.shrink();
      }

      _adWidget ??= Container(
        alignment: Alignment.center,
        width: ad.sizes[0].width.toDouble(),
        height: ad.sizes[0].height.toDouble(),
        child: AdWidget(ad: ad),
      );

      return _adWidget!;
    });
  }
}
