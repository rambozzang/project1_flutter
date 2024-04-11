import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/utils.dart';

class AgreePage extends StatefulWidget {
  const AgreePage({super.key});

  @override
  State<AgreePage> createState() => _AgreePageState();
}

class _AgreePageState extends State<AgreePage> {
  final formKey = GlobalKey<FormState>();

  final StreamController<ResStream<BoardDetailData>> dataCtrl = StreamController();

  List<BoardDetailData> boardList = [];

  String ptupDsc = 'INDL';
  String ptupTrgtDsc = 'INDL';
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

      ResData resData = await repo.searchOriginList('FAQ', 'ALL', page, pageSzie);

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('서비스 이용약관'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
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
        Text(
            //   '${data.subject}',
            '서비스 이용약관'),
        const Divider(
          height: 20,
          thickness: 1,
          color: Colors.black,
        ),

        // Text(
        //   '${data.ptupDt}',
        //   style: KosStyle.styleB1SemanticGray14,
        // ),
        Text(
          "${data.contents}",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
        ),
      ],
    );
  }
}
