import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:preload_page_view/preload_page_view.dart';
import 'package:project1/app/videomylist/Video_myScreen_page.dart';
import 'package:project1/app/videomylist/cntr/video_myinfo_list_cntr.dart';
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

  GlobalKey<ScaffoldState> Scaffoldkey = GlobalKey<ScaffoldState>();

  late final String datatype;
  late final String custId;
  late final String boardId;
  late final String searchWord;

  @override
  void initState() {
    super.initState();

    datatype = Get.arguments['datatype'];
    custId = Get.arguments['custId'];
    boardId = Get.arguments['boardId'];
    searchWord = Get.arguments['searchWord'] ?? "";

    if (datatype == 'ONE' && (boardId == '' || boardId == 'null' || boardId == null)) {
      Get.back();
    }
    Get.put(VideoMyinfoListCntr(datatype, custId, boardId, searchWord));
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
        key: Scaffoldkey,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFF262B49),
        extendBody: true,
        body: RefreshIndicator(
          onRefresh: () async {
            Get.find<VideoMyinfoListCntr>().pageNum = 0;
            Get.find<VideoMyinfoListCntr>().getData();
          },
          child: Stack(
            children: [
              Utils.commonStreamList<BoardWeatherListData>(
                Get.find<VideoMyinfoListCntr>().videoMyListCntr,
                buildVideoBody,
                Get.find<VideoMyinfoListCntr>().getData,
              ),
              // buildLocalName(),
              // buildTemp(),
              // buildRecodeBtn(),
              // Join 버튼
              //buildJoinButton(),
              // 오른쪽 상단 close 버튼
              buildCloseButton(),
            ],
          ),
        ));
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

  Widget buildCloseButton() {
    return Positioned(
      top: 40,
      right: 10,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        iconSize: 30,
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
        preloadPagesCount: Get.find<VideoMyinfoListCntr>().preLoadingCount,
        scrollDirection: Axis.vertical,
        itemCount: data.length,
        physics: const AlwaysScrollableScrollPhysics(),
        onPageChanged: (int position) {
          lo.g('page changed. current: $position');

          Get.find<VideoMyinfoListCntr>().currentIndex.value = position;
          Get.find<VideoMyinfoListCntr>().getMoreData(position, data.length);
        },
        itemBuilder: (context, i) {
          // if (Get.find<VideoMyinfoListCntr>().isLoadingMore.value && Get.find<VideoMyinfoListCntr>().currentIndex.value == data.length) {
          //   return Utils.progressbar();
          // }
          lo.g(' data.length : ${data.length} : i : $i');

          return VideoMySreenPage(data: data[i], index: i);
        });
  }
}
