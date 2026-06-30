import 'dart:async';
import 'dart:io';

import 'package:app_version_update/app_version_update.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/alram/alram_page.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/camera/page/camera_awesome_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/app/chatting/lib/flutter_supabase_chat_core.dart';
import 'package:project1/app/chatting/supabase_options.dart';
import 'package:project1/app/myinfo/myinfo_page.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/app/videolist/video_list_page.dart';
import 'package:project1/app/weathergogo/weathergogo_page.dart';
import 'package:project1/config/app_config.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/fade_stack.dart';
import 'package:project1/widget/hide_bottombar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late List<BottomNavigationBarItem> bottomItemList = [
    bottomItem(Icons.home, '홈'),
    bottomItem(Icons.cloudy_snowing, 'Feed'),
    // bottomItem(Icons.cloud_queue, '날씨'),
    bottomItem(Icons.add, '추가'),
    bottomItem(Icons.favorite, '라운지'),
    bottomItem(Icons.person, '내정보'),
  ];
  // body Widget List
  late List<Widget> mainlist = [
    const WeathgergogoPage(),
    const VideoListPage(),
    const SizedBox.shrink(),
    const SizedBox.shrink(),
    const SizedBox.shrink()
  ];

  @override
  void initState() {
    super.initState();

    Get.put(VideoListCntr());
    checkAppVersion();

    // 카메라 목록을 미리 열거해 두어 첫 촬영 화면 진입을 빠르게 한다(비동기).
    CameraUtils.warmUp();

    initSetting();
  }

  void initSetting() {
    Future.delayed(const Duration(milliseconds: 3500), () {
      // 광고 초기화는 main.dart에서 한 번만 수행한다. 여기서는 supabase만 초기화한다.
      Supabase.initialize(url: supabaseOptions.url, anonKey: supabaseOptions.anonKey);
    });
  }

  Future<void> checkAppVersion() async {
    try {
      await AppVersionUpdate.checkForUpdates(appleId: AppConfig.appleId, playStoreId: AppConfig.playStoreId, country: 'kr')
          .then((data) async {
        if (data.canUpdate!) {
          if (kDebugMode) {
            Utils.alert("앱 최신번전으로 업데이트가 필요합니다.");
          } else {
            Utils.appUpdateAlert(context, data.storeUrl.toString());
          }
        }
      });
    } catch (e) {
      lo.g('checkAppVersion : $e');
    }
  }

  onClick(index) {
    if (index == 2) {
      goRecord();
      return;
    }
    // 알람 페이지로 이동
    if (index == 3) {
      mainlist[3] = const AlramPage();
      // Get.to(() => const AlramPage2());
      // return;
    }
    //내정보 페이지로 이동
    if (index == 4) {
      mainlist[4] = const MyPage();
    }
    RootCntr.to.changeRootPageIndex(index);
    // 탭 전환 시 하단 플로팅 메뉴바는 항상 표시한다.
    // (이전: Feed 진입 시 add(index != 1)로 무조건 숨겨, 영상을 스와이프해야 다시 나오는 버그가 있었음)
    RootCntr.to.bottomBarStreamController.sink.add(true);
  }

  DateTime? currentBackPressTime = DateTime.now();

  //뒤로가기 로직(핸드폰 뒤로가기 버튼 클릭시)
  Future<void> onGoBack(didPop) async {
    lo.g('didPop : $didPop ');
    if (didPop) return;

    DateTime now = DateTime.now();
    if (currentBackPressTime == null || now.difference(currentBackPressTime!).inMilliseconds > 2000) {
      currentBackPressTime = now;
      Utils.alertIcon('뒤로가기 버튼을 누르면 앱이 종료됩니다.', // Page No : ${RootCntr.to.rootPageIndex.value}',
          icontype: 'W',
          duration: const Duration(milliseconds: 2000));
      return Future.value(false);
    } else {
      //앱 종료
      if (Platform.isIOS) {
        exit(0);
      } else {
        SystemNavigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    log("rootpage ");
    // return Listener(
    //   behavior: HitTestBehavior.translucent,
    //   onPointerDown: handleUserInteraction,
    //   onPointerMove: handleUserInteraction,
    //   onPointerUp: handleUserInteraction,
    return PopScope(
      canPop: false, // ㄷ뒤로가기 버튼 막기(제어)
      onPopInvokedWithResult: (didPop, result) async {
        lo.g("gogogooogogo : $didPop");

        onGoBack(didPop);
      },
      child: UserOnlineStateObserver(
        child: Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // PopScope(
              //   canPop: false, // ㄷ뒤로가기 버튼 막기(제어)
              //   onPopInvokedWithResult: (didPop, result) async {
              //     lo.g("gogogooogogo : $didPop");
              //     if (didPop) return;

              //     onGoBack(didPop);
              //   },
              // child:
              Positioned.fill(
                child: Obx(() => FadeIndexedStack(
                    index: RootCntr.to.rootPageIndex.value, // RootCntr.to.rootPageIndex.value,
                    key: scaffoldKey,
                    children: mainlist)),
              ),
              // ),
              Positioned(
                top: 100,
                right: 20,
                child: Obx(() => Column(
                      children: [
                        if (RootCntr.to.isFileUploading.value == UploadingType.UPLOADING) ...[
                          Column(
                            children: [
                              Utils.progressUpload(size: 25),
                              const Gap(5),
                              Container(
                                color: Colors.black,
                                padding: const EdgeInsets.all(3),
                                child: const Center(
                                  child: Row(
                                    children: [
                                      // Icon(Icons.check, color: Colors.yellow, size: 20),
                                      Text(
                                        "Uploading..",
                                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                        if (RootCntr.to.isFileUploading.value == UploadingType.SUCCESS) ...[
                          Container(
                            color: Colors.black,
                            padding: const EdgeInsets.all(5),
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
                        ],
                        if (RootCntr.to.isFileUploading.value == UploadingType.FAIL) ...[
                          const SizedBox(),
                        ]
                      ],
                    )),
              ),
              // Positioned(
              //   top: 150,
              //   right: 10,
              //   child: TextButton(
              //     onPressed: () => Get.find<ThemeController>().toggleTheme(),
              //     child: Container(
              //       color: Theme.of(context).scaffoldBackgroundColor,
              //       child: Text(
              //         Get.isDarkMode ? 'Dark Theme' : 'Light Theme',
              //         style: TextStyle(color: Theme.of(context).primaryColor),
              //       ),
              //     ),
              //   ),
              // ),

              ValueListenableBuilder(
                  valueListenable: isEventBox,
                  builder: (BuildContext context, bool value, Widget? child) {
                    return value ? centerEventContainer() : Container();
                  }),
            ],
          ),
          extendBody: true,
          floatingActionButtonLocation:
              Platform.isIOS ? FloatingActionButtonLocation.centerDocked : FloatingActionButtonLocation.centerFloat,
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          // floatingActionButton: makeBottomItem(),
          bottomSheet: const Padding(padding: EdgeInsets.only(bottom: 0.0)),

          floatingActionButton: Obx(() => HideBottomBar(childWdiget: makeBottomItem())),
          // bottomNavigationBar: Obx(() => HideBottomBar(children: makeBottomItem())),
          // ),
        ),
      ),
    );
  }

  void goRecord() {
    // 탭하는 "즉시"(라우트 전환 시작 전) 카메라 블록을 만들고 초기화를 시작한다.
    // → 화면 전환 애니메이션(~300ms) 동안 카메라 HW 오픈이 병렬로 진행되어
    //   촬영 화면이 뜰 때쯤 이미 프리뷰가 준비된다(틱톡식 사전 초기화).
    final camBloc = CameraBloc(cameraUtils: CameraUtils(), permissionUtils: PermissionUtils())
      ..add(const CameraInitialize(recordingLimit: 15));

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const CameraAwesomePage(),
          ),
        );
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
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
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
    return Positioned(
      top: MediaQuery.of(context).size.height / 2 - 50,
      left: MediaQuery.of(context).size.width / 2 - 100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "messageString",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }
}
