import 'dart:async';
import 'dart:io';

import 'package:animate_icons/animate_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/test/cloud/cloud_page.dart';
import 'package:project1/app/test/darkcloud/darkcloud_page.dart';
import 'package:project1/app/test/hazy/hazy_page.dart';
import 'package:project1/app/test/rain/RainAnimation.dart';
import 'package:project1/app/test/raindrop/raindrop_page.dart';
import 'package:project1/app/test/snow/SnowAnimation.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weathergogo/appbar_page.dart';
import 'package:project1/app/weathergogo/detail_main_page.dart';
import 'package:project1/app/weathergogo/header_main_page.dart';
import 'package:project1/app/weathergogo/seven_day_page.dart';
import 'package:project1/app/weathergogo/twenty4_page.dart';
import 'package:project1/app/weathergogo/weathergogo_kakao_searchbar.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/webview/common_webview.dart';
import 'package:project1/repo/cust/data/cust_tag_res_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

class WeathgergogoPage extends StatefulWidget {
  const WeathgergogoPage({super.key});

  @override
  State<WeathgergogoPage> createState() => WeathgergogoPageState();
}

class WeathgergogoPageState extends State<WeathgergogoPage> with AutomaticKeepAliveClientMixin<WeathgergogoPage>, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // 섹션 리스트 정의
  final List<Widget Function()> sections = [];
  late AnimateIconController controller;

  // final WeatherGogoCntr controller = Get.find();
  ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    controller = AnimateIconController();
    _loadAd();
    _initializeSections();
  }

  void _initializeSections() {
    sections.addAll([
      () => buildFavLocal(),
      () => _buildWeatherInfoHeader(),
      () => const HeaderMainPage(),
      () => const DetailMainPage(),
      () => _buildAdWidget(),
      () => const Twenty4Page(),
      () => const SevenDayPage(),
      // () => const NaverScraPpingPage(),
      () => _buildWeatherWebView(),
      () => const SizedBox(height: 50),
    ]);
    Get.find<WeatherGogoCntr>().getLocalTag();
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('WeatherPage');
    isAdLoading.value = true;
  }

/*
/ Primary colors
  static const Color primaryBlue = Color(0xFF00ADEF);
  static const Color silver = Color(0xFFCCCCCC);
  static const Color darkGrey = Color(0xFF333333);

*/
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF262B49),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          backgroundColor: Colors.transparent,
          title: const AppbarPage(),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 29, 33, 56), Color.fromARGB(255, 45, 52, 91)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              // 비 애니메이션
              RainAnimation2(isVisibleNotifier: Get.find<WeatherGogoCntr>().isRainVisibleNotifier),
              SnowAnimation2(isVisibleNotifier: Get.find<WeatherGogoCntr>().isSnowVisibleNotifier),
              CloudyAnimation(isVisibleNotifier: Get.find<WeatherGogoCntr>().isCloudVisibleNotifier),
              HazyAnimation(isVisibleNotifier: Get.find<WeatherGogoCntr>().isHazyVisibleNotifier),
              RainDropAnimation(isVisibleNotifier: Get.find<WeatherGogoCntr>().isRainDropVisibleNotifier),
              DarkCloudsAnimation(isVisibleNotifier: Get.find<WeatherGogoCntr>().isDarkCloudVisibleNotifier),
              _buildLazyLoadingContent(),

              const WeathergogoKakaoSearchPage(),

              // _buildLoadingIndicator(),
            ],
          ),
        ));
  }

  var physic = Platform.isIOS ? const AlwaysScrollableScrollPhysics() : const BouncingScrollPhysics();

  Widget _buildLazyLoadingContent2() {
    return SingleChildScrollView(
      controller: RootCntr.to.hideButtonController5,
      physics: physic,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.0).copyWith(
        top: kToolbarHeight + 3,
      ),
      child: Column(
        children: sections.map((section) => section()).toList(),
      ),
    );
  }

  Widget _buildLazyLoadingContent() {
    return ListView.builder(
      controller: RootCntr.to.hideButtonController5,
      physics: physic,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.0).copyWith(
        top: kToolbarHeight + 3,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return sections[index]();
      },
    );
  }

  Widget _buildWeatherInfoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('날씨 정보', style: semiboldText.copyWith(fontSize: 24.0)),
              const Gap(20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black87, // 텍스트 및 아이콘 색상
                  backgroundColor: Colors.white12, // 버튼 배경색
                  elevation: 4, // 그림자 높이
                  shadowColor: Colors.black.withOpacity(0.3), // 그림자 색상
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  minimumSize: const Size(67, 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 더 둥근 모서리
                  ),
                ),
                onPressed: () => Get.toNamed('/WeatherComPage'),
                child: Row(
                  children: [
                    Text('날씨 비교 ', style: semiboldText.copyWith(fontSize: 11.0)),
                    const Icon(Icons.arrow_forward_ios, size: 10.0, color: Colors.amber),
                  ],
                ),
              ),
              const Gap(10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black87, // 텍스트 및 아이콘 색상
                  backgroundColor: Colors.white12, // 버튼 배경색
                  elevation: 4, // 그림자 높이
                  shadowColor: Colors.black.withOpacity(0.3), // 그림자 색상
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  minimumSize: const Size(67, 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 더 둥근 모서리
                  ),
                ),
                onPressed: () => Get.toNamed('/MapPage'), // Get.find<WeatherGogoCntr>().test(), //
                child: Row(
                  children: [
                    Text('지도 보기 ', style: semiboldText.copyWith(fontSize: 11.0)),
                    const Icon(Icons.arrow_forward_ios, size: 10.0, color: Colors.amber),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        AnimateIcons(
          startIcon: Icons.refresh,
          endIcon: Icons.refresh_rounded,
          controller: controller,
          // add this tooltip for the start icon
          startTooltip: 'Icons.refresh',
          // add this tooltip for the end icon
          endTooltip: 'Icons.refresh_rounded',
          size: 26.0,
          onStartIconPress: () {
            Get.find<WeatherGogoCntr>().getRefreshWeatherData(true);
            return true;
          },
          onEndIconPress: () {
            Get.find<WeatherGogoCntr>().getRefreshWeatherData(true);
            return true;
          },
          duration: Duration(milliseconds: 500),
          startIconColor: Colors.amber,
          endIconColor: Colors.amber,
          clockwise: false,
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildAdWidget() {
    return ValueListenableBuilder<bool>(
        valueListenable: isAdLoading,
        builder: (context, value, child) {
          if (!value) {
            return const SizedBox(
              height: 20,
            );
          }
          return const Center(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
                child: SizedBox(height: 70, child: BannerAdWidget(screenName: 'WeatherPage'))),
          );
        });
  }

  Widget _buildWeatherWebView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // const SizedBox(height: 600, child: WeatherWebView(key: PageStorageKey<String>('webview'), isBackBtn: false)),
          SizedBox(
              height: 600,
              child: CommonWebView(
                isBackBtn: false,
                url: Get.find<WeatherGogoCntr>().webViewUrl.value,
              )),
          const Gap(10),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white12,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              minimumSize: const Size(50, 22),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  fullscreenDialog: false,
                  builder: (context) => CommonWebView(
                        isBackBtn: true,
                        url: Get.find<WeatherGogoCntr>().webViewUrl.value,
                      )),
            ), // Get.toNamed('/WeatherWebView'),
            child: Text('전체화면으로 ', style: semiboldText.copyWith(fontSize: 11.0)),
          ),
          const Gap(40)
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final cntr = Get.find<WeatherGogoCntr>();
    return Obx(() => CustomIndicatorOffstage(
          isLoading: !cntr.isLoading.value,
          color: const Color(0xFFEA3799),
          opacity: 0.5,
        ));
  }

  // 관심지역 리스트
  Widget buildFavLocal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      width: double.infinity,
      child: Obx(() {
        if (Get.find<WeatherGogoCntr>().areaList.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            child: Row(
              children: [
                InkWell(
                    onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => Get.find<WeatherGogoCntr>().getLocalTag()),
                    child: const Text('관심지역', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))),
                const Gap(3),
                const Icon(Icons.arrow_circle_right_outlined, color: Colors.white, size: 16),
                const Gap(6),
                Text(
                  '등록된 관심지역이 없습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Row(children: [
            InkWell(
                onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => Get.find<WeatherGogoCntr>().getLocalTag()),
                child: const Text('관심지역', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))),
            const Gap(3),
            InkWell(
                onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => Get.find<WeatherGogoCntr>().getLocalTag()),
                child: const Icon(Icons.arrow_circle_right_outlined, color: Colors.white, size: 16)),
            const Gap(5),
            ...Get.find<WeatherGogoCntr>().areaList.map((e) => buildLocalChip(e)).toList(),
          ]),
        );
      }),
    );
  }

  // 지역
  Widget buildLocalChip(CustagResData data) {
    return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              late GeocodeData geocodeData = GeocodeData(
                name: data.id!.tagNm.toString(),
                latLng: LatLng(double.parse(data.lat.toString()), double.parse(data.lon.toString())),
              );
              Get.find<WeatherGogoCntr>().searchWeatherKakao(geocodeData);
            },
            child: Chip(
              elevation: 4,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              backgroundColor: const Color.fromARGB(255, 122, 110, 199), // Color.fromARGB(255, 76, 70, 124),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color.fromARGB(0, 166, 155, 155)),
              ),
              label: Text(
                data.id!.tagNm.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.0),
              ),
              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            ),
          ),
        ));
  }
}

class RainbowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final rainbow = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];

    // 검은색 배경 그리기
    canvas.drawRect(rect, Paint()..color = Colors.black);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 14; // 무지개 띠의 두께를 화면 크기에 비례하게 설정

    final center = Offset(size.width / 2, size.height);
    final radius = size.height * 1.5; // 무지개의 반지름을 화면 높이의 1.5배로 설정

    for (int i = rainbow.length - 1; i >= 0; i--) {
      paint.color = rainbow[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (i * paint.strokeWidth)),
        pi,
        pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
