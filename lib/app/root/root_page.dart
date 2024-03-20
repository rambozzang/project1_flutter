import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:project1/app/root/main_view1.dart';
import 'package:project1/app/root/cntr/root_cntr.dart';
import 'package:project1/app/root/main_view2.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/fade_stack.dart';
import 'package:project1/widget/hide_bottombar.dart';

// ignore: must_be_immutable
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => RootPageState();
}

class RootPageState extends State<RootPage> with TickerProviderStateMixin {
  final GlobalKey scaffoldKey = GlobalKey<ScaffoldState>();

  ValueNotifier<bool> isEventBox = ValueNotifier<bool>(false);
  ValueNotifier<bool> isBottomBox = ValueNotifier<bool>(true);

  Color bgcolor = const Color.fromARGB(255, 12, 12, 12);
  var messageString = "";
  // 로그아웃 타임 설정
  int timerMinute = 300;
  Timer rootTimer = Timer.periodic(const Duration(seconds: 1), (timer) {});

  // bottom item list
  late List<BottomNavigationBarItem> bottomItemList = [];
  // body Widget List
  late List<Widget> mainlist = [];

  @override
  void initState() {
    super.initState();
    initializeTimer();

    mainlist = [
      const MainView1(),
      MainView2(),
      const Center(child: Text("data3")),
      const Center(child: Text("data4")),
      const Center(child: Text("data5")),
    ];

    bottomItemList = [
      bottomItem(Icons.home, '홈'),
      bottomItem(Icons.search, '검색'),
      bottomItem(Icons.add, '추가'),
      bottomItem(Icons.favorite, '즐겨찾기'),
      bottomItem(Icons.person, '내정보'),
    ];
    // getData();
  }

  void initializeTimer() {
    if (rootTimer != null) rootTimer.cancel();

    // rootTimer = Timer(Duration(seconds: timerSeconds), () { //테스트 코드
    rootTimer = Timer(Duration(minutes: timerMinute), () {
      // Utils.alert('30분동안 움직이 없어 로그아웃됩니다.');
      Get.offAllNamed('/CoLogOutPage');
    });
  }

  // 사용자 상호작용을 처리하는 메서드
  void handleUserInteraction([_]) {
    if (!rootTimer.isActive) {
      // 이미 타이머가 종료되었으면 무시
      return;
    }
    rootTimer.cancel();
    initializeTimer();
  }

  void goPage(int page) async {
    Utils.alert('page : $page');
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: handleUserInteraction,
      onPointerMove: handleUserInteraction,
      onPointerUp: handleUserInteraction,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
                child: PopScope(
              canPop: false,
              onPopInvoked: (bool didPop) {
                // Lo.g('root > onPopInvoked > didPop : $didPop');
                // if (didPop) {
                //   Utils.alert('didPop');
                // } else {
                //   Utils.alert('not didPop');
                // }
                // Utils.alert('onPopInvoked');
              },
              child: SafeArea(
                child: Obx(() => FadeIndexedStack(
                    index: RootCntr.to.rootPageIndex
                        .value, // RootCntr.to.rootPageIndex.value,
                    key: scaffoldKey,
                    children: mainlist)),
              ),
            )),
            ValueListenableBuilder(
                valueListenable: isEventBox,
                builder: (BuildContext context, bool value, Widget? child) {
                  return value ? centerEventContainer() : Container();
                }),
          ],
        ),
        extendBodyBehindAppBar: true,
        bottomNavigationBar:
            Obx(() => HideBottomBar(children: makeBottomItem())),
      ),
    );
  }

  BottomNavigationBarItem bottomItem(IconData icondata, String label) {
    // 4번 클릭시 화면 호출
    if (RootCntr.to.rootPageIndex.value == 1 ||
        RootCntr.to.rootPageIndex.value == 2) {
      //   WidgetsBinding.instance.addPostFrameCallback((_) => goPage(RootCntr.to.rootPageIndex.value));
      //   WidgetsBinding.instance.addPostFrameCallback((_) => goPage(RootCntr.to.rootPageIndex.value));
    }
    return BottomNavigationBarItem(
      backgroundColor: Colors.white,
      icon: Icon(
        icondata,
        color: Colors.grey,
      ),
      label: label,
      activeIcon: Icon(icondata, color: Colors.black),
    );
  }

  BottomNavigationBar makeBottomItem() {
    return BottomNavigationBar(
      currentIndex: RootCntr.to.rootPageIndex.value,
      backgroundColor: Colors.white,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      iconSize: 22,
      onTap: RootCntr.to.changeRootPageIndex,
      selectedIconTheme: const IconThemeData(size: 25),
      selectedFontSize: 13,
      selectedItemColor: Colors.black,
      unselectedFontSize: 11,
      unselectedItemColor: Colors.black,
      unselectedIconTheme: const IconThemeData(size: 23),
      items: bottomItemList,
    );
  }

  Widget centerEventContainer() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        height: 200,
        width: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 170,
              width: 200,
              child: const Center(child: Text('이미지 영역')),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Container(
              height: 25,
              width: 200,
              color: Colors.white10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Checkbox(
                          side: const BorderSide(color: Colors.black),
                          value: true,
                          onChanged: null,
                        ),
                      ),
                      Text(
                        '하루동안 열지않기',
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        isEventBox.value = false;
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
