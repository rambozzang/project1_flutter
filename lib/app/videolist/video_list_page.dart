import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import 'package:preload_page_view/preload_page_view.dart' hide PageScrollPhysics;
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/app/videolist/Video_screen_page.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/WeatherLottie.dart';
import 'package:project1/utils/utils.dart';
import 'package:text_scroll/text_scroll.dart';

/// 틱톡식 빠른 스와이프 물리.
/// 아주 작은 플링(살짝만 휙)에도 드래그 방향으로 "무조건 한 페이지" 넘어가고,
/// 단단한 스프링으로 즉시 스냅된다.
class FastPageScrollPhysics extends ScrollPhysics {
  const FastPageScrollPhysics({super.parent});

  @override
  FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  // 이 속도(px/s)만 넘으면 한 페이지 넘어간다. 낮을수록 더 민감(살짝 튕겨도 전환).
  static const double _flingThreshold = 3.0;

  // 느린 드래그에서 페이지를 넘기는 데 필요한 이동 비율(뷰포트 대비).
  // 0.5(50%, round)가 기본이지만, 0.25(25%)로 낮춰 화면 1/4만 끌어도 전환 → 더 민감.
  static const double _commitFraction = 0.25;

  double _page(ScrollMetrics p) => p.pixels / p.viewportDimension;
  double _pixels(ScrollMetrics p, double page) => page * p.viewportDimension;

  double _target(ScrollMetrics p, double velocity) {
    final double page = _page(p);
    final double base = page.floorToDouble();
    final double frac = page - base; // 0~1, 다음 페이지를 향한 진행도

    double targetPage;
    if (velocity > _flingThreshold) {
      // 빠른 위로 플릭 → 다음 페이지(이동량이 적어도 무조건 전환)
      targetPage = base + 1;
    } else if (velocity < -_flingThreshold) {
      // 빠른 아래로 플릭 → 이전 페이지
      targetPage = base;
    } else if (velocity >= 0) {
      // 느린 위로(다음) 드래그: 25%만 넘으면 전환
      targetPage = frac >= _commitFraction ? base + 1 : base;
    } else {
      // 느린 아래로(이전) 드래그: 25%만 넘으면 전환(frac <= 75%)
      targetPage = frac <= (1 - _commitFraction) ? base : base + 1;
    }

    final double maxPage = p.maxScrollExtent / p.viewportDimension;
    return _pixels(p, targetPage.clamp(0.0, maxPage));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // 끝단에서는 부모(오버스크롤) 처리에 위임
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tol = toleranceFor(position);
    final double target = _target(position, velocity);
    if ((target - position.pixels).abs() < tol.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tol);
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.3, // 가볍게 → 즉각 반응
        stiffness: 280, // 매우 단단하게 → 확 스냅
        ratio: 1.1, // 과감쇠 → 출렁임 없음
      );

  @override
  double get minFlingVelocity => 1.5;

  @override
  double get minFlingDistance => 0.0;

  @override
  bool get allowImplicitScrolling => false;
}

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> with AutomaticKeepAliveClientMixin<VideoListPage> {
  @override
  bool get wantKeepAlive => true;

  final PreloadPageController _controller = PreloadPageController();
  final ScrollController scrollController = ScrollController();

  GlobalKey<ScaffoldState> scaffoldkey = GlobalKey<ScaffoldState>();
  AdManager adManager = AdManager();
  // static const String AD_UNIT_NAME = 'VideoPage';

  final ValueNotifier<bool> _showInterstitial = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // permissionLocation();
    // Get.put(VideoListCntr());

    // AdManager().loadInterstitialAd();
    Future.delayed(const Duration(seconds: 2), () {
      _showInterstitial.value = true;
    });
  }

  void getData() {
    Get.find<VideoListCntr>().getDataWithPagination(isInitialLoad: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    scrollController.dispose();
    // AdManager().disposeBannerAd('VideoPage');
    super.dispose();
  }

  // 전체 화면을 차지하는 배경 (달 애니메이션 제거 → 검은색)
  Widget buildLoading() {
    return Container(color: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: scaffoldkey,
      extendBodyBehindAppBar: false, //  본문(body) 콘텐츠를 AppBar 뒤로 확장
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // 루트 피드 배경: 달 애니메이션 제거 → 검은색
          Positioned.fill(
            child: Container(color: Colors.black),
          ),
          Positioned.fill(
            child: Utils.commonStreamList<BoardWeatherListData>(
              Get.find<VideoListCntr>().videoListCntr,
              (data) => buildVideoBody(data, context),
              getData,
              loadingWidget: buildLoading(),
              noDataWidget: buildNoData(),
            ),
          ),
          buildLocalName(),
          buildButton(),
          // 검색하기
          buildSeachBtn(),
        ],
      ),
      //   ),
    );
  }

  Widget buildNoData() {
    return Center(
      child: Obx(() {
        String desc = '';

        if (Get.find<VideoListCntr>().isLoading.value == false) {
          switch (Get.find<VideoListCntr>().searchType.value) {
            case 'TOTAL':
              desc = '전체 조회된 데이터가 없습니다.';
              break;
            case 'DIST':
              desc = '현위치 조회된 데이터가 없습니다.';
              break;
            case 'TAG':
              desc = '관심태그 조회된 데이터가 없습니다.';
              break;
            case 'LOCAL':
              desc = '관심지역 조회된 데이터가 없습니다.';
              break;
            case 'FOLLOW':
              desc = '팔로우 조회된 데이터가 없습니다.';
              break;
          }
        } else {
          desc = '데이터를 가져오는 중입니다.';
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 55, height: 55, child: WeatherLottie.failure()),
            const Gap(10),
            Text(desc, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const Gap(20),
            if (Get.find<VideoListCntr>().searchType.value.contains('TAG')) ...[
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  minimumSize: const Size(80, 38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '태그 등록하기',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  RootCntr.to.changeRootPageIndex(4);
                  Utils.alert('관심태그 + 버튼을 클릭하여 등록해주세요.');
                },
              ),
              const Gap(30),
            ],
            if (Get.find<VideoListCntr>().searchType.value.contains('LOCAL')) ...[
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  minimumSize: const Size(80, 38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '관심지역 등록하기',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await Get.toNamed('/FavoriteAreaPage')!.then((value) {
                    Get.find<WeatherGogoCntr>().getLocalTag();
                    Get.find<VideoListCntr>().swichSearchType('LOCAL');
                  });
                },
              ),
              const Gap(30),
            ],
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white30,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size(80, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '전체 조회하기',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Get.find<VideoListCntr>().swichSearchType('TOTAL');
              },
            ),
          ],
        );
      }),
    );
  }

  // 동영상 리스트
  Widget buildVideoBody(List<BoardWeatherListData> data, BuildContext context) {
    return GetBuilder<VideoListCntr>(
      builder: (cntr) {
        return PreloadPageView.builder(
          key: const PageStorageKey("tigerBkPageView"),
          controller: _controller,
          preloadPagesCount: cntr.preLoadingCount,
          scrollDirection: Axis.vertical,
          itemCount: data.length,
          physics: const FastPageScrollPhysics(),
          onPageChanged: (int inx) {
            // 현재 페이지 인덱스 갱신: 좋아요/팔로우가 현재 영상을 정확히 가리키도록
            cntr.currentIndex.value = inx;
            if (inx >= cntr.list.length - (cntr.preLoadingCount + 1)) {
              cntr.getDataWithPagination();
            }
            RootCntr.to.bottomBarStreamController.sink.add(true);
          },
          itemBuilder: (context, videoIndex) {
            PageStorageKey key = PageStorageKey('key_$videoIndex');
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: VideoScreenPage(key: key, index: videoIndex, data: data[videoIndex]),
            );
          },
        );
      },
    );
  }

  Widget buildButtonDetail(String title, String type) {
    return Stack(
      children: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Get.find<VideoListCntr>().searchType.value == type
                ? const Color.fromARGB(255, 15, 67, 136).withOpacity(0.3)
                : const Color.fromARGB(255, 31, 91, 170).withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(40, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            Get.find<VideoListCntr>().swichSearchType(type);
          },
        ),
        Get.find<VideoListCntr>().searchType.value == type
            ? Positioned(
                top: -2,
                right: 0,
                child: Icon(Icons.check_circle, color: Colors.purple.withOpacity(0.6), size: 15),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  // 상단 버튼
  Widget buildButton() {
    return ValueListenableBuilder(
        valueListenable: _showInterstitial,
        builder: (context, value, child) {
          // animation 자동으로 나타나기
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.fastOutSlowIn,
            top: MediaQuery.of(context).padding.top + (Platform.isAndroid ? 10 : 0),
            left: value ? 6 : -400,
            child: Obx(() => Row(
                  children: [
                    buildButtonDetail('전체', 'TOTAL'),
                    const Gap(5),
                    buildButtonDetail('현위치', 'DIST'),
                    const Gap(5),
                    buildButtonDetail('관심태그', 'TAG'),
                    const Gap(5),
                    buildButtonDetail('관심지역', 'LOCAL'),
                    const Gap(5),
                    buildButtonDetail('Follow', 'FOLLOW'),
                  ],
                )),
          );
        });
  }

  // 상단 동네 이름
  Widget buildLocalName() {
    final controller = Get.find<WeatherGogoCntr>();
    return Positioned(
        top: MediaQuery.of(context).padding.top + (Platform.isAndroid ? 40 : 30),
        left: 6,
        child: Obx(
          () {
            if (controller.isLoading.value == true) {
              return const SizedBox.shrink();
            }
            String weathDesc = WeatherDataProcessor.instance
                .combineWeatherCondition(controller.currentWeather.value.sky.toString(), controller.currentWeather.value.rain.toString());
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 155,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      // Container(
                      //     width: 22,
                      //     padding: const EdgeInsets.all(3),
                      //     decoration: BoxDecoration(
                      //       color: Colors.green.withOpacity(0.9),
                      //       borderRadius: BorderRadius.circular(5),
                      //     ),
                      //     child: const Icon(Icons.location_on, color: Colors.white, size: 15)),
                      // const Gap(6),
                      SizedBox(
                        width: 130,
                        child: TextScroll(
                          '현재날씨 ${controller.currentWeather.value.temp ?? 0}° ${(weathDesc.isEmpty || weathDesc == 'null') ? '' : weathDesc}    ',
                          // '${controller.currentLocation.value!.name} ${controller.currentWeather.value.temp ?? 0}° ${(weathDesc.isEmpty || weathDesc == 'null' || weathDesc == null) ? '' : weathDesc}',
                          mode: TextScrollMode.endless,
                          numberOfReps: 20000,
                          // fadedBorder: true,
                          delayBefore: const Duration(milliseconds: 4000),
                          pauseBetween: const Duration(milliseconds: 2000),
                          velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.left,
                          selectable: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(5),
                TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 112, 170, 31).withOpacity(0.4),
                      padding: const EdgeInsets.only(
                        left: 7,
                      ),
                      minimumSize: const Size(90, 28),
                      // maximumSize: const Size(80, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${controller.currentLocation.value.name} 실시간 동네라운지',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const Gap(3),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 11,
                        ),
                      ],
                    ),
                    onPressed: () => Get.toNamed('/ShortViewPage', arguments: {
                          'address': controller.currentLocation.value.addr,
                          'lat': controller.currentLocation.value.latLng.latitude.toString(),
                          'lng': controller.currentLocation.value.latLng.longitude.toString(),
                        })),
              ],
            );
          },
        ));
  }

  // 상단 검색 하기
  Widget buildSeachBtn() {
    return ValueListenableBuilder(
        valueListenable: _showInterstitial,
        builder: (context, value, child) {
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.fastOutSlowIn,
            top: MediaQuery.of(context).padding.top + (Platform.isAndroid ? 10 : 0),
            right: value ? 0 : -300,
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 25,
                  ),
                  onPressed: () => Get.toNamed('/SearchPage'),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 110, 160, 245).withOpacity(0.4),
                      padding: const EdgeInsets.only(
                        top: 0,
                        bottom: 0,
                        left: 2,
                      ),
                      minimumSize: const Size(60, 24),
                      maximumSize: const Size(62, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          color: Color.fromARGB(255, 219, 164, 2),
                          size: 12,
                        ),
                        Gap(4),
                        Text(
                          '지도',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Gap(10),
                        // Icon(
                        //   Icons.arrow_forward_ios,
                        //   color: Colors.white,
                        //   size: 11,
                        // ),
                      ],
                    ),
                    onPressed: () => Get.toNamed('/MapPage'),
                  ),
                ),
                // IconButton(
                //   icon: const Icon(
                //     Icons.map,
                //     color: Colors.white,
                //     weight: 250,
                //     size: 25,
                //   ),
                //   onPressed: () => Get.toNamed('/MapPage'),
                // ),
              ],
            ),
          );
        });
  }

  // Refresh 하기
  Widget buildRefreshBtn() {
    return Obx(() => Positioned(
          top: MediaQuery.of(context).padding.top + 42,
          right: 0,
          child: Get.find<WeatherGogoCntr>().currentWeather.value.temp != '0.0'
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 25,
                      ),
                      onPressed: () async {
                        Get.find<VideoListCntr>().swichSearchType('TOTAL');
                      },
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ));
  }

  Widget buildScrollInfo() {
    return Positioned(
      top: 150.0,
      left: 0.0,
      bottom: 150.0,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const ClampingScrollPhysics(),
          child: Obx(() => Column(
                children: Get.find<VideoListCntr>().list.map((element) {
                  return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 2.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color:
                                  (Get.find<VideoListCntr>().list[Get.find<VideoListCntr>().currentIndex.value].boardId == element.boardId)
                                      ? Colors.yellow
                                      : Colors.transparent,
                              width: 1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(element.boardId.toString(),
                            style: TextStyle(
                              color: (Get.find<VideoListCntr>().mountedList.contains(element.boardId)) ? Colors.white : Colors.yellow,
                              fontSize: 12,
                            )),
                      ));
                }).toList(),
              )),
        ),
      ),
    );
  }
}
