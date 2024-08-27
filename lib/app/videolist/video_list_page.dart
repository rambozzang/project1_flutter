import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'package:preload_page_view/preload_page_view.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/videolist/Video_screen_page.dart';
import 'package:project1/app/camera/page/camera_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/utils.dart';
import 'package:text_scroll/text_scroll.dart';

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

  ValueNotifier<bool> _showInterstitial = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // permissionLocation();
    // Get.put(VideoListCntr());

    // AdManager().loadInterstitialAd();
    Future.delayed(const Duration(seconds: 5), () {
      _showInterstitial.value = true;
    });
  }

  // Future<void> initBannerAd() async {
  //   await adManager.loadBannerAd(AD_UNIT_NAME);
  //   await adManager.loadInterstitialAd();
  // }

  // 동영상 녹화 페이지로 이동
  void goRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            return CameraBloc(cameraUtils: CameraUtils(), permissionUtils: PermissionUtils())
              ..add(const CameraInitialize(recordingLimit: 15));
          },
          child: const CameraPage(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    scrollController.dispose();
    // AdManager().disposeBannerAd('VideoPage');
    super.dispose();
  }

  // 전체 하면을 차지하면서 이미지를 보여주는 위젯
  Widget buildLoading() {
    return Hero(
      tag: 'bg1',
      child: SizedBox(
        width: double.infinity,
        child: Lottie.asset(
          'assets/login/bg1.json',
          fit: BoxFit.cover,
        ),
      ),
    );
    // return SizedBox.expand(
    //   child: Container(
    //     decoration: const BoxDecoration(
    //       image: DecorationImage(
    //         image: AssetImage('assets/images/2.jpg'),
    //         // image: ExactAssetImage(
    //         //   'assets/images/2.jpg',
    //         // ),
    //         fit: BoxFit.cover,
    //       ),
    //     ),
    //     child: BackdropFilter(
    //       filter: ImageFilter.blur(sigmaX: 35.0, sigmaY: 45.0),
    //       child: const Center(child: Text(" ", style: TextStyle(color: Colors.white, fontSize: 9))),
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: scaffoldkey,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF262B49),
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: () async {
          Get.find<VideoListCntr>().pageNum = 0;
          Get.find<VideoListCntr>().getData();
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Utils.commonStreamList<BoardWeatherListData>(
                  Get.find<VideoListCntr>().videoListCntr, buildVideoBody, Get.find<VideoListCntr>().getData,
                  loadingWidget: buildLoading()),
            ),
            buildLocalName(),
            buildButton(),
            // 검색하기
            buildSeachBtn(),
          ],
        ),
      ),
    );
  }

  // 동영상 리스트
  Widget buildVideoBody(List<BoardWeatherListData> data) {
    return GetBuilder<VideoListCntr>(
      builder: (cntr) {
        return PreloadPageView.builder(
          key: const PageStorageKey("tigerBkPageView"),
          controller: _controller,
          preloadPagesCount: cntr.preLoadingCount, // 7 이 이상적임
          scrollDirection: Axis.vertical,
          itemCount: data.length,
          physics: const CustomPhysics(),
          onPageChanged: (int inx) {
            cntr.getMoreData(inx, data.length);
          },
          itemBuilder: (context, videoIndex) {
            PageStorageKey key = PageStorageKey('key_$videoIndex');
            return VideoScreenPage(key: key, index: videoIndex, data: data[videoIndex]);
          },
        );
      },
    );
  }

  // Join 버튼
  Widget buildJoinButton() {
    return Positioned(
      right: 10,
      top: 40,
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 65, height: 40),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.15),
            padding: const EdgeInsets.all(1.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 1.0,
          ),
          onPressed: () {
            Get.toNamed('/JoinPage');
          },
          child: const Text(
            'Join',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
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
            top: MediaQuery.of(context).padding.top + 10,
            left: value ? 6 : -400,
            child: Obx(() => Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Get.find<VideoListCntr>().searchType.value == 'TOTAL' ? Colors.white54 : Colors.white30,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(50, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '전체',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Get.find<VideoListCntr>().swichSearchType('TOTAL');
                      },
                    ),
                    const Gap(5),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Get.find<VideoListCntr>().searchType.value == 'DIST' ? Colors.white54 : Colors.white30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(50, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '현위치기준',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Get.find<VideoListCntr>().swichSearchType('DIST');
                      },
                    ),
                    const Gap(5),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Get.find<VideoListCntr>().searchType.value == 'TAG' ? Colors.white54 : Colors.white30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(50, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '관심태그',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Get.find<VideoListCntr>().swichSearchType('TAG');
                      },
                    ),
                    const Gap(5),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Get.find<VideoListCntr>().searchType.value == 'LOCAL' ? Colors.white54 : Colors.white30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(50, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '관심지역',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Get.find<VideoListCntr>().swichSearchType('LOCAL');
                      },
                    ),
                  ],
                )),
          );
        });
  }

  // 상단 동네 이름
  Widget buildLocalName() {
    final controller = Get.find<WeatherGogoCntr>();
    return Positioned(
        top: MediaQuery.of(context).padding.top + 47,
        left: 6,
        child: Obx(
          () {
            if (controller.isLoading.value == true) {
              return const SizedBox.shrink();
            }
            String weathDesc = WeatherDataProcessor.instance
                .combineWeatherCondition(controller.currentWeather.value.sky.toString(), controller.currentWeather.value.rain.toString());
            return Container(
              width: 250,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Container(
                      width: 22,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 15)),
                  const Gap(6),
                  SizedBox(
                    width: 210,
                    child: TextScroll(
                      '${controller.currentLocation.value!.name} ${controller.currentWeather.value.temp ?? 0}° ${(weathDesc.isEmpty || weathDesc == 'null' || weathDesc == null) ? '' : weathDesc}',
                      mode: TextScrollMode.endless,
                      numberOfReps: 20000,
                      // fadedBorder: true,
                      delayBefore: const Duration(milliseconds: 4000),
                      pauseBetween: const Duration(milliseconds: 2000),
                      velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                      selectable: true,
                    ),
                  ),
                ],
              ),
            );
          },
        )
        // child: GetBuilder<WeatherGogoCntr>(
        //   builder: (weatherCntr) {
        //     if (weatherCntr.isLoading.value == true) {
        //       return const SizedBox.shrink();
        //     }
        //     String weathDesc = WeatherDataProcessor.instance
        //         .combineWeatherCondition(weatherCntr.currentWeather.sky.toString(), weatherCntr.currentWeather.rain.toString());

        //     return Container(
        //       width: 250,
        //       padding: const EdgeInsets.all(2),
        //       decoration: BoxDecoration(
        //         color: Colors.grey.withOpacity(0.2),
        //         borderRadius: BorderRadius.circular(5),
        //       ),
        //       child: Row(
        //         children: [
        //           Container(
        //               width: 22,
        //               padding: const EdgeInsets.all(3),
        //               decoration: BoxDecoration(
        //                 color: Colors.green.withOpacity(0.9),
        //                 borderRadius: BorderRadius.circular(5),
        //               ),
        //               child: const Icon(Icons.location_on, color: Colors.white, size: 15)),
        //           const Gap(6),
        //           SizedBox(
        //             width: 210,
        //             child: TextScroll(
        //               '${weatherCntr.currentLocation.value!.name} ${weatherCntr.currentWeather.temp ?? 0}° ${(weathDesc.isEmpty || weathDesc == 'null' || weathDesc == null) ? '' : weathDesc}',
        //               mode: TextScrollMode.endless,
        //               numberOfReps: 20000,
        //               // fadedBorder: true,
        //               delayBefore: const Duration(milliseconds: 4000),
        //               pauseBetween: const Duration(milliseconds: 2000),
        //               velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
        //               style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
        //               textAlign: TextAlign.right,
        //               selectable: true,
        //             ),
        //           ),
        //         ],
        //       ),
        //     );
        //   },
        // ),
        );
  }

  // 상단 검색 하기
  Widget buildSeachBtn() {
    return Positioned(
        top: MediaQuery.of(context).padding.top,
        right: 1,
        child: IconButton(
          icon: const Icon(
            Icons.search,
            color: Colors.white,
            size: 25,
          ),
          onPressed: () => Get.toNamed('/SearchPage'),
        ));
  }

  // Refresh 하기
  Widget buildRefreshBtn() {
    return Obx(() => Positioned(
          top: MediaQuery.of(context).padding.top + 42,
          right: 0,
          child: Get.find<WeatherGogoCntr>().currentWeather.value.temp != null
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

// 화면 넘어 가는 스크롤 속도 조절
class CustomPhysics extends ScrollPhysics {
  const CustomPhysics({super.parent});
  // const CustomPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  CustomPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 20,
        stiffness: 13,
        damping: 3,
      );
}
