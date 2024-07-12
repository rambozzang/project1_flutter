import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

class MyFollowingListPage extends StatefulWidget {
  const MyFollowingListPage({super.key});

  @override
  State<MyFollowingListPage> createState() => _MyFollowingListPageState();
}

class _MyFollowingListPageState extends State<MyFollowingListPage> {
  // 팔로워 리스트 가져오기
  int followboardPageNum = 0;
  int followboardageSize = 10;
  List<BoardWeatherListData> followboardlist = [];
  StreamController<ResStream<List<BoardWeatherListData>>> followVideoListCntr = BehaviorSubject();
  ScrollController followboardScrollCtrl = ScrollController();
  bool isFollowLastPage = false;
  final ValueNotifier<bool> isFollowMoreLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    getInitFollowBoard();
    followboardScrollCtrl.addListener(() {
      if (followboardScrollCtrl.position.pixels == followboardScrollCtrl.position.maxScrollExtent) {
        if (!isFollowLastPage) {
          followboardPageNum++;
          isFollowMoreLoading.value = true;
          getFollowBoard(followboardPageNum);
        }
      }
    });
  }

  Future<void> getInitFollowBoard() async {
    followboardPageNum = 0;
    getFollowBoard(followboardPageNum);
  }

  Future<void> getFollowBoard(int page) async {
    try {
      if (page == 0) {
        followVideoListCntr.sink.add(ResStream.loading());
        followboardlist.clear();
      }
      BoardRepo repo = BoardRepo();
      ResData res =
          await repo.getFollowBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), followboardPageNum, followboardageSize);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      print(res.data);
      List<BoardWeatherListData> list = ((res.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      followboardlist.addAll(list);

      if (list.length < followboardageSize) {
        isFollowLastPage = true;
      }
      isFollowMoreLoading.value = false;

      followVideoListCntr.sink.add(ResStream.completed(followboardlist));
    } catch (e) {
      Utils.alert(e.toString());
      followVideoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  @override
  void dispose() {
    followVideoListCntr.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(.94),
      // appBar: AppBar(
      //   forceMaterialTransparency: true,
      //   automaticallyImplyLeading: false,
      //   // backgroundColor: Colors.white,
      //   title: const Text(
      //     "사용자 리스트",
      //     style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      //   ),
      //   centerTitle: true,
      //   // backgroundColor: Colors.transparent,
      //   elevation: 0,
      // ),
      body: RefreshIndicator(
        onRefresh: () async {
          getInitFollowBoard();
        },
        child: Container(
          // color: Colors.white.withOpacity(.94),
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
          child: SingleChildScrollView(
            controller: followboardScrollCtrl,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            child: Expanded(
              child: Column(
                children: [
                  Container(
                      //    height: 200,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Utils.commonStreamList<BoardWeatherListData>(followVideoListCntr, followFeeds, getInitFollowBoard))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget followFeeds(List<BoardWeatherListData> list) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          controller: followboardScrollCtrl,
          // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
          itemCount: list.length,
          itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                Get.toNamed('/VideoMyinfoListPage', arguments: {
                  'datatype': 'FOLLOW',
                  'custId': Get.find<AuthCntr>().resLoginData.value.custId.toString(),
                  'boardId': list[index].boardId.toString()
                });
              },
              child: Container(
                height: (index % 5 + 1) * 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      list[index].thumbnailPath!,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const Gap(5),
                                Text(
                                  list[index].likeCnt.toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.play_arrow_outlined,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const Gap(5),
                                Text(
                                  list[index].likeCnt.toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Text(
                        list[index].nickNm.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ))),
    );
  }
}
