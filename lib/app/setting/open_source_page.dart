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

class OpenSourcePage extends StatefulWidget {
  const OpenSourcePage({super.key});

  @override
  State<OpenSourcePage> createState() => _OpenSourcePageState();
}

class _OpenSourcePageState extends State<OpenSourcePage> {
  final formKey = GlobalKey<FormState>();

  final StreamController<ResStream<List<BoardDetailData>>> listCtrl = StreamController();

  List<BoardDetailData> boardList = [];

  String ptupDsc = 'OPEN';
  String ptupTrgtDsc = 'OPEN';
  int page = 0;
  int pageSzie = 2000;
  String topYn = 'N';

  @override
  initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    try {
      listCtrl.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();

      ResData resData = await repo.searchOriginList('FAQ', 'ALL', page, pageSzie);

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

  @override
  void dispose() {
    listCtrl.close();
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
        title: const Text('오픈소스 라이센스'),
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
                Utils.commonStreamList<BoardDetailData>(listCtrl, buildList, getData),
                buildItem(BoardDetailData(subject: '이미지 출처: Freepik')),
                //<a href="https://kr.freepik.com/free-vector/flat-design-illustration-customer-support_12982910.htm#query=%EA%B3%A0%EA%B0%9D%EC%84%BC%ED%84%B0&position=1&from_view=keyword&track=ais&uuid=aa7b7691-daa1-46c6-88d0-55653a755271">Freepik</a>
                const Gap(200),
              ],
            ),
          ),
          const Gap(300),
        ]),
      ),
    );
  }

// 오픈 소스 리스트
  Widget buildList(List<BoardDetailData> list) {
    return SizedBox(
      width: double.infinity,
      //   height: 322,
      //padding: const EdgeInsets.all(20),
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

// 오픈 소스 리스트
  Widget buildItem(BoardDetailData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
              shadowColor: Colors.grey[50],
              // fixedSize: Size(0, 0),
              minimumSize: Size.zero, // Set this
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              backgroundColor: Colors.grey[200],
            ),
            onPressed: () => Lo.g('data.ptupSeq'),
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
                        Text(
                          data.subject.toString(),
                          softWrap: true,
                          overflow: TextOverflow.fade,
                        ),
                        const Gap(6),
                      ],
                    ),
                    const Gap(10),
                    Text(
                      '출처 : Google inc.',
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
