import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/utils.dart';

/// 마케팅 수신 동의 설정 — 설정 화면(setting_page)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
/// 라이트 고정: `SaColors.syncWith(context)`를 부르지 않는다. 약관 본문은 서버에서 받아 그대로 노출한다.
class MaketingPage extends StatefulWidget {
  const MaketingPage({super.key});

  @override
  State<MaketingPage> createState() => _PrivecyPageState();
}

class _PrivecyPageState extends State<MaketingPage> {
  final formKey = GlobalKey<FormState>();

  final StreamController<ResStream<BoardDetailData>> dataCtrl = StreamController();

  List<BoardDetailData> boardList = [];

  String ptupDsc = 'AGRE';
  String ptupTrgtDsc = 'MACT';
  int page = 0;
  int pageSzie = 20;
  String topYn = 'N';

  @override
  initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    try {
      dataCtrl.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();

      ResData resData = await repo.searchOriginList(ptupDsc, ptupTrgtDsc, page, pageSzie, topYn);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        dataCtrl.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }

      boardList = ((resData.data['list']) as List).map((data) => BoardDetailData.fromMap(data)).toList();
      getDataDetail(boardList[0].boardId!);
      // listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
    } catch (e) {
      dataCtrl.sink.add(ResStream.error(e.toString()));
    }
  }

  // 실제 상세 내용 가져오기
  Future<void> getDataDetail(int boardId) async {
    try {
      BoardRepo repo = BoardRepo();
      ResData resData = await repo.getDefBoardByBoardId(boardId.toString());

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        dataCtrl.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }

      BoardDetailData boardList = BoardDetailData.fromMap(resData.data);
      dataCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
    } catch (e) {
      dataCtrl.sink.add(ResStream.error(e.toString()));
    }
  }

  @override
  void dispose() {
    dataCtrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('마케팅 수신 동의설정', style: SaText.titleS),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: SaColors.bgBase,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Gap(10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(4),
                // 공통 스트림 빌더
                Utils.commonStreamBody<BoardDetailData>(dataCtrl, buildBody, getData),
                const Gap(200),
              ],
            ),
          ),
          const Gap(300),
        ]),
      ),
    );
  }

  Column buildBody(BoardDetailData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카드 r26 / surface / border / 내부 패딩 14 — 핸드오프 규격
        Material(
          color: SaColors.surface,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: SaColors.border),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    // '${data.subject}',
                    '개인정보 처리방침',
                    style: SaText.titleS),
                Divider(
                  height: 20,
                  thickness: 1,
                  color: SaColors.border,
                ),

                // Text(
                //   '${data.ptupDt}',
                //   style: KosStyle.styleB1SemanticGray14,
                // ),
                Text(
                  "${data.contents}",
                  style: SaText.body.copyWith(color: SaColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
