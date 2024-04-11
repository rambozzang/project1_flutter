import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/camera/page/camera_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/app/list/cntr/video_list_cntr.dart';
import 'package:project1/app/list/video_list_page.dart';
import 'package:project1/app/myinfo/myinfo_page.dart';
import 'package:project1/app/search/search_page.dart';
import 'package:project1/app/setting/setting_page.dart';
import 'package:project1/root/main_view1.dart';
import 'package:project1/root/main_view2.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/root/main_view3.dart';
import 'package:project1/utils/log_utils.dart';
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

    mainlist = [const VideoListPage(), SearchPage(), const SizedBox(), const SizedBox(), const SettingPage()];

    bottomItemList = [
      bottomItem(Icons.home, '홈'),
      bottomItem(Icons.search, '검색'),
      bottomItem(Icons.add, '추가'),
      bottomItem(Icons.favorite, '내정보'),
      bottomItem(Icons.person, '설정'),
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

  DateTime? currentBackPressTime = null;

  //뒤로가기 로직(핸드폰 뒤로가기 버튼 클릭시)
  Future<void> onGoBack(didPop) async {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null || now.difference(currentBackPressTime!) > const Duration(milliseconds: 2000)) {
      currentBackPressTime = now;
      Utils.alertIcon('한번 더 백버튼을 누르면 앱이 종료됩니다.', // Page No : ${RootCntr.to.rootPageIndex.value}',
          icontype: 'W',
          duration: const Duration(milliseconds: 2000));
      return Future.value(false);
    }
    //앱 종료
    if (Platform.isIOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: handleUserInteraction,
      onPointerMove: handleUserInteraction,
      onPointerUp: handleUserInteraction,
      child: Scaffold(
        // backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
                child: PopScope(
              canPop: false,
              onPopInvoked: (bool didPop) async => onGoBack(didPop),
              child: Obx(() => FadeIndexedStack(
                  index: RootCntr.to.rootPageIndex.value, // RootCntr.to.rootPageIndex.value,
                  key: scaffoldKey,
                  children: mainlist)),
            )),
            Positioned(
              top: 100,
              right: 20,
              child: Obx(() => Column(
                    children: [
                      RootCntr.to.isFileUploading.value == UploadingType.UPLOADING
                          ? Column(
                              children: [
                                Utils.progressUpload(size: 20),
                                const Gap(5),
                                const Text(
                                  "Uploading..",
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                )
                              ],
                            )
                          : RootCntr.to.isFileUploading.value == UploadingType.SUCCESS
                              ? Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: Row(
                                      children: [
                                        // Icon(Icons.check, color: Colors.yellow, size: 20),
                                        Text(
                                          "게시물이 정상 게시 되었습니다.",
                                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                    ],
                  )),
            )

            // RootCntr.to.isFileUploading.value == UploadingType.NONE
            //     ? const SizedBox()
            //     :  ( RootCntr.to.isFileUploading.value == UploadingType.UPLOADING
            //        ? Positioned(
            //           top: 90,
            //           right: 20,
            // child: Column(
            //   children: [
            //     Utils.progressUpload(size: 20),
            //     const Gap(5),
            //     const Text(
            //       "Uploading..",
            //       style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            //     )
            //   ],
            // ),)
            //       : (RootCntr.to.isFileUploading.value == UploadingType.SUCCESS
            //         ? Container(
            //             color: Colors.black,
            //             child: const Center(
            //               child: Text(
            //                 "임시 게시물이 정상 게시 되었습니다.",
            //                 style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            //               ),
            //             ),
            //           )
            //         : const SizedBox(),)
            //  : const SizedBox(),
            //           ),
            //)
            ,
            ValueListenableBuilder(
                valueListenable: isEventBox,
                builder: (BuildContext context, bool value, Widget? child) {
                  return value ? centerEventContainer() : Container();
                }),
          ],
        ),
        extendBody: true,
        floatingActionButtonLocation: Platform.isIOS ? FloatingActionButtonLocation.centerDocked : FloatingActionButtonLocation.centerFloat,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        // floatingActionButton: makeBottomItem(),
        bottomSheet: const Padding(padding: EdgeInsets.only(bottom: 0.0)),

        floatingActionButton: Obx(() => HideBottomBar(childWdiget: makeBottomItem())),
        // bottomNavigationBar: Obx(() => HideBottomBar(children: makeBottomItem())),
      ),
    );
  }

  void goRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            return CameraBloc(
              cameraUtils: CameraUtils(),
              permissionUtils: PermissionUtils(),
              currentWeather: Get.find<VideoListCntr>().currentWeather.value,
            )..add(const CameraInitialize(recordingLimit: 15));
          },
          child: const CameraPage(),
        ),
      ),
    );
  }

  onClick(index) {
    // 가운데 + 키 눌렀을대 카메라로 이동
    if (index == 2) {
      goRecord();
      return;
    }
    //
    if (index == 3) {
      mainlist[3] = const MyPage();
    }
    RootCntr.to.changeRootPageIndex(index);
  }

  BottomNavigationBarItem bottomItem(IconData icondata, String label) {
    return BottomNavigationBarItem(
      icon: Obx(() => Icon(
            icondata,
            color: RootCntr.to.rootPageIndex.value == 0 ? Colors.white : Colors.grey,
          )),
      label: label,
      activeIcon: Icon(icondata, color: Colors.black),
    );
  }

  Widget makeBottomItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
      decoration: BoxDecoration(
        // color: Colors.grey.withOpacity(0.63),
        color: RootCntr.to.rootPageIndex.value == 0 ? Colors.white10.withOpacity(0.63) : Colors.grey[200]?.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.63), width: 0.25),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: RootCntr.to.rootPageIndex.value,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        //    backgroundColor: Colors.grey[100],
        showSelectedLabels: true,
        iconSize: 22,
        onTap: (index) {
          onClick(index);
        },
        selectedIconTheme: const IconThemeData(size: 24),
        selectedFontSize: 13,
        selectedItemColor: Colors.black,
        unselectedFontSize: 11,
        unselectedItemColor: RootCntr.to.rootPageIndex.value == 0 ? Colors.white : Colors.black,
        unselectedIconTheme: const IconThemeData(size: 22),
        items: bottomItemList,
      ),
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
