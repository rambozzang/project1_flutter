import 'dart:async';

import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import 'package:preload_page_view/preload_page_view.dart';
import 'package:project1/app/list/Video_myScreen_page.dart';
import 'package:project1/app/list/cntr/video_myinfo_list_cntr.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class VideoMyinfoListPage extends StatefulWidget {
  const VideoMyinfoListPage({super.key});

  @override
  State<VideoMyinfoListPage> createState() => _VideoMyinfoListPageState();
}

class _VideoMyinfoListPageState extends State<VideoMyinfoListPage> {
  final PreloadPageController _controller = PreloadPageController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    permissionLocation();
    Get.put(VideoMyinfoListCntr());
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
                  Get.find<VideoMyinfoListCntr>().pageNum = 0;
                  Get.find<VideoMyinfoListCntr>().getData();
                },
              ),
              SliverFillRemaining(
                child: Stack(
                  children: [
                    Utils.commonStreamList<BoardWeatherListData>(
                        Get.find<VideoMyinfoListCntr>().videoListCntr, buildVideoBody, Get.find<VideoMyinfoListCntr>().getData),
                    // buildLocalName(),
                    // buildTemp(),
                    // buildRecodeBtn(),
                    // Join 버튼
                    //buildJoinButton(),
                    // 오른쪽 상단 close 버튼
                    buildCloseButton(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildCloseButton() {
    return Positioned(
      top: 40,
      right: 10,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () {
          Get.back();
        },
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
          Get.find<VideoMyinfoListCntr>().currentIndex.value = position;
          Get.find<VideoMyinfoListCntr>().getMoreData(position, data.length);
        },
        itemBuilder: (context, i) {
          if (Get.find<VideoMyinfoListCntr>().isLoadingMore.value && Get.find<VideoMyinfoListCntr>().currentIndex.value == data.length) {
            return Utils.progressbar();
          }
          return VideoMySreenPage(data: data[i]);
        });
  }
}
