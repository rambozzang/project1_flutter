import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:animate_icons/animate_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/join/widget/TwinklingStar.dart';
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
import 'package:project1/app/weathergogo/naver_scrapping_page.dart';
import 'package:project1/app/weathergogo/seven_day_chart.dart';
import 'package:project1/app/weathergogo/twenty4_page.dart';
import 'package:project1/app/weathergogo/weather_webview.dart';
import 'package:project1/app/weathergogo/weathergogo_kakao_searchbar.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/cust/data/cust_tag_res_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/ShimmeringText.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
import 'package:project1/widget/custom_tabbarview.dart';
import 'package:text_scroll/text_scroll.dart';

class WeathgergogoPage extends StatefulWidget {
  const WeathgergogoPage({super.key});

  @override
  State<WeathgergogoPage> createState() => WeathgergogoPageState();
}

class WeathgergogoPageState extends State<WeathgergogoPage> with AutomaticKeepAliveClientMixin<WeathgergogoPage> {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // 섹션 리스트 정의
  final List<Widget Function()> sections = [];
  late AnimateIconController controller;

  // final WeatherGogoCntr controller = Get.find();
  ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  List<TwinklingStar> twinklingStars = [];
  ValueNotifier<List<TwinklingStar>> starsNotifier = ValueNotifier<List<TwinklingStar>>([]);

  List<Color> currentColors = [];
  late Color appbarColor;

  bool isStartStart = false;

  @override
  void initState() {
    super.initState();

    controller = AnimateIconController();
    _loadAd();
    _initializeSections();
  }

  // instState 할수 다음에 호출되는 메써드
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 오후 7시부터 새벽 7시까지 createTwinklingStars() 메써드를 호출
    final now = DateTime.now();
    if ((now.hour >= 19 || now.hour < 7) && isStartStart == false) {
      createTwinklingStars();
    }
  }

  void _initializeSections() {
    sections.addAll([
      () => buildFavLocal(),
      () => _buildWeatherInfoHeader(),
      () => const HeaderMainPage(
            key: ValueKey('HeaderMainPage'),
          ),
      () => const DetailMainPage(
            key: ValueKey('DetailMainPage'),
          ),
      () => _buildAdWidget(),
      () => const Twenty4Page(
            key: ValueKey('Twenty4Page'),
          ),
      // () => const SevenDayPage(
      //       key: ValueKey('SevenDayPage'),
      //     ),
      () => const DailyWeatherChart(),

      // () => const SizedBox(height: 10),
      () => const NaverNewPage(
            key: ValueKey('NaverNewPage'),
          ),
      // () => _buildWeatherWebView(),
      () => const WeatherWEbviewPage(),
      () => const SizedBox(
            height: 40,
          ),
    ]);
    Get.find<WeatherGogoCntr>().getLocalTag();
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('WeatherPage');
    isAdLoading.value = true;
  }

  void createTwinklingStars() {
    twinklingStars = [];
    isStartStart = true;
    for (int i = 0; i < 100; i++) {
      twinklingStars.add(TwinklingStar(
          Random().nextDouble() * MediaQuery.of(context).size.width, Random().nextDouble() * MediaQuery.of(context).size.height));
    }
    starsNotifier.value = twinklingStars;
    startObjectMovement();
  }

  Timer? _animationTimer;

  void startObjectMovement() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        updateStarPositions();
      } else {
        timer.cancel();
      }
    });
  }

  void updateStarPositions() {
    List<TwinklingStar> updatedStars = starsNotifier.value.map((star) {
      star.twinkle();
      return star;
    }).toList();
    starsNotifier.value = updatedStars;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Get.find<WeatherGogoCntr>().currentColors.first,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          backgroundColor: Colors.transparent,
          title: const AppbarPage(),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: Get.find<WeatherGogoCntr>().currentColors,
            ),
          ),
          child: Stack(
            children: <Widget>[
              buildStarts(),
              // NightSun(isVisibleNotifier: Get.find<WeatherGogoCntr>().isNightSun, top: 0, right: 0),
              // DaySun(isVisibleNotifier: Get.find<WeatherGogoCntr>().isDaySun, top: 56, right: 20),
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

  Widget buildStarts() {
    return ValueListenableBuilder<List<TwinklingStar>>(
      valueListenable: starsNotifier,
      builder: (context, stars, child) {
        return Stack(
          children: stars
              .map((star) => Positioned(
                    left: star.x,
                    top: star.y,
                    child: Opacity(
                      opacity: star.opacity,
                      child: Container(
                        width: star.opacity * 5,
                        height: star.opacity * 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  // var physic = Platform.isIOS ? const AlwaysScrollableScrollPhysics() : const BouncingScrollPhysics();
  var physic = const CustomTabBarViewScrollPhysics();

  Widget _buildLazyLoadingContent2() {
    return SingleChildScrollView(
      controller: RootCntr.to.hideButtonController5,
      physics: const BouncingScrollPhysics(),
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
      cacheExtent: 5000,
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
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 4.0),
      child: Column(
        children: [
          Obx(() {
            if (Get.find<WeatherGogoCntr>().weatherAlert.value == null) {
              return const SizedBox();
            }
            final String tmFc = Get.find<WeatherGogoCntr>().weatherAlert.value!.tmFc.toString();
            // 날짜 형식 변경 .
            final String tmFc2 =
                '${tmFc.substring(0, 4)}.${tmFc.substring(4, 6)}.${tmFc.substring(6, 8)} ${tmFc.substring(8, 10)}:${tmFc.substring(10, 12)}';
            String title = Get.find<WeatherGogoCntr>().weatherAlert.value!.title.toString();
            // 제목도  / 가 포함되어 있으면 / 를 기준으로 나누어서 2개로 나누어서 2번째 값만 사용한다.
            final List<String> titleList = title.split('/');
            if (titleList.length > 1) {
              title = titleList[1];
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 237, 219, 240).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.red, size: 18),
                  const Gap(5),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextScroll(
                      "$tmFc2 ${title.toString().replaceAll('(*)', '')}",
                      // '각 항목을 Card 위젯으로 감싸 구글 Discover와 유사한 디자인을 구현했습니다.',
                      mode: TextScrollMode.endless,
                      numberOfReps: 20000,
                      fadedBorder: false,
                      delayBefore: const Duration(milliseconds: 4000),
                      pauseBetween: const Duration(milliseconds: 2000),
                      velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                      style: const TextStyle(fontSize: 14, color: Colors.yellow, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.left,
                      selectable: false,
                    ),
                  ),
                ],
              ),
            );
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('날씨정보', style: semiboldText.copyWith(fontSize: 20.0)),
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
                    onPressed: () {
                      // Get.find<WeatherGogoCntr>().changeBgColor();
                      // Get.toNamed('/WeathgergogoPage');

                      // Get.find<WeatherGogoCntr>().fetchWeatherAlert(Get.find<WeatherGogoCntr>().currentLocation.value.latLng);
                      Get.toNamed('/WeatherComPage');
                    },
                    child: Row(
                      children: [
                        Text('날씨비교 ', style: semiboldText.copyWith(fontSize: 11.0)),
                        const Icon(Icons.arrow_forward_ios, size: 12.0, color: Colors.amber),
                      ],
                    ),
                  ),
                  const Gap(3),
                  Stack(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black87, // 텍스트 및 아이콘 색상
                          backgroundColor: Colors.white12, // 버튼 배경색
                          elevation: 4, // 그림자 높이
                          shadowColor: Colors.black.withOpacity(0.3), // 그림자 색상
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(67, 25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // 더 둥근 모서리
                          ),
                        ),
                        // onPressed: () => Get.toNamed('/MapPage'), // Get.find<WeatherGogoCntr>().test(), //
                        onPressed: () => Get.toNamed('/ShortViewPage', arguments: {
                          'address': Get.find<WeatherGogoCntr>().currentLocation.value.addr,
                          'lat': Get.find<WeatherGogoCntr>().currentLocation.value.latLng.latitude.toString(),
                          'lng': Get.find<WeatherGogoCntr>().currentLocation.value.latLng.longitude.toString(),
                        }),
                        child: const Row(
                          children: [
                            Text('동네라운지 ', style: TextStyle(fontSize: 13.0, color: Colors.yellow)),
                            Icon(Icons.arrow_forward_ios, size: 13.0, color: Colors.amber),
                            // ShimmeringText(
                            //   text: '동네라운지 ',
                            //   fontSize: 13.0,
                            //   baseColor: Colors.yellow,
                            //   highlightColor: Colors.purple,
                            // ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -10,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => Get.toNamed('/ShortViewPage', arguments: {
                            'address': Get.find<WeatherGogoCntr>().currentLocation.value.addr,
                            'lat': Get.find<WeatherGogoCntr>().currentLocation.value.latLng.latitude.toString(),
                            'lng': Get.find<WeatherGogoCntr>().currentLocation.value.latLng.longitude.toString(),
                          }),
                          child: Transform.rotate(
                            angle: pi / 16,
                            child: Lottie.asset(
                              'assets/lottie/new.json',
                              width: 45,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
              const Spacer(),
              AnimateIcons(
                startIcon: Icons.refresh,
                endIcon: Icons.refresh,
                controller: controller,
                startTooltip: 'Icons.refresh',
                endTooltip: 'Icons.refresh_rounded',
                size: 24.0,
                onStartIconPress: () {
                  Get.find<WeatherGogoCntr>().getRefreshWeatherData(true);
                  return true;
                },
                onEndIconPress: () {
                  Get.find<WeatherGogoCntr>().getRefreshWeatherData(true);
                  return true;
                },
                duration: const Duration(milliseconds: 250),
                startIconColor: Colors.amber,
                endIconColor: Colors.amber,
                clockwise: true,
              ),
            ],
          ),
        ],
      ),
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

  // Widget _buildWeatherWebView() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.end,
  //       children: [
  //         const Row(
  //           children: [
  //             PhosphorIcon(PhosphorIconsRegular.wind, color: Colors.white),
  //             SizedBox(width: 4.0),
  //             Text(
  //               '대기 흐름',
  //               style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
  //             ),
  //             Spacer(),
  //           ],
  //         ),
  //         const Gap(15),
  //         SizedBox(
  //           height: 600,
  //           child: CommonWebView2(
  //             isBackBtn: false,
  //             url: Get.find<WeatherGogoCntr>().webViewUrl.value,
  //           ),
  //         ),
  //         const Gap(10),
  //         TextButton(
  //           style: TextButton.styleFrom(
  //             backgroundColor: Colors.white12,
  //             padding: const EdgeInsets.symmetric(horizontal: 0),
  //             minimumSize: const Size(50, 22),
  //             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //           ),
  //           onPressed: () => Navigator.of(context).push(
  //             MaterialPageRoute(
  //                 fullscreenDialog: false,
  //                 builder: (context) => CommonWebView(
  //                       isBackBtn: true,
  //                       url: Get.find<WeatherGogoCntr>().webViewUrl.value,
  //                     )),
  //           ), // Get.toNamed('/WeatherWebView'),
  //           child: Text('전체화면으로 ', style: semiboldText.copyWith(fontSize: 11.0)),
  //         ),
  //         const Gap(40)
  //       ],
  //     ),
  //   );
  // }

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
          return InkWell(
            onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => Get.find<WeatherGogoCntr>().getLocalTag()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              alignment: Alignment.center,
              child: Row(
                children: [
                  const Text('관심지역', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
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
