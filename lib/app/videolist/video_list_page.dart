import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import 'package:preload_page_view/preload_page_view.dart';
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

  // 전체 하면을 차지하면서 이미지를 보여주는 위젯
  Widget buildLoading() {
    return Hero(
      tag: 'bg1',
      child: SizedBox(
        width: double.infinity,
        child: WeatherLottie.background(),
      ),
    );
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
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: WeatherLottie.background(),
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
          physics: const CustomPhysics(),
          onPageChanged: (int inx) {
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
            top: MediaQuery.of(context).padding.top + 10,
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
        top: MediaQuery.of(context).padding.top + 40,
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
                          '현재날씨 ${controller.currentWeather.value.temp ?? 0}° ${(weathDesc.isEmpty || weathDesc == 'null' || weathDesc == null) ? '' : weathDesc}    ',
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
            top: MediaQuery.of(context).padding.top,
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
