import 'dart:async';
import 'dart:io';

import 'package:app_version_update/app_version_update.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/alram/alram_page.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/camera/page/camera_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/app/chatting/lib/flutter_supabase_chat_core.dart';
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
    bottomItem(Icons.cloudy_snowing, '날씨'),
    // bottomItem(Icons.cloud_queue, '날씨'),
    bottomItem(Icons.add, '추가'),
    bottomItem(Icons.favorite, '알람'),
    bottomItem(Icons.person, '내정보'),
  ];
  // body Widget List
  late List<Widget> mainlist = [
    const VideoListPage(),
    const WeathgergogoPage(),
    const SizedBox.shrink(),
    const SizedBox.shrink(),
    const SizedBox.shrink()
  ];

  @override
  void initState() {
    super.initState();
    Get.put(VideoListCntr());
    checkAppVersion();

    // initFirebase();

    // getData();
    // 3초후 실행
    // Future.delayed(const Duration(seconds: 3), () {
    //   Utils.AppUpdateAlert(context);
    //   // Utils.checkAppVersion();

    //   Utils.bottomNotiAlert(context, '신기능 추가', '날씨 예보 비교 기능 추가되었습니다.');
    // });
  }

  // Future<void> initFirebase() async {
  //   if (Platform.isIOS) {
  //     await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //       alert: true,
  //       badge: true,
  //       sound: true,
  //     );
  //     await FirebaseMessaging.instance.requestPermission(
  //       alert: true,
  //       announcement: false,
  //       badge: true,
  //       carPlay: false,
  //       criticalAlert: false,
  //       provisional: false,
  //       sound: true,
  //     );
  //   }
  // }

  Future<void> checkAppVersion() async {
    try {
      await AppVersionUpdate.checkForUpdates(appleId: AppConfig.appleId, playStoreId: AppConfig.playStoreId).then((data) async {
        lo.g('checkAppVersion : ${data.storeUrl}');
        lo.g('checkAppVersion : ${data.storeVersion}');

        if (data.canUpdate!) {
          Utils.appUpdateAlert(context, data.storeUrl.toString());
        }
      });
    } catch (e) {
      lo.g('checkAppVersion : ${e}');
    }
  }

  DateTime? currentBackPressTime = null;

  //뒤로가기 로직(핸드폰 뒤로가기 버튼 클릭시)
  Future<void> onGoBack(didPop) async {
    lo.g('didPop : ${didPop} ');

    if (didPop) return;

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
    log("rootpage ");
    // return Listener(
    //   behavior: HitTestBehavior.translucent,
    //   onPointerDown: handleUserInteraction,
    //   onPointerMove: handleUserInteraction,
    //   onPointerUp: handleUserInteraction,
    return UserOnlineStateObserver(
      child: Scaffold(
        backgroundColor: Colors.transparent, //  Color(0xFF262B49),
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
        // ),
      ),
    );
  }

  void goRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            return CameraBloc(cameraUtils: CameraUtils(), permissionUtils: PermissionUtils())
              ..add(const CameraInitialize(recordingLimit: 15));
          },
          child: const CameraPage(),
        ),
      ),
    );
  }

  onClick(index) {
    // 검색 페이지로 이동
    // if (index == 1) {
    //   mainlist[1] = const WeatherPage();
    //   // mainlist[1] = const SearchPage();
    // }

    // if (index == 1) {
    //   mainlist[1] = const WeatherPage();
    // }

    // 가운데 + 키 눌렀을대 카메라로 이동
    if (index == 2) {
      goRecord();
      return;
    }
    // 알람 페이지로 이동
    if (index == 3) {
      mainlist[3] = const AlramPage();
    }
    //내정보 페이지로 이동
    if (index == 4) {
      mainlist[4] = const MyPage();
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
    return Container();
  }
}
