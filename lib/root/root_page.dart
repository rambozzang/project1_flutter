import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:app_version_update/app_version_update.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:project1/app/shared_album/album_list_page.dart';
import 'package:project1/app/camera/page/camera_awesome_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/myinfo/myinfo_page.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/app/videolist/video_list_page.dart';
import 'package:project1/app/weathergogo/weathergogo_page.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/theme/sky_gradient.dart';
import 'package:project1/config/app_config.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
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
    bottomItem(Icons.cloudy_snowing, 'Feed'),
    // bottomItem(Icons.cloud_queue, '날씨'),
    bottomItem(Icons.add, '추가'),
    bottomItem(Icons.photo_library_rounded, '앨범'),
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
  }

  Future<void> checkAppVersion() async {
    // Android: 공식 In-App Update(Play Core) API로 판단·업데이트.
    // 스토어에 새 버전이 게시되면 스크래핑 없이 versionCode로 안정적으로 감지해 네이티브 업데이트 플로우를 띄운다.
    // (Play 스토어로 설치된 빌드에서만 동작 — 디버그/사이드로드는 예외로 조용히 무시)
    if (Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
          } else if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate();
            await InAppUpdate.completeFlexibleUpdate();
          }
        }
      } catch (e) {
        lo.g('checkAppVersion(Android in_app_update) 실패: $e');
      }
      return;
    }

    // iOS: 기존 경로 유지(App Store iTunes 조회는 신뢰 가능).
    // 현재 설치된 앱 버전 — 하드코딩 상수 대신 런타임 조회(pubspec 버전이 자동 반영되어 rot 없음).
    String currentVersion = '';
    try {
      currentVersion = (await PackageInfo.fromPlatform()).version;
    } catch (e) {
      lo.g('checkAppVersion: PackageInfo 실패 $e');
    }

    // 1차: 백엔드 버전 체크. 실패해도 2차(스토어)로 반드시 넘어가도록 자체 try로 격리한다.
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/comm/appVersion');
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code == '00' && resData.data != null) {
        final String minVersion = resData.data['minVersion']?.toString() ?? '0.0.0';
        final bool force = (resData.data['forceUpdate']?.toString() ?? 'N') == 'Y';
        if (force && currentVersion.isNotEmpty && _compareVersion(currentVersion, minVersion)) {
          lo.g('checkAppVersion: 백엔드 강제업데이트 (현재=$currentVersion, 최소=$minVersion)');
          _showForceUpdate();
          return;
        }
      }
    } catch (e) {
      lo.g('checkAppVersion: 백엔드 체크 실패(스토어 체크로 진행) $e');
    }

    // 2차: 스토어 신버전 확인(스크래핑) — 실패는 조용히 무시(다음 실행 때 재시도).
    try {
      final data = await AppVersionUpdate.checkForUpdates(
          appleId: AppConfig.appleId, playStoreId: AppConfig.playStoreId, country: 'kr');
      if (data.canUpdate == true) {
        if (kDebugMode) {
          Utils.alert("앱 최신버전으로 업데이트가 필요합니다.");
        } else if (mounted) {
          // 스크래핑이 URL을 못 채워주는 경우가 있어 공식 스토어 URL로 폴백을 보장한다.
          final String url =
              (data.storeUrl != null && data.storeUrl!.startsWith('http')) ? data.storeUrl! : _storeUrl();
          Utils.appUpdateAlert(context, url);
        }
      }
    } catch (e) {
      lo.g('checkAppVersion: 스토어 체크 실패 $e');
    }
  }

  /// 플랫폼별 공식 스토어 URL — 강제 업데이트 버튼이 항상 열 수 있는 유효한 링크.
  String _storeUrl() => Platform.isIOS
      ? 'https://apps.apple.com/kr/app/id${AppConfig.appleId}'
      : 'https://play.google.com/store/apps/details?id=${AppConfig.playStoreId}';

  /// a < b 이면 true (업데이트 필요)
  bool _compareVersion(String current, String min) {
    try {
      final cur = current.split('+')[0].split('.').map(int.parse).toList();
      final minParts = min.split('+')[0].split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final c = i < cur.length ? cur[i] : 0;
        final m = i < minParts.length ? minParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _showForceUpdate() {
    if (!mounted) return;
    if (kDebugMode) {
      Utils.alert("앱 최신버전으로 업데이트가 필요합니다. (백엔드)");
      return;
    }
    // 빈 URL을 넘기면 닫을 수 없는 다이얼로그에 갇힌다 — 반드시 유효한 스토어 URL 전달.
    Utils.appUpdateAlert(context, _storeUrl());
  }

  onClick(index) {
    if (index == 2) {
      goRecord();
      return;
    }
    // 앨범(공유앨범 홈 1a — 구 스카이라운지 허브 대체)으로 이동
    if (index == 3) {
      mainlist[3] = const AlbumListPage();
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
              // 업로드 상태 인디케이터는 GetMaterialApp.builder(main.dart)의 전역 Stack으로 승격 —
              // 루트 위에 푸시된 화면(앨범 상세/몰입 등)에서도 보이도록 (GlobalUploadIndicator)
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
    );
  }


  void goRecord() {
    // 일반 카메라 진입: 모임 대상 초기화(모임 홈이 아닌 곳에서 올린 글이 모임에 섞이지 않도록).
    RootCntr.to.pendingCommunityId = null;
    // 카메라는 CameraAwesomePage(camerawesome 패키지)가 자체적으로 열고 권한도 처리한다.
    // ⚠️ 이전: 여기서 CameraBloc(camera 패키지)으로 카메라를 '또' 열어 →
    //   서로 다른 두 카메라 엔진이 같은 카메라 하드웨어를 동시에 점유 →
    //   최초 설치 후 첫 카메라 실행 시 크래시(iOS/Android). 고아 bloc 제거로 해결.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraAwesomePage(),
      ),
    );
  }

  BottomNavigationBarItem bottomItem(IconData icondata, String label) {
    return BottomNavigationBarItem(
      icon: Obx(() => Icon(
            icondata,
            // 날씨 탭: 다크 필 위 또렷한 흰색(미선택), 그 외 탭: 회색
            color: RootCntr.to.rootPageIndex.value == 0 ? Colors.white.withOpacity(0.85) : Colors.grey,
          )),
      label: label,
      // 선택 아이콘도 탭에 맞춰: 날씨 탭 다크 필엔 흰색, 그 외엔 검정
      activeIcon: Obx(() => Icon(
            icondata,
            color: RootCntr.to.rootPageIndex.value == 0 ? Colors.white : Colors.black,
          )),
    );
  }

  Widget makeBottomItem() {
    // 날씨 탭(index 0)은 시간대별 하늘 그라데이션 위에 뜬다. 밤(20~05시)엔 하늘이 거의 검정이라,
    // 아이콘은 흰색으로 두고 필(fill)은 낮·밤 모두 '어둡게' 유지해 흰 아이콘 대비를 지킨다.
    // 대신 밤엔 ①필을 더 불투명하게 ②테두리를 밝혀 윤곽을 살리고 ③은은한 밝은 헤일로로 검정에서 바를 띄운다.
    final bool onSky = RootCntr.to.rootPageIndex.value == 0;
    // 하늘색 Rx(currentColors, 10분마다 _updateSky가 갱신)를 이 Obx에서 구독한다.
    // 이전엔 rootPageIndex만 구독해 '탭 전환 때만' 색이 재계산 → 낮에 켜두고 밤이 되면
    // 하단바가 낮 스타일 그대로라 검은 하늘에서 안 보였다. 이제 시간 흐름에도 따라간다.
    if (Get.isRegistered<WeatherGogoCntr>()) {
      Get.find<WeatherGogoCntr>().currentColors.length; // 구독용 읽기(값 자체는 nf로 계산)
    }
    final double nf = SkyGradient.nightFactor(DateTime.now()); // 밤 1.0 ~ 낮 0.0
    final Color skyBarBg = Color.lerp(
      Colors.black.withOpacity(0.38), // 낮: 밝은 하늘 위 어두운 필
      const Color(0xFF1C2026).withOpacity(0.88), // 밤: 순검정 하늘 위 '떠 있는 어두운 표면'(검정 필은 하늘에 묻힘)
      nf,
    )!;
    final Color skyBorder = Color.lerp(
      Colors.white.withOpacity(0.18), // 낮
      Colors.white.withOpacity(0.55), // 밤: 검정 배경과 확실히 분리되는 밝은 윤곽선
      nf,
    )!;
    final BorderRadius radius = BorderRadius.circular(20);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: radius,
        // 밤엔 은은한 밝은 헤일로로 검정 배경에서 바를 띄운다(어두운 그림자는 검정 위에서 안 보임).
        boxShadow: onSky && nf > 0
            ? [BoxShadow(color: Colors.white.withOpacity(0.10 * nf), blurRadius: 18, spreadRadius: 1)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          // 프로스티드 글래스(앨범 셸 하단바와 동일 패턴) — 바쁜 그라데이션 위에서도 바가 또렷.
          filter: ImageFilter.blur(sigmaX: onSky ? 14 : 0, sigmaY: onSky ? 14 : 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            decoration: BoxDecoration(
              color: onSky ? skyBarBg : Colors.grey[200]?.withOpacity(0.85),
              borderRadius: radius,
              border: Border.all(
                color: onSky ? skyBorder : Colors.grey.withOpacity(0.5),
                width: onSky ? 0.8 : 0.6,
              ),
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
              selectedItemColor: onSky ? Colors.white : Colors.black,
              unselectedFontSize: 11,
              unselectedItemColor: onSky ? Colors.white.withOpacity(0.85) : Colors.black54,
              unselectedIconTheme: const IconThemeData(size: 22),
              items: bottomItemList,
            ),
          ),
        ),
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
