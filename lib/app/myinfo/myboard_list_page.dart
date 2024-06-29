import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

class MyboardListPage extends StatefulWidget {
  const MyboardListPage({super.key});

  @override
  State<MyboardListPage> createState() => _MyboardListPageState();
}

class _MyboardListPageState extends State<MyboardListPage> {
  // 내게시물 리스트 가져오기
  int myboardPageNum = 0;
  int myboardageSize = 10;
  List<BoardWeatherListData> myboardlist = [];
  StreamController<ResStream<List<BoardWeatherListData>>> myVideoListCntr = BehaviorSubject();
  ScrollController myboardScrollCtrl = ScrollController();
  bool isMyBoardLastPage = false;
  final ValueNotifier<bool> isMyBoardMoreLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    getInitMyBoard();
    myboardScrollCtrl.addListener(() {
      if (myboardScrollCtrl.position.pixels == myboardScrollCtrl.position.maxScrollExtent) {
        if (!isMyBoardLastPage) {
          myboardPageNum++;
          isMyBoardMoreLoading.value = true;
          getMyBoard(myboardPageNum);
        }
      }
    });
  }

  Future<void> getInitMyBoard() async {
    myboardPageNum = 0;
    getMyBoard(myboardPageNum);
  }

  Future<void> getMyBoard(int page) async {
    try {
      if (page == 0) {
        myVideoListCntr.sink.add(ResStream.loading());
        myboardlist.clear();
      }
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getMyBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), myboardPageNum, myboardageSize);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        isMyBoardLastPage = true;
        return;
      }
      print(res.data);
      List<BoardWeatherListData> list = ((res.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      myboardlist.addAll(list);

      if (list.length < myboardageSize) {
        isMyBoardLastPage = true;
      }
      isMyBoardMoreLoading.value = false;

      myVideoListCntr.sink.add(ResStream.completed(myboardlist));
    } catch (e) {
      Utils.alert(e.toString());
      myVideoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  @override
  void dispose() {
    myVideoListCntr.close();

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
          getInitMyBoard();
        },
        child: Container(
          // color: Colors.white.withOpacity(.94),
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
          child: SingleChildScrollView(
            controller: myboardScrollCtrl,
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
                      child: Utils.commonStreamList<BoardWeatherListData>(myVideoListCntr, myFeeds, getInitMyBoard))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget myFeeds(List<BoardWeatherListData> list) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: list.length > 0
          ? GridView.builder(
              shrinkWrap: true,
              controller: myboardScrollCtrl,
              // physics: const NeverScrollableScrollPhysics(),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, //1 개의 행에 보여줄 item 개수
                childAspectRatio: 3 / 5, //item 의 가로 1, 세로 1 의 비율
                mainAxisSpacing: 6, //수평 Padding
                crossAxisSpacing: 3, //수직 Padding
              ),
              itemCount: list.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  Get.toNamed('/VideoMyinfoListPage', arguments: {
                    'datatype': 'MYFEED',
                    'custId': Get.find<AuthCntr>().resLoginData.value.custId.toString(),
                    'boardId': list[index].boardId.toString()
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.0),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(list[index].thumbnailPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Utils.progressbar(),
    );
  }
}
