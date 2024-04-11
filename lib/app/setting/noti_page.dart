import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_data.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/paging_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_badge.dart';

class NotiPage extends StatefulWidget {
  const NotiPage({super.key});

  @override
  State<NotiPage> createState() => _NotiPageState();
}

class _NotiPageState extends State<NotiPage> with AutomaticKeepAliveClientMixin {
  final formKey = GlobalKey<FormState>();

  @override
  bool get wantKeepAlive => true;

  // 스크롤 컨트롤러
  ScrollController scrollCtrl = ScrollController();

  // 데이터 스크림
  final StreamController<ResStream<List<BoardDetailData>>> listCtrl = StreamController();

  List<BoardDetailData> boardList = [];

  String ptupDsc = 'NOTI';
  String ptupTrgtDsc = 'NOTI';

  String topYn = 'N';

  // bool isLastPage = false;
  int page = 0;
  int pageSzie = 10;
  final ValueNotifier<bool> isLastPage = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isMoreLoading = ValueNotifier<bool>(false);

  @override
  initState() {
    super.initState();
    getData(0);

    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels == scrollCtrl.position.maxScrollExtent) {
        if (!isLastPage.value) {
          page++;
          getData(page);
        }
      }
    });
  }

  // Future<void> getMoreData(int _page) async {
  //   isMoreLoading.value = true;
  //   BoardRepo repo = BoardRepo();
  //   ResData resData = await repo.searchOriginList('NOTI', 'NOTI', _page, pageSzie);

  //   if (resData.code != '00') {
  //     isMoreLoading.value = false;
  //     return;
  //   }
  //   List<BoardDetailData> _list = ((resData.data['list']) as List).map((data) => BoardDetailData.fromMap(data)).toList();

  //   PagingData pageData = PagingData.fromMap(resData.data['pageData']);
  //   page = pageData.currPageNum!;
  //   isLastPage.value = pageData.last!;

  //   boardList.addAll(_list);
  //   isMoreLoading.value = false;
  //   listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
  // }

  Future<void> getDataInit() async => getData(0);

  Future<void> getData(int _page) async {
    if (_page != 0) {
      isMoreLoading.value = true;
    } else {
      listCtrl.sink.add(ResStream.loading());
    }
    try {
      BoardRepo repo = BoardRepo();
      ResData resData = await repo.searchOriginList('NOTI', 'NOTI', _page, pageSzie);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        listCtrl.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }
      List<BoardDetailData> _list = ((resData.data['list']) as List).map((data) => BoardDetailData.fromMap(data)).toList();

      if (_page == 0) {
        boardList.clear();
      }
      PagingData pageData = PagingData.fromMap(resData.data['pageData']);
      page = pageData.currPageNum!;
      isLastPage.value = pageData.last!;
      boardList.addAll(_list);
      isMoreLoading.value = false;

      listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
    } catch (e) {
      listCtrl.sink.add(ResStream.error(e.toString()));
      isMoreLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('공지사항'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async => await getData(0),
        child: SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(children: [
            const Gap(24),
            // 공통 스트림 빌더
            Utils.commonStreamList<BoardDetailData>(listCtrl, buildList, getDataInit),
            ValueListenableBuilder<bool>(
                valueListenable: isMoreLoading,
                builder: (context, val, snapshot) {
                  if (val) {
                    return SizedBox(height: 60, child: Utils.progressbar());
                  } else {
                    return SizedBox(
                      height: 60,
                    );
                  }
                }),
            const Gap(30),
          ]),
        ),
      ),
    );
  }

  // 공지사항 리스트
  Widget buildList(List<BoardDetailData> list) {
    return SizedBox(
      width: double.infinity,
      //   height: 322,
      //padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return buildItem(list[index]);
            },
          ),

          // if (!isLastPage.value) ...[
          //   const Gap(10),
          //   Text('가져오는 중....'),
          // ]
        ],
      ),
    );
  }

// 공지사항 아이템
  Widget buildItem(BoardDetailData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      child: Column(
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),
          const Gap(10),
          ElevatedButton(
            clipBehavior: Clip.none,
            style: ElevatedButton.styleFrom(
              shadowColor: Colors.transparent,
              // fixedSize: Size(0, 0),
              minimumSize: Size.zero, // Set this
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              backgroundColor: Colors.transparent,
            ),
            onPressed: () => Get.toNamed('/NotiViewPage', arguments: {'boardId': data.boardId.toString()}),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              //   crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.isTop == 'Y') ...[
                          CustomBadge(
                            text: 'Top',
                            bgColor: Colors.red[700],
                          ),
                          const Gap(5),
                        ],
                        if (data.isNew == 'Y') ...[
                          CustomBadge(
                            text: 'New',
                            bgColor: Colors.blue,
                          ),
                          const Gap(5),
                        ],
                        Text(
                          data.subject.toString(),
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        const Gap(6),
                        // const Align(alignment: Alignment.centerRight, child: Icon(Icons.new_label_sharp, size: 14, color: Colors.red)),
                      ],
                    ),
                    const Gap(10),
                    Text(
                      '${data.regDate.toString().substring(0, 4)}.${data.regDate.toString().substring(4, 6)}.${data.regDate.toString().substring(6, 8)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 19, color: Colors.grey[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
