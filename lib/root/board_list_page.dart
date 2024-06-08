import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/list/cntr/video_list_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

class BoardListPage extends StatefulWidget {
  const BoardListPage({super.key, required this.searchWord});
  final String searchWord;

  @override
  State<BoardListPage> createState() => _BoardListPageState();
}

class _BoardListPageState extends State<BoardListPage> with AutomaticKeepAliveClientMixin {
  // 리스트 상태 유지
  @override
  bool get wantKeepAlive => true;

  ScrollController scrollController = ScrollController();

  TextEditingController searchController = TextEditingController();

  // 팔로워 리스트 가져오기
  int boardPageNum = 0;
  int boardageSize = 5000;
  StreamController<ResStream<List<BoardWeatherListData>>> followVideoListCntr = BehaviorSubject();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (widget.searchWord.isNotEmpty && widget.searchWord != 'null') {
      searchController.text = widget.searchWord.toString();
      getSearchBoard(widget.searchWord.toString());
    } else {
      getFollowBoard();
    }
  }

  // 검색어로 조회
  Future<void> getSearchBoard(String searchWord) async {
    try {
      followVideoListCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();

      ResData res = await repo.getSearchBoard(Get.find<VideoListCntr>().position!.latitude.toString(),
          Get.find<VideoListCntr>().position!.latitude.toString(), boardPageNum, boardageSize, searchWord);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }

      print(res.data);
      List<BoardWeatherListData> list = ((res.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      followVideoListCntr.sink.add(ResStream.completed(list));
    } catch (e) {
      Utils.alert(e.toString());
      followVideoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  Future<void> getFollowBoard() async {
    try {
      followVideoListCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getMyBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), boardPageNum, boardageSize);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      print(res.data);
      List<BoardWeatherListData> list = ((res.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      followVideoListCntr.sink.add(ResStream.completed(list));
    } catch (e) {
      Utils.alert(e.toString());
      followVideoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  void addAlram() {
    // 알람 추가
    Utils.alert("알람 추가");
  }

  void addFollow() {
    // 팔로우 추가
    Utils.alert("팔로우 추가");
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(.94),
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        // backgroundColor: Colors.white,
        title: const Text(
          "사용자 리스트",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        // color: Colors.white.withOpacity(.94),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
        child: Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            child: Column(
              children: [
                buildSearchInputBox(),
                Container(child: Utils.commonStreamList<BoardWeatherListData>(followVideoListCntr, _followFeeds, getFollowBoard)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _followFeeds(List<BoardWeatherListData> list) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      //   child: GridView.builder(
      //     // crossAxisCount: 3,
      //     // mainAxisSpacing: 4,
      //     // crossAxisSpacing: 4,
      //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
      //     shrinkWrap: true,
      //     itemCount: list.length,
      //     itemBuilder: (context, index) => GestureDetector(
      //       onTap: () {
      //         Get.toNamed('/VideoMyinfoListPage', arguments: list[index]);
      //       },
      //       child: Container(
      //         color: Colors.red,
      //         height: 100, //(index % 5 + 1) * 60,
      //         child: CachedNetworkImage(
      //           imageUrl: list[index].thumbnailPath!,
      //           fit: BoxFit.cover,
      //         ),
      //       ),
      //     ),
      //   ),
      child: MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
        itemCount: list.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            Get.toNamed('/VideoMyinfoListPage', arguments: list[index]);
          },
          child: Container(
            color: Colors.grey.shade300,
            height: (index % 5 + 1) * 60,
            child: CachedNetworkImage(
              imageUrl: list[index].thumbnailPath!,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // 검색창
  Widget buildSearchInputBox() {
    return Container(
        height: 62,
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          style: const TextStyle(decorationThickness: 0), // 한글밑줄제거
          decoration: InputDecoration(
            hintText: '궁금한 것을 빠르게 검색해보세요.',
            // hintStyle: KosStyle.bodyB1,
            //  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(width: 1),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.grey),
              onPressed: () {
                getSearchBoard(searchController.text);
              },
            ),
          ),
        ));
  }
}
