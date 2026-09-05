import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 공지사항 상세 — 설정 화면(setting_page)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
/// 라이트 고정: `SaColors.syncWith(context)`를 부르지 않는다.
class NotiViewPage extends StatefulWidget {
  const NotiViewPage({super.key});

  @override
  State<NotiViewPage> createState() => _NotiViewPageState();
}

class _NotiViewPageState extends State<NotiViewPage> {
  final formKey = GlobalKey<FormState>();

  final StreamController<ResStream<BoardDetailData>> dataCtrl = StreamController();

  late String boardId;

  @override
  initState() {
    super.initState();

    boardId = Get.arguments['boardId'] ?? '0';
    Lo.g('boardId : $boardId');

    getData(boardId);
  }

  Future<void> getDataInit() async => getData(boardId);

  Future<void> getData(String boardId) async {
    try {
      dataCtrl.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData resData = await repo.getDefBoardByBoardId(boardId);

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
  Widget build(BuildContext context) {
    SaColors.isLight = true; // 라이트 고정 — 앨범 다크모드 잔류 방지
    var isChecked = false;
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
        title: Text('공지사항 보기', style: SaText.titleS),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: SaColors.bgBase,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Utils.commonStreamBody<BoardDetailData>(dataCtrl, buildBody, getDataInit),
      ),
    );
  }

  Column buildBody(BoardDetailData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(12),
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
                Wrap(
                  children: [
                    Text(
                      '${data.subject}',
                      style: SaText.titleS,
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  data.crtDtm!.replaceAll('T', ' '),
                  style: SaText.caption.copyWith(color: SaColors.textTertiary),
                ),
                Divider(
                  height: 25,
                  thickness: 1,
                  color: SaColors.border,
                ),
                Wrap(
                  children: [
                    Text(
                      '${data.contents}',
                      style: SaText.body.copyWith(color: SaColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Gap(40),
      ],
    );
  }
}
