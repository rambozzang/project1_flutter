import 'dart:async';
import 'dart:ffi';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import 'package:preload_page_view/preload_page_view.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/list/Video_screen_page.dart';
import 'package:project1/app/camera/page/camera_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/app/list/cntr/video_list_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:text_scroll/text_scroll.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final PreloadPageController _controller = PreloadPageController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    permissionLocation();
    Get.put(VideoListCntr());
  }

  Future<void> permissionLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Utils.alert('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    lo.g(permission.toString());

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return Utils.alert('Location permissions are denied');
      }
    }
  }

  // 동영상 녹화 페이지로 이동
  void goRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            return CameraBloc(
              cameraUtils: CameraUtils(),
              permissionUtils: PermissionUtils(),
              currentWeather: Get.find<VideoListCntr>().currentWeather.value,
            )..add(const CameraInitialize(recordingLimit: 15));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      body: Builder(
        builder: (context) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              LoadingCupertinoSliverRefreshControl(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                  Get.find<VideoListCntr>().pageNum = 0;
                  Get.find<VideoListCntr>().getData();
                },
              ),
              SliverFillRemaining(
                child: Stack(
                  children: [
                    Utils.commonStreamList<BoardWeatherListData>(
                        Get.find<VideoListCntr>().videoListCntr, buildVideoBody, Get.find<VideoListCntr>().getData),
                    buildLocalName(),
                    buildTemp(),
                    // buildRecodeBtn(),
                    // Join 버튼
                    buildJoinButton(),
                  ],
                ),
              ),
            ],
          );
        },
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
            Get.toNamed('/OnboardingPage');
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
    return PreloadPageView.builder(
        controller: _controller,
        preloadPagesCount: 3,
        scrollDirection: Axis.vertical,
        itemCount: data.length,
        physics: const AlwaysScrollableScrollPhysics(),
        onPageChanged: (int position) {
          print('page changed. current: $position');
          Get.find<VideoListCntr>().currentIndex.value = position;
          Get.find<VideoListCntr>().getMoreData(position, data.length);
        },
        itemBuilder: (context, i) {
          if (Get.find<VideoListCntr>().isLoadingMore.value && Get.find<VideoListCntr>().currentIndex.value == data.length) {
            return Utils.progressbar();
          }
          return VideoSreenPage(data: data[i]);
        });
  }

  // 상단 현재 온도
  Widget buildTemp() {
    return Obx(() => Positioned(
          top: 80,
          right: 10,
          left: 10,
          child: Get.find<VideoListCntr>().currentWeather.value!.coord != null
              ? Container(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            Get.find<VideoListCntr>().currentWeather.value!.weather![0].description!.toString(),
                            style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${Get.find<VideoListCntr>().currentWeather.value?.main!.temp?.toStringAsFixed(1) ?? 0}°',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              CachedNetworkImage(
                                width: 50,
                                height: 50,
                                // color: Colors.white,
                                imageUrl:
                                    'http://openweathermap.org/img/wn/${Get.find<VideoListCntr>().currentWeather.value?.weather![0].icon ?? '10n'}@2x.png',
                                //   imageUrl:  'http://openweathermap.org/img/w/${value.weather![0].icon}.png',
                                imageBuilder: (context, imageProvider) => Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                        colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.colorBurn)),
                                  ),
                                ),
                                placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ],
                          ),
                          Text(
                            '체감온도 ${Get.find<VideoListCntr>().currentWeather.value?.main!.feels_like?.toStringAsFixed(1) ?? 0}°',
                            style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '최저 ${Get.find<VideoListCntr>().currentWeather.value?.main!.temp_min?.toStringAsFixed(1) ?? 0}° · 최고 ${Get.find<VideoListCntr>().currentWeather.value?.main!.temp_max?.toStringAsFixed(1) ?? 0}°',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ));
  }

  // 상단 동네 이름
  Widget buildLocalName() {
    return Obx(() => Positioned(
          top: 45,
          left: 3,
          child: Container(
              //  width: 240,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 15)),
                  const SizedBox(width: 5),
                  SizedBox(
                    width: 200,
                    child: TextScroll(
                      Get.find<VideoListCntr>().localName.value,
                      mode: TextScrollMode.endless,
                      numberOfReps: 20000,
                      fadedBorder: true,
                      delayBefore: const Duration(milliseconds: 4000),
                      pauseBetween: const Duration(milliseconds: 2000),
                      velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                      style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                      selectable: true,
                    ),
                  ),
                ],
              )),
        ));
  }

  // 상단 촬영 하기
  Widget buildRecodeBtn() {
    return Obx(() => Positioned(
          top: 35,
          right: 10,
          child: Get.find<VideoListCntr>().currentWeather.value!.coord != null
              ? SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => goRecord(),
                  ))
              : const SizedBox.shrink(),
        ));
  }
}
