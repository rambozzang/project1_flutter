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
  /// 단, 광고 인스턴스가 교체(dispose 후 재생성)되면 캐시를 무효화해야 한다.
  Widget? _adWidget;
  AdManagerBannerAd? _cachedAd;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoaded = Get.find<RootCntr>().isAdLoaded(widget.screenName);
      final ad = AdManager().getBannerAd(widget.screenName);

      if (!isLoaded || ad == null) {
        _adWidget = null;
        _cachedAd = null;
        // 슬롯이 화면에 있는데 광고가 없으면 재로드를 요청한다(매니저에서 30초 디바운스).
        // 날씨 메인처럼 initState가 1회뿐인 탭에서 콜드스타트 로드 실패를 자가치유.
        Future.microtask(() => AdManager().ensureBannerAd(widget.screenName));
        return const SizedBox.shrink();
      }

      // 광고 인스턴스가 바뀌면 AdWidget을 새로 생성한다.
      if (_adWidget == null || _cachedAd != ad) {
        _cachedAd = ad;
        _adWidget = Container(
          alignment: Alignment.center,
          width: ad.sizes[0].width.toDouble(),
          height: ad.sizes[0].height.toDouble(),
          child: AdWidget(ad: ad),
        );
      }

      return _adWidget!;
    });
  }
}
