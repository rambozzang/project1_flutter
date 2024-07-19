import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';

import 'package:preload_page_view/preload_page_view.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/videolist/Video_screen_page.dart';
import 'package:project1/app/camera/page/camera_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_marquee.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:path_provider/path_provider.dart';

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

  GlobalKey<ScaffoldState> Scaffoldkey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // permissionLocation();
    // Get.put(VideoListCntr());
  }

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
    super.dispose();
  }

  // 전체 하면을 차지하면서 이미지를 보여주는 위젯
  Widget buildLoading() {
    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage(
              'assets/images/2.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 45.0),
          child: const Center(child: Text(" ", style: TextStyle(color: Colors.white, fontSize: 9))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: Scaffoldkey,
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
            // 상단 현재 온도
            // buildTemp(),
            // 미세먼지
            //buildMist(),
            // buildRecodeBtn(),
            // Join 버튼
            //  buildJoinButton(),
            // 검색하기
            buildSeachBtn(),
            // 캐쉬 삭제하기
            // buildEmptyCacheBtn(),
            //
            buildRefreshBtn(),
            // 스크롤 Mounted 정보
            //   buildScrollInfo(),
          ],
        ),
      ),
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
          // physics: const CustomPhysics(),
          onPageChanged: (int position) {
            cntr.currentIndex.value = position;
            cntr.getMoreData(position, data.length);
          },
          itemBuilder: (context, i) {
            return VideoScreenPage(index: i, data: data[i]);
          },
        );
      },
    );
  }

  // 상단 동네 이름
  Widget buildLocalName() {
    return Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 3,
        child: GetBuilder<WeatherCntr>(
          builder: (weatherCntr) {
            if (weatherCntr.isLoading.value == true) {
              return const SizedBox.shrink();
            }

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
                      '${weatherCntr.currentLocation.value!.name} ${weatherCntr.oneCallCurrentWeather.value!.temp?.toStringAsFixed(1) ?? 0}° ${weatherCntr.oneCallCurrentWeather.value!.weather![0].description!.toString()}',
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
                  // Expanded(
                  //   child: MarqueeList(
                  //     key: GlobalKey(),
                  //     children: [
                  //       const SizedBox(width: 5),
                  //       Text(
                  //         weatherCntr.currentLocation.value!.name,
                  //         textAlign: TextAlign.right,
                  //         style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                  //       ),
                  //       const Gap(5),
                  //       Text(
                  //         '${weatherCntr.oneCallCurrentWeather.value!.temp?.toStringAsFixed(1) ?? 0}°',
                  //         textAlign: TextAlign.right,
                  //         style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                  //       ),
                  //       CachedNetworkImage(
                  //         width: 25,
                  //         height: 25,
                  //         imageUrl:
                  //             'http://openweathermap.org/img/wn/${weatherCntr.oneCallCurrentWeather.value?.weather![0].icon ?? '10n'}@2x.png',
                  //         imageBuilder: (context, imageProvider) => Container(
                  //           decoration: BoxDecoration(
                  //             image: DecorationImage(
                  //               image: imageProvider,
                  //               fit: BoxFit.cover,
                  //               colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.colorBurn),
                  //             ),
                  //           ),
                  //         ),
                  //         placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
                  //         errorWidget: (context, url, error) => const Icon(Icons.error),
                  //       ),
                  //       Text(
                  //         weatherCntr.oneCallCurrentWeather.value!.weather![0].description!.toString(),
                  //         style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                  //       ),
                  //       const SizedBox(width: 25),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            );
          },
        ));
  }

  // 상단 검색 하기
  Widget buildSeachBtn() {
    return Obx(() => Positioned(
          top: MediaQuery.of(context).padding.top,
          right: 10,
          child: Get.find<WeatherCntr>().oneCallCurrentWeather.value!.dt != null
              ? SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Get.toNamed('/SearchPage'),
                  ))
              : const SizedBox.shrink(),
        ));
  }

  // Refresh 하기
  Widget buildRefreshBtn() {
    return Obx(() => Positioned(
          top: MediaQuery.of(context).padding.top + 48,
          right: 0,
          child: Get.find<WeatherCntr>().oneCallCurrentWeather.value!.dt != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: Get.find<VideoListCntr>().searchType.value == 'DIST' ? 33 : 30,
                      ),
                      onPressed: () async {
                        Get.find<VideoListCntr>().swichSearchType('TOTAL');
                      },
                    ),
                    TextButton(
                      child: Text(
                        '거리',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: Get.find<VideoListCntr>().searchType.value == 'DIST' ? 13 : 11,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Get.find<VideoListCntr>().swichSearchType('DIST');
                      },
                    ),
                    TextButton(
                      child: Text(
                        '관심태그',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: Get.find<VideoListCntr>().searchType.value == 'TAG' ? 13 : 11,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Get.find<VideoListCntr>().swichSearchType('TAG');
                      },
                    ),
                    TextButton(
                      child: Text(
                        '관심지역',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: Get.find<VideoListCntr>().searchType.value == 'LOCAL' ? 13 : 11,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Get.find<VideoListCntr>().swichSearchType('LOCAL');
                      },
                    ),
                    TextButton(
                      child: Text(
                        '캐쉬삭제',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        CacheManager.clearAppCache();
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
        mass: 150,
        stiffness: 100,
        damping: 1,
      );
}

class CacheManager {
  static Future<void> clearAppCache() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.listSync().forEach((FileSystemEntity file) {
          if (file is File) {
            file.deleteSync();
          } else if (file is Directory) {
            file.deleteSync(recursive: true);
          }
        });
      }

      Directory appDocDir = await getApplicationDocumentsDirectory();
      if (appDocDir.existsSync()) {
        appDocDir.listSync().forEach((FileSystemEntity file) {
          if (file is File) {
            file.deleteSync();
          } else if (file is Directory) {
            file.deleteSync(recursive: true);
          }
        });
      }

      Utils.alert("App cache cleared successfully.");
    } catch (e) {
      Utils.alert("Error clearing app cache: $e");
    }
  }
}
