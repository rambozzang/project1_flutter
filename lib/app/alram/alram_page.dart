import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:project1/app/chatting/main.dart';
import 'package:project1/repo/alram/alram_repo.dart';
import 'package:project1/repo/alram/data/alram_req_data.dart';
import 'package:project1/repo/alram/data/alram_res_data.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/repo/mist_gogoapi/mist_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_badge.dart';
import 'package:rxdart/rxdart.dart';

class AlramPage extends StatefulWidget {
  const AlramPage({super.key});

  @override
  State<AlramPage> createState() => _AlramPageState();
}

class _AlramPageState extends State<AlramPage> with AutomaticKeepAliveClientMixin {
  List<AlramResData> list = <AlramResData>[];

  @override
  bool get wantKeepAlive => true;
  // 스크롤 컨트롤러
  ScrollController scrollCtrl = ScrollController();

  // 데이터 스크림
  final StreamController<ResStream<List<AlramResData>>> listCtrl = BehaviorSubject();

  // bool isLastPage = false;
  int page = 0;
  int pageSzie = 10;
  final ValueNotifier<bool> isLastPage = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isMoreLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
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
    try {
      listCtrl.sink.add(ResStream.loading());
      AlramRepo repo = AlramRepo();
      AlramReqData reqData = AlramReqData();
      reqData.receiverCustId = '3393153168';
      reqData.senderCustId = 'tigerbk';
      reqData.alramCd = '100';
      final ResData res = await repo.getAlramList(reqData);
      list = (res.data as List).map((data) => AlramResData.fromMap(data)).toList();
      listCtrl.sink.add(ResStream.completed(list));

      Lo.g(res);
    } catch (e) {
      listCtrl.sink.add(ResStream.error(e.toString()));
      lo.g(e.toString());
    }
  }

  // 미세먼지 가져오기
  void getMistData(String localName) async {
    try {
      MistRepo mistRepo = MistRepo();

      // 동이름 가져오기
      // String _localName = localName.split(' ')[1];
      String _localName = localName;
      Lo.g('_localName :  $_localName');

      Response? res = await mistRepo.getMistData(_localName);
      Lo.g('getMistData() res1 : ${res!.data}');
      Lo.g('getMistData() res2 : ${res!.data['response']}');
      Lo.g('getMistData() res3 : ${res!.data['response']['body']}');

      MistData mistData = MistData.fromJson(jsonEncode(res!.data['response']['body']));
      Lo.g('10 >>>' + mistData.items![0].pm10Value!);
      String result10 = mistRepo.getMist10Grade(mistData.items![0].pm10Value!);
      String result25 = mistRepo.getMist25Grade(mistData.items![0].pm10Value!);

      Lo.g('10 >>>' + result10);
      // Lo.g('25 >>>' + getMist25Grade(mistData.items![0].pm25Value!));
    } catch (e) {
      Lo.g('getMistData() error : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          centerTitle: false,
          title: const Text('알람'),
          // actions: [

          //   IconButton(
          //     onPressed: () async => await getData(0),
          //     icon: const Icon(Icons.refresh_outlined),
          //   ),
          // IconButton(
          //     onPressed: () async => await getData(0),
          //     icon: const Icon(Icons.refresh_outlined),
          //   ),
          // ],
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [_tabs(), _tabBarView()],
        ),
      ),
    );
  }

  Widget _tabs() {
    return const TabBar(indicatorColor: Colors.black, tabs: [
      Tab(
        // child: Icon(Icons.grid_on),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm),
            Gap(10),
            Text('알람'),
          ],
        ),
      ),
      Tab(
        // child: Icon(Icons.person_pin),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message),
            Gap(10),
            Text('메세지'),
          ],
        ),
      ),
    ]);
  }

  Widget _tabBarView() {
    return Expanded(
      child: TabBarView(children: [
        buildAlramWidget(),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatMainApp())),
          child: const Text('채팅'),
        )
      ]),
    );
  }

  Widget buildAlramWidget() {
    return RefreshIndicator(
      onRefresh: () async => await getData(0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        controller: scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(children: [
          // const Gap(24),
          // 공통 스트림 빌더
          Utils.commonStreamList<AlramResData>(listCtrl, buildList, getDataInit),
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
    );
  }

  Widget buildList(List<AlramResData> list) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          itemCount: list.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return buildItem(list[index]);
          },
        ),
      ],
    );
  }

  Widget buildItem(AlramResData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Divider(
        //   height: 1,
        //   thickness: 1,
        //   color: Colors.grey[300],
        // ),
        const Gap(10),
        Divider(
          height: 2,
          thickness: 2,
          color: Colors.grey[300],
        ),
        ElevatedButton(
          clipBehavior: Clip.none,
          style: ElevatedButton.styleFrom(
            shadowColor: Colors.transparent,
            // fixedSize: Size(0, 0),
            minimumSize: Size.zero, // Set this
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
              // side: BorderSide(color: Colors.grey.shade500, width: 0.5),
            ),

            backgroundColor: Colors.transparent,
          ),
          onPressed: () => print('눌림'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[100],
                child: ClipOval(
                  child: Image.network('https://picsum.photos/200/300',
                      width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error)),
                ),
              ),
              const Gap(10),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.alramContents.toString() + data.alramContents.toString(),
                      softWrap: true,
                      // overflow: TextOverflow.fade,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    const Gap(6),
                    Row(
                      children: [
                        Text(
                          '${data.crtDtm.toString().substring(0, 10).replaceAll('-', '/')}:${data.crtDtm.toString().substring(11, 16)}',
                          // '${data.crtDtm.toString().substring(0, 4)}.${data.crtDtm.toString().substring(5, 7)}.${data.crtDtm.toString().substring(8, 10)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                        ),
                        const Gap(10),
                        Text(
                          data.senderCustId.toString(),
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // const Spacer(),
              const Gap(10),
              ElevatedButton(
                onPressed: () => print('팔로우'),
                clipBehavior: Clip.none,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  elevation: 1.5,
                  minimumSize: const Size(0, 0),
                  backgroundColor: const Color.fromARGB(255, 140, 131, 221),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  '팔로우',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
