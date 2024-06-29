import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/chatting/main.dart';
import 'package:project1/app/chatting/chat_main_page.dart';
import 'package:project1/repo/alram/alram_repo.dart';
import 'package:project1/repo/alram/data/alram_req_data.dart';
import 'package:project1/repo/alram/data/alram_res_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

class AlramPage extends StatefulWidget {
  const AlramPage({super.key});

  @override
  State<AlramPage> createState() => _AlramPageState();
}

class _AlramPageState extends State<AlramPage> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  List<AlramResData> list = <AlramResData>[];

  @override
  bool get wantKeepAlive => true;
  // 스크롤 컨트롤러
  ScrollController scrollCtrl = ScrollController();

  // 데이터 스크림
  final StreamController<ResStream<List<AlramResData>>> listCtrl = BehaviorSubject();

  // bool isLastPage = false;
  int page = 0;
  int pageSzie = 15;
  bool isLastPage = false;
  final ValueNotifier<bool> isMoreLoading = ValueNotifier<bool>(false);

  late TabController tabController;

  GlobalKey<ChatMainAppState> chatMainPageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    tabController = TabController(vsync: this, length: 2);

    getData(0);
    scrollCtrl.addListener(() {
      RootCntr.to.changeScrollListner(scrollCtrl);
      if (scrollCtrl.position.pixels == scrollCtrl.position.maxScrollExtent) {
        if (!isLastPage) {
          page++;
          isMoreLoading.value = true;
          getData(page);
        }
      }
    });
  }

  Future<void> getDataInit() async {
    page = 0;
    getData(page);
  }

  Future<void> getData(int page) async {
    try {
      if (page == 0) {
        listCtrl.sink.add(ResStream.loading());
        list.clear();
      }

      AlramRepo repo = AlramRepo();
      AlramReqData reqData = AlramReqData();
      reqData.receiverCustId = Get.find<AuthCntr>().custId.value;
      reqData.senderCustId = '';
      reqData.alramCd = '';
      reqData.pageNum = page;
      reqData.pageSize = pageSzie;

      final ResData res = await repo.getAlramList(reqData);
      if (res.data == null) {
        isLastPage = true;
        listCtrl.sink.add(ResStream.completed(list));
        return;
      }
      List<AlramResData> _list = (res.data as List).map((data) => AlramResData.fromMap(data)).toList();
      list.addAll(_list);
      if (_list.length < pageSzie) {
        isLastPage = true;
      }
      isMoreLoading.value = false;
      listCtrl.sink.add(ResStream.completed(list));

      Lo.g(res);
    } catch (e) {
      listCtrl.sink.add(ResStream.error(e.toString()));
      lo.g(e.toString());
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    listCtrl.close();
    scrollCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          centerTitle: false,
          title: const Text('알람'),
          actions: [
            // IconButton(
            //   onPressed: () => NotiShow(),
            //   icon: const Icon(Icons.chat_bubble_outline),
            // ),
            IconButton(
              onPressed: () => tabController.index == 0 ? getDataInit() : chatMainPageKey.currentState?.initSupaBaseSession(),
              icon: const Icon(Icons.refresh_outlined),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [_tabs(), _tabBarView()],
        ),
      ),
    );
  }

  Widget _tabs() {
    return TabBar(controller: tabController, indicatorColor: Colors.black, tabs: const [
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
            Text('대화하기'),
          ],
        ),
      ),
    ]);
  }

  Widget _tabBarView() {
    return Expanded(
      child: TabBarView(controller: tabController, children: [
        buildAlramWidget(),
        ChatMainApp(
          key: chatMainPageKey,
        )
        // TextButton(
        //   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatMainApp())),
        //   child: const Text('채팅'),
        // )
      ]),
    );
  }

  // 알림 리스트 위젯
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
                  return SizedBox(height: 60, child: Utils.progressbar(size: 50));
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
        const Gap(15),
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
        // const Gap(10),
        // Divider(
        //   height: 2,
        //   thickness: 2,
        //   color: Colors.grey[300],
        // ),
        ElevatedButton(
          clipBehavior: Clip.none,
          style: ElevatedButton.styleFrom(
            shadowColor: Colors.transparent,
            // fixedSize: Size(0, 0),
            minimumSize: Size.zero, // Set this
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            backgroundColor: Colors.transparent,
          ),
          onPressed: () {
            if (data.boardId != null) {
              Get.toNamed('/VideoMyinfoListPage',
                  arguments: {'datatype': 'ONE', 'custId': AuthCntr.to.resLoginData.value.custId, 'boardId': data.boardId.toString()});
            } else {
              Get.toNamed('/OtherInfoPage/${data.senderCustId}');
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    // color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(data.profilePath.toString()),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: data.profilePath == null ? const Icon(Icons.person, color: Colors.white) : null),
              const Gap(10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          data.alramTitle.toString(),
                          softWrap: true,
                          // overflow: TextOverflow.fade,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        const Spacer(),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            data.alramContents.toString(),
                            // softWrap: true,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                          ),
                        ),
                        const Gap(5),
                        data.boardId != null
                            ?
                            // 이쁜 게시물확인 버튼 만들어주세요.

                            SizedBox(
                                width: 20,
                                height: 25,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    Get.toNamed('/VideoMyinfoListPage', arguments: {
                                      'datatype': 'ONE',
                                      'custId': AuthCntr.to.resLoginData.value.custId,
                                      'boardId': data.boardId.toString()
                                    });
                                  },
                                  child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                                ),
                              )
                            : const SizedBox(
                                width: 10,
                              ),
                      ],
                    ),
                    // const Gap(6),
                    SizedBox(
                      height: 30,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              // backgroundColor: Colors.red,
                            ),
                            onPressed: () => Get.toNamed('/OtherInfoPage/${data.senderCustId}'),
                            child: Text(
                              '@${data.senderNickNm == null ? data.senderCustNm.toString() : data.senderNickNm.toString()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // 가운데 점 표시
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              '·',
                              style: TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                          ),
                          Text(
                            Utils.timeage(data.crtDtm.toString()),
                            // '${data.crtDtm.toString().substring(0, 10).replaceAll('-', '/')} ${data.crtDtm.toString().substring(11, 19)}',

                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black),
                          ),

                          // Text(
                          //   '@${data.senderNickNm == null ? data.senderCustNm.toString() : data.senderNickNm.toString()}',
                          //   softWrap: true,
                          //   overflow: TextOverflow.fade,
                          //   style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // const Spacer(),
              // const Gap(10),
              // ElevatedButton(
              //   onPressed: () => print('팔로우'),
              //   clipBehavior: Clip.none,
              //   style: ElevatedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              //     elevation: 1.5,
              //     minimumSize: const Size(0, 0),
              //     backgroundColor: const Color.fromARGB(255, 140, 131, 221),
              //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(10.0),
              //     ),
              //   ),
              //   child: const Text(
              //     '팔로우',
              //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              //   ),
              // )
            ],
          ),
        ),
      ],
    );
  }
}
