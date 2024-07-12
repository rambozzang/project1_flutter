import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

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
    if (boardId == null) {
      Utils.alertIcon('비정상적인 접근입니다.', icontype: 'E');
      Get.back();
      return;
    }

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
    var _isChecked = false;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('공지사항 보기'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Utils.commonStreamBody<BoardDetailData>(dataCtrl, buildBody, getDataInit),
      ),
    );
  }

  Column buildBody(BoardDetailData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(20),
        Wrap(
          children: [
            Text(
              '${data.subject}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          "${data.crtDtm!.replaceAll('T', ' ')}",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
        ),
        const Divider(
          height: 25,
          thickness: 1,
          color: Colors.black38,
        ),
        Wrap(
          children: [
            Text(
              '${data.contents}',
            ),
          ],
        ),
        const Gap(20),
        const Gap(20),
      ],
    );
  }
}
