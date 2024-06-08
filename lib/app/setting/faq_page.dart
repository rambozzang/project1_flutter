import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/paging_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_sec_button.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final formKey = GlobalKey<FormState>();

  TextEditingController controller = TextEditingController();

  // 스크롤 컨트롤러
  ScrollController scrollCtrl = ScrollController();

  //List<String> badgeList = ['TOP10', '사건수임', '견적서', '사전정보', '보험가입', '지급정보', '대출금', '상환말소', '접수번호', '서류등록', '회원정보', '기타'];
  List<Map<String, dynamic>> badgeList2 = [
    {'codeNm': '전체', 'code': 'ALL'},
    {'codeNm': 'TOP10', 'code': 'TOP10'},
    {'codeNm': '사건수임', 'code': '사건수임'},
    {'codeNm': '견적서', 'code': '견적서'},
    {'codeNm': '사전정보', 'code': '사전정보'},
    {'codeNm': '보험가입', 'code': '보험가입'},
    {'codeNm': '지급정보', 'code': '지급정보'},
    {'codeNm': '대출금', 'code': '대출금'},
    {'codeNm': '상환말소', 'code': '상환말소'},
    {'codeNm': '접수번호', 'code': '접수번호'},
    {'codeNm': '서류등록', 'code': '서류등록'},
    {'codeNm': '회원정보', 'code': '회원정보'},
    {'codeNm': '기타', 'code': '기타'},
  ];
  // late List<SearchCommCodeRes> badgeList2 = [];

  // final StreamController<ResStream<List<SearchCommCodeRes>>> codeCtrl = StreamController();
  final StreamController<ResStream<List<BoardDetailData>>> listCtrl = StreamController();

  List<BoardDetailData> boardList = [];

  // 뱃지 선택 리스트
  final ValueNotifier<List<String>> badgeSelectedList = ValueNotifier<List<String>>(['']);
//   final ValueNotifier<List<String>> badgeSelectedList = ValueNotifier(<String>[]);

  String ptupDsc = 'FAQ';
  String ptupTrgtDsc = '';
  String topYn = 'N';

  int page = 0;
  int pageSzie = 20;
  final ValueNotifier<bool> isLastPage = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isMoreLoading = ValueNotifier<bool>(false);

  @override
  initState() {
    super.initState();
    //  getCodeData();
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

  Future<void> getDataInit() async => getData(0);
  Future<void> getData(int _page) async {
    if (_page != 0) {
      isMoreLoading.value = true;
    } else {
      listCtrl.sink.add(ResStream.loading());
    }
    try {
      BoardRepo repo = BoardRepo();

      ResData resData = await repo.searchOriginList('FAQ', 'ALL', page, pageSzie);

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
    }
  }

  Future<void> SearchData(String word) async {
    try {
      listCtrl.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();

      ResData resData = await repo.searchOriginList('FAQ', '', page, pageSzie);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        listCtrl.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }

      boardList = ((resData.data['list']) as List).map((data) => BoardDetailData.fromMap(data)).toList();

      listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
    } catch (e) {
      listCtrl.sink.add(ResStream.error(e.toString()));
    }
  }

  // Future<void> badgeSearchData(String word) async {
  //   try {
  //     listCtrl.sink.add(ResStream.loading());
  //     BoardRepo repo = BoardRepo();

  //     BoardReqData reqData = BoardReqData();

  //     reqData.ptupDsc = ptupDsc;
  //     reqData.ptupTrgtDsc = word;
  //     reqData.searchWord = '';
  //     reqData.topYn = topYn;
  //     reqData.page = page;
  //     reqData.pageSize = pageSzie;

  //     ResData resData = await repo.searchList(reqData);

  //     if (resData.code != '00') {
  //       Utils.alert(resData.msg.toString());
  //       listCtrl.sink.add(ResStream.error(resData.msg.toString()));
  //       return;
  //     }

  //     BoardResData boardResData = BoardResData.fromMap(resData.data);

  //     boardList = boardResData.list!;
  //     listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
  //   } catch (e) {
  //     listCtrl.sink.add(ResStream.error(e.toString()));
  //   }
  // }

  @override
  void dispose() {
    listCtrl.close();
    //codeCtrl.close();
    super.dispose();
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
        title: const Text('자주 찾는 질문'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        //  padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(children: [
          const Gap(10),
          buildSearchInputBox(),

          //buildBadgeList(),
          const Gap(20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              height: 1,
              thickness: 2,
              color: Colors.grey,
            ),
          ),
          const Gap(10),
          Utils.commonStreamList<BoardDetailData>(listCtrl, buildList, getDataInit),
        ]),
      ),
    );
  }

  // 검색창
  Widget buildSearchInputBox() {
    return Container(
        height: 62,
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: TextField(
          controller: controller,
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
                SearchData(controller.text);
              },
            ),
          ),
        ));
  }

  // 자주 찾는 질문 뱃지 리스트
  Widget buildBadgeList() {
    return Container(
      //   width: 400,
      //   height: 522,
      alignment: Alignment.center,
      // child: StreamBuilder<ResStream<List<SearchCommCodeRes>>>(
      //     stream: codeCtrl.stream,
      //     builder: (context, snapshot) {
      //       if (!snapshot.hasData) {
      //         return const SizedBox.shrink();
      //       }
      //       return Wrap(
      //         direction: Axis.horizontal,
      //         children: snapshot.data!.data!.map((item) {
      //           return Row(
      //             mainAxisSize: MainAxisSize.min,
      //             mainAxisAlignment: MainAxisAlignment.center,
      //             crossAxisAlignment: CrossAxisAlignment.center,
      //             children: [buildBadgeItem(item), const Gap(10)],
      //           );
      //         }).toList(),
      //       );
      //     }),
      padding: const EdgeInsets.all(20),
      child: Wrap(
        direction: Axis.horizontal,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: badgeList2.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildBadgeItem(badgeList2[index]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildBadgeItem(dynamic text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
      child: ValueListenableBuilder<List<String>>(
          valueListenable: badgeSelectedList,
          builder: (context, val, snapshot) {
            return CustomSecButton(
              text: text.codeNm.toString(),
              type: 'L',
              widthValue: (Get.width / 4) - 17,
              heightValue: 45,
              colorValue: val.contains(text.code.toString()) ? Colors.amber[100] : Colors.grey,
              // color: val.contains(text) ? Colors.white : C.semanticGrayTabBg,
              onPressed: () {
                // if (val.contains(text)) {
                //   badgeSelectedList.value = List.from(badgeSelectedList.value)..remove(text);
                // } else {
                //   badgeSelectedList.value = List.from(badgeSelectedList.value)..add(text);
                // }
                badgeSelectedList.value = [];
                badgeSelectedList.value = List.from(badgeSelectedList.value)..add(text.code.toString());
                // badgeSearchData(text.code.toString());
              },
            );
          }),
    );
  }

  // 자주 찾는 질문 리스트
  Widget buildList(List<BoardDetailData> list) {
    return SizedBox(
      width: double.infinity,
      //   height: 322,
      // padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: list.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return buildItem(list[index]);
        },
      ),
    );
  }

// 자주 찾는 질문 아이템
  Widget buildItem(BoardDetailData data) {
    return Column(
      children: [
        ExpansionTile(
          leading: null,
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,

          //  maintainState: true,
          clipBehavior: Clip.antiAlias,

          // dense: true,
          // visualDensity: VisualDensity.compact,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              data.subject.toString(),
              softWrap: true,
              //  style: KosStyle.bodyB4,
            ),
          ),

          shape: const Border(
            top: BorderSide(color: Colors.white, width: 0),
            bottom: BorderSide(color: Colors.white, width: 0),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: .0, vertical: 0.0),
          collapsedShape: const RoundedRectangleBorder(
            side: BorderSide.none,
          ),

          children: [
            ListTile(
              style: ListTileStyle.drawer,
              contentPadding: EdgeInsets.zero, // this also removes horizontal padding
              dense: true,
              // shape: const Border(
              //   top: BorderSide(),
              //   bottom: BorderSide(),
              // ),
              visualDensity: VisualDensity.compact,

              trailing: null,
              selectedTileColor: Colors.red,
              selected: false,
              horizontalTitleGap: 0,
              minVerticalPadding: 0,
              title: Container(
                color: Colors.grey[100],
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    data.contents.toString(),
                    softWrap: true,
                    // overflow: TextOverflow.fade,
                    //  style: KosStyle.bodyB1,
                  ),
                ),
              ),
            ),
          ],
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey[300],
        ),
      ],
    );
  }
}
