import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:text_scroll/text_scroll.dart';

class LikeListPage extends StatefulWidget {
  const LikeListPage({super.key, required this.custId});
  final String custId;

  @override
  State<LikeListPage> createState() => _LikeListPageState();
}

class _LikeListPageState extends State<LikeListPage> with AutomaticKeepAliveClientMixin {
  // 리스트 상태 유지
  @override
  bool get wantKeepAlive => true;

  ScrollController scrollController = ScrollController();

  // 팔로워 리스트 가져오기
  int boardPageNum = 0;
  int boardageSize = 15;
  bool isLastPage = false;
  List<BoardWeatherListData> alllist = [];
  StreamController<ResStream<List<BoardWeatherListData>>> likeVideoListCntr = BehaviorSubject();

  @override
  void initState() {
    super.initState();
    getLikeBoard();

    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        if (!isLastPage) {
          boardPageNum++;
          isLastPage = true;
          getLikeBoard();
        }
      }
    });
  }

  Future<void> getLikeBoard() async {
    try {
      if (boardPageNum == 0) {
        likeVideoListCntr.sink.add(ResStream.loading());
        alllist.clear();
      }
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getLikeBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), boardPageNum, boardageSize);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      print(res.data);

      List<BoardWeatherListData> list = ((res.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      alllist.addAll(list);

      if (list.length <= boardageSize) {
        isLastPage = true;
      } else {
        isLastPage = false;
      }

      likeVideoListCntr.sink.add(ResStream.completed(alllist));
    } catch (e) {
      Utils.alert(e.toString());
      likeVideoListCntr.sink.add(ResStream.error(e.toString()));
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
    likeVideoListCntr.close();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
      body: RefreshIndicator(
        onRefresh: () async {
          getLikeBoard();
        },
        child: Container(
          // color: Colors.white.withOpacity(.94),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // buildSearchInputBox(),
                const Text('내가 좋아요를 누른 리스트'),
                Container(child: Utils.commonStreamList<BoardWeatherListData>(likeVideoListCntr, getLikeFeeds, getLikeBoard)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getLikeFeeds(List<BoardWeatherListData> list) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GridView.builder(
        // crossAxisCount: 3,
        // mainAxisSpacing: 4,
        // crossAxisSpacing: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, //1 개의 행에 보여줄 item 개수
          childAspectRatio: 0.5, //item 의 가로 1, 세로 1 의 비율
          mainAxisSpacing: 6, //수평 Padding
          crossAxisSpacing: 3, //수직 Padding
        ),
        shrinkWrap: true,
        itemCount: list.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            Get.toNamed('/VideoMyinfoListPage', arguments: {
              'datatype': 'LIKE',
              'custId': Get.find<AuthCntr>().resLoginData.value.custId.toString(),
              'boardId': list[index].boardId.toString(),
              'searchWord': ''
            });
          },
          child: Container(
            // height: 100, //(index % 5 + 1) * 60,
            margin: const EdgeInsets.all(2),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.grey.withOpacity(0.5),
              //     spreadRadius: 1,
              //     blurRadius: 1,
              //     offset: const Offset(0, 1), // changes position of shadow
              //   ),
              // ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 0.68,
                      child: CachedNetworkImage(
                        imageUrl: list[index].thumbnailPath!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      left: 5,
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white, size: 15),
                          Text(' ${list[index].likeCnt.toString()}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Text('조회수 ${list[index].viewCnt.toString()}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400)),
                    ),
                    list[index].hideYn == 'Y'
                        ? const Positioned(
                            top: 10,
                            left: 10,
                            child: Icon(Icons.lock, color: Colors.red, size: 20),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  // height: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          //  width: 240,
                          padding: const EdgeInsets.all(1),
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
                                width: 100,
                                child: TextScroll(
                                  list[index].location.toString(),
                                  mode: TextScrollMode.endless,
                                  numberOfReps: 20000,
                                  fadedBorder: true,
                                  delayBefore: const Duration(milliseconds: 4000),
                                  pauseBetween: const Duration(milliseconds: 2000),
                                  velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                                  style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.right,
                                  selectable: true,
                                ),
                              ),
                            ],
                          )),
                      Row(
                        children: [
                          SizedBox(
                            height: 20,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                // backgroundColor: Colors.red,
                              ),
                              onPressed: () => Get.toNamed('/OtherInfoPage/${list[index].custId.toString()}'),
                              child: Text(
                                '@${list[index].nickNm == null ? list[index].custNm.toString() : list[index].nickNm.toString()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          // 가운데 점 표시
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              '·',
                              style: TextStyle(color: Colors.black87, fontSize: 12),
                            ),
                          ),
                          Text(
                            '${Utils.timeage(list[index].crtDtm.toString())}전',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.black),
                          ),
                          // Text(
                          //   '@${data.senderNickNm == null ? data.senderCustNm.toString() : data.senderNickNm.toString()}',
                          //   softWrap: true,
                          //   overflow: TextOverflow.fade,
                          //   style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                          // ),
                        ],
                      ),
                      Text(
                        list[index].contents.toString() == 'null' ? '' : list[index].contents.toString(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // child: MasonryGridView.count(
      //   crossAxisCount: 3,
      //   mainAxisSpacing: 4,
      //   crossAxisSpacing: 4,
      //   shrinkWrap: true,
      //   scrollDirection: Axis.vertical,
      //   // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
      //   itemCount: list.length,
      //   itemBuilder: (context, index) => GestureDetector(
      //     onTap: () {
      //       Get.toNamed('/VideoMyinfoListPage', arguments: {
      //         'datatype': 'SEARCHLIST',
      //         'custId': Get.find<AuthCntr>().resLoginData.value.custId.toString(),
      //         'boardId': list[index].boardId.toString(),
      //         'searchWord': widget.searchWord.toString()
      //       });
      //     },
      //     child: Container(
      //       color: Colors.grey.shade300,
      //       height: (index % 5 + 1) * 60,
      //       child: CachedNetworkImage(
      //         imageUrl: list[index].thumbnailPath!,
      //         fit: BoxFit.cover,
      //       ),
      //     ),
      //   ),
      // ),
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
          // controller: controller,
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
                //    SearchData(controller.text);
              },
            ),
          ),
        ));
  }
}
