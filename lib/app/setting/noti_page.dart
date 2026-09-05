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
import 'package:project1/widget/custom_badge.dart';

/// 공지사항 목록 — 설정 화면(setting_page)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
/// 라이트 고정: `SaColors.syncWith(context)`를 부르지 않는다.
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

  String typeCd = 'NOTI';
  String typeDtCd = 'NOTI';

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
      isMoreLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    SaColors.isLight = true; // 라이트 고정 — 앨범 다크모드 잔류 방지
    super.build(context);
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
        title: Text('공지사항', style: SaText.titleS),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: SaColors.bgBase,
      body: RefreshIndicator(
        onRefresh: () async => await getData(0),
        child: SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(children: [
            const Gap(8),
            // 공통 스트림 빌더
            Utils.commonStreamList<BoardDetailData>(listCtrl, buildList, getDataInit),
            ValueListenableBuilder<bool>(
                valueListenable: isMoreLoading,
                builder: (context, val, snapshot) {
                  if (val) {
                    return SizedBox(height: 60, child: Utils.progressbar());
                  } else {
                    return const SizedBox(
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

        // if (!isLastPage.value) ...[
        //   const Gap(10),
        //   Text('가져오는 중....'),
        // ]
      ),
    );
  }

  // regDate가 null이거나 8자 미만이면 빈 문자열 반환(RangeError 방지). 'YYYYMMDD...' → 'YYYY.MM.DD'
  String _formatRegDate(String? raw) {
    if (raw == null || raw.length < 8) return '';
    return '${raw.substring(0, 4)}.${raw.substring(4, 6)}.${raw.substring(6, 8)}';
  }

// 공지사항 아이템
  Widget buildItem(BoardDetailData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      child: Column(
        children: [
          ElevatedButton(
            clipBehavior: Clip.none,
            style: ElevatedButton.styleFrom(
              shadowColor: Colors.transparent,
              // fixedSize: Size(0, 0),
              minimumSize: Size.zero, // Set this
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.transparent,
            ),
            onPressed: () => Get.toNamed('/NotiViewPage', arguments: {'boardId': data.boardId.toString()}),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              //   crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 카드 내부 패딩(14)만큼 가로가 좁아져, 긴 제목이 넘치지 않도록 Expanded로 감싼다.
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 뱃지 색(colorNo)은 항목 구분용이라 원본 유지.
                          if (data.isTop == 'Y') ...[
                            CustomBadge(
                              text: 'Top',
                              colorNo: 4,
                            ),
                            const Gap(5),
                          ],
                          if (data.isNew == 'Y') ...[
                            CustomBadge(
                              text: 'New',
                              colorNo: 1,
                            ),
                            const Gap(5),
                          ],
                          Flexible(
                            child: Text(
                              data.subject.toString(),
                              softWrap: true,
                              overflow: TextOverflow.fade,
                              style: SaText.titleS,
                            ),
                          ),
                          const Gap(6),
                          // const Align(alignment: Alignment.centerRight, child: Icon(Icons.new_label_sharp, size: 14, color: Colors.red)),
                        ],
                      ),
                      const Gap(6),
                      Text(
                        _formatRegDate(data.regDate),
                        style: SaText.caption.copyWith(color: SaColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const Gap(6),
                PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: SaColors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
