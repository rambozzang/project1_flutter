import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/paging_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_sec_button.dart';

/// 자주 찾는 질문(FAQ) — 설정 화면(setting_page)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
/// 라이트 고정: `SaColors.syncWith(context)`를 부르지 않는다. Q&A 본문은 서버 값 그대로 노출한다.
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

  String typeCd = 'FAQ';
  String typeDtCd = 'ALL';
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
  Future<void> getData(int page) async {
    if (page != 0) {
      isMoreLoading.value = true;
    } else {
      listCtrl.sink.add(ResStream.loading());
    }
    try {
      BoardRepo repo = BoardRepo();

      ResData resData = await repo.searchOriginList(typeCd, typeDtCd, page, pageSzie, topYn);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        listCtrl.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }

      // 백엔드 응답에 list/pageData가 없거나 null일 수 있으므로 방어적으로 파싱(크래시 방지).
      final dataMap = resData.data;
      final rawList = (dataMap is Map ? dataMap['list'] : null) as List?;
      List<BoardDetailData> list = (rawList ?? []).map((data) => BoardDetailData.fromMap(data)).toList();

      if (page == 0) {
        boardList.clear();
      }
      final rawPaging = dataMap is Map ? dataMap['pageData'] : null;
      isLastPage.value = rawPaging is Map<String, dynamic> ? (PagingData.fromMap(rawPaging).last ?? true) : true;
      boardList.addAll(list);
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

      ResData resData = await repo.searchOriginList(typeCd, typeDtCd, page, pageSzie, topYn);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        listCtrl.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }

      // 응답 구조 방어(list 누락/null 시 빈 목록).
      final rawList = (resData.data is Map ? resData.data['list'] : null) as List?;
      boardList = (rawList ?? []).map((data) => BoardDetailData.fromMap(data)).toList();

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
    SaColors.isLight = true; // 라이트 고정 — 앨범 다크모드 잔류 방지
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        // 뒤로가기 — setting_page와 같은 원형 surface 버튼(pill). 화면 좌측 패딩 16에 맞춘다.
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: SaColors.surface,
                shape: CircleBorder(side: BorderSide(color: SaColors.borderStrong)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: PhosphorIcon(PhosphorIconsBold.caretLeft, size: 17, color: SaColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text('자주 찾는 질문', style: SaText.titleS),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: SaColors.bgBase,
      body: SingleChildScrollView(
        //  padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(children: [
          const Gap(8),
          buildSearchInputBox(),

          //buildBadgeList(),
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Utils.commonStreamList<BoardDetailData>(listCtrl, buildList, getDataInit),
          ),
          const Gap(40),
        ]),
      ),
    );
  }

  // 검색창 — 앨범 탐색(album_explore_page)의 검색창과 같은 규격
  Widget buildSearchInputBox() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          style: SaText.bodyMedium.copyWith(decorationThickness: 0), // 한글밑줄제거
          decoration: InputDecoration(
            hintText: '궁금한 것을 빠르게 검색해보세요.',
            hintStyle: SaText.body.copyWith(fontSize: 13, color: SaColors.textTertiary),
            filled: true,
            fillColor: SaColors.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: SaColors.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: SaColors.accentTeal),
            ),
            suffixIcon: IconButton(
              icon: PhosphorIcon(PhosphorIconsBold.magnifyingGlass, size: 16, color: SaColors.textSecondary),
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
  // 카드 r26 / surface / border / 내부 패딩 14 — setting_page의 SettingsGroup과 같은 규격.
  // 배경은 Container가 아니라 Material이 그린다(항목의 잉크 리플이 가려지지 않도록).
  Widget buildList(List<BoardDetailData> list) {
    return Material(
      color: SaColors.surface,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: SaColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: list.length,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (context, index) => Divider(color: SaColors.border, height: 13, thickness: 1),
          itemBuilder: (BuildContext context, int index) {
            return buildItem(list[index]);
          },
        ),
      ),
    );
  }

// 자주 찾는 질문 아이템
  Widget buildItem(BoardDetailData data) {
    return Column(
      children: [
        ExpansionTile(
          leading: null,
          backgroundColor: SaColors.surface,
          collapsedBackgroundColor: SaColors.surface,
          iconColor: SaColors.textTertiary,
          collapsedIconColor: SaColors.textTertiary,

          //  maintainState: true,
          clipBehavior: Clip.antiAlias,

          // dense: true,
          // visualDensity: VisualDensity.compact,
          tilePadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(
              data.subject.toString(),
              softWrap: true,
              style: SaText.titleS,
            ),
          ),

          // 확장/축소 시 나타나는 기본 외곽선 제거(카드가 이미 테두리를 갖는다).
          shape: const Border(),
          childrenPadding: const EdgeInsets.symmetric(horizontal: .0, vertical: 0.0),
          collapsedShape: const Border(),

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
              // selected가 항상 false라 실제로 그려지지 않는 값 — 위험색이라 원본 유지.
              selectedTileColor: Colors.red,
              selected: false,
              horizontalTitleGap: 0,
              minVerticalPadding: 0,
              title: Container(
                decoration: BoxDecoration(
                  color: SaColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(
                  data.contents.toString(),
                  softWrap: true,
                  // overflow: TextOverflow.fade,
                  style: SaText.body.copyWith(color: SaColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
