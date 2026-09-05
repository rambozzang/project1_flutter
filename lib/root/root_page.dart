import 'dart:async';
import 'dart:io';

import 'package:app_version_update/app_version_update.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/album_list_page.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/camera/page/camera_awesome_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/home/pending_upload_prompt.dart';
import 'package:project1/app/myinfo/myinfo_page.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/app/videolist/video_list_page.dart';
import 'package:project1/app/weathergogo/weathergogo_page.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
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

  // bottom item list — 아이콘은 "우리의 앨범"과 같은 Phosphor 세트(Fill=선택, Bold=비선택).
  List<BottomNavigationBarItem> get bottomItemList => [
    bottomItem(PhosphorIconsBold.house, PhosphorIconsFill.house, '홈'),
    bottomItem(
        PhosphorIconsBold.filmStrip, PhosphorIconsFill.filmStrip, 'Feed'),
    bottomItem(PhosphorIconsBold.plus, PhosphorIconsBold.plus, '추가',
        special: true),
    bottomItem(
        PhosphorIconsBold.imagesSquare, PhosphorIconsFill.imagesSquare, '앨범'),
    bottomItem(
        PhosphorIconsBold.userCircle, PhosphorIconsFill.userCircle, '내정보'),
  ];
  // body Widget List
  //
  // ⚠️ 이 리스트는 `IndexedStack` 에 그대로 들어간다. IndexedStack 은 **보이지 않는 자식도
  // 전부 만든다** — 화면에 안 그릴 뿐이다. 그래서 무거운 탭은 처음엔 빈 위젯으로 두고
  // [onClick] 에서 처음 눌릴 때 진짜 화면을 끼워 넣는다(앨범·내정보가 원래 그 방식).
  //
  // Feed(1)도 같은 방식으로 바꿨다. 이전엔 즉시 생성이라 **홈 탭에 머물러 있는데도**
  // 앱을 켜자마자 영상 디코더 4개가 떴다(실측: 각 2.2~2.6초, 2026-09-04).
  // 목록 데이터는 `VideoListCntr.onInit()` 이 계속 미리 받아두므로 첫 진입 속도는 그대로다.
  late List<Widget> mainlist = [
    const WeathgergogoPage(),
    const SizedBox.shrink(), // Feed — 첫 진입 때 생성
    const SizedBox.shrink(),
    const SizedBox.shrink(),
    const SizedBox.shrink()
  ];

  @override
  void initState() {
    super.initState();

    Get.put(VideoListCntr());
    // 부트 시퀀스: 버전 확인(업데이트 안내 포함)이 끝난 뒤에 대기 업로드를 묻는다.
    // 다이얼로그가 겹치면 사용자가 업데이트 안내를 놓친다.
    checkAppVersion().whenComplete(_askPendingUploads);

    // 카메라 목록을 미리 열거해 두어 첫 촬영 화면 진입을 빠르게 한다(비동기).
    CameraUtils.warmUp();

    _prewarmFeed();
  }

  /// Feed 화면을 **날씨 렌더가 끝난 직후** 미리 만들어 둔다.
  ///
  /// 배경: Feed 는 영상 디코더를 물어야 해서 첫 진입에 시간이 걸린다
  /// (실측: 탭 후 첫 영상까지 2,154ms). 그래서 원래는 앱 시작과 동시에 만들어 그 대기를
  /// 시작 시간 뒤로 숨겼다. 다만 그러면 ①날씨 렌더와 자원을 다투고 ②안 볼 수도 있는 탭이
  /// 처음부터 디코더 4개를 물었다.
  ///
  /// 그래서 **시점만 옮긴다** — 미리 만드는 것은 유지하되, 홈이 다 그려진 뒤로 미룬다.
  /// 고정 지연(예: 3초)을 쓰지 않는 이유는 날씨가 빨리 끝나면 그만큼 놀고, 느리면 겹치기 때문이다.
  ///  ① `WeatherGogoCntr.isLoading` 이 false 로 떨어지는 순간 = 코어 날씨 렌더 완료 신호
  ///  ② 그 즉시가 아니라 **프레임이 한가할 때**(Priority.idle) 만든다 —
  ///     사용자가 홈을 스크롤 중이면 그게 끝난 뒤로 자동으로 밀린다.
  ///  ③ 날씨가 실패·지연돼도 결국 준비되도록 백스톱 타이머를 함께 건다.
  Worker? _feedPrewarmWorker;
  Timer? _feedPrewarmBackstop;

  void _prewarmFeed() {
    if (Get.isRegistered<WeatherGogoCntr>()) {
      final cntr = Get.find<WeatherGogoCntr>();
      if (!cntr.isLoading.value) {
        _schedulePrewarmWhenIdle(); // 이미 끝나 있으면 바로 예약
      } else {
        _feedPrewarmWorker = ever<bool>(cntr.isLoading, (loading) {
          if (!loading) _schedulePrewarmWhenIdle();
        });
      }
    }
    // 날씨가 끝나지 않아도(네트워크 실패 등) Feed 는 준비돼야 한다.
    _feedPrewarmBackstop =
        Timer(const Duration(seconds: 8), _schedulePrewarmWhenIdle);
  }

  void _schedulePrewarmWhenIdle() {
    if (!mounted || mainlist[1] is! SizedBox) return;
    // ⚠️ `scheduleTask(Priority.idle)` 은 쓰지 않는다. 홈 화면은 하늘 그라디언트·별 반짝임 등
    // 애니메이션이 계속 돌아 스케줄러가 "한가한" 상태가 되지 않고, 그러면 idle 작업이 굶어
    // 사전 생성이 아예 실행되지 않는다(2026-09-04 실측: 25초 대기해도 안 돎).
    //
    // 대신 다음 프레임이 그려진 뒤 + 짧은 여유를 두고 실행한다 — 날씨 렌더 프레임과 겹치지 않으면서
    // 실행은 보장된다.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        // 예약과 실행 사이에 사용자가 먼저 Feed 를 눌렀을 수 있다.
        if (!mounted || mainlist[1] is! SizedBox) return;
        setState(() => mainlist[1] = const VideoListPage());
        lo.g('Feed 사전 생성 완료(날씨 렌더 직후)');
      });
    });
  }

  @override
  void dispose() {
    _feedPrewarmWorker?.dispose();
    _feedPrewarmBackstop?.cancel();
    rootTimer.cancel(); // 1초 주기 타이머 — 여태 해제하는 곳이 없었다
    super.dispose();
  }

  /// 업데이트 안내 다이얼로그를 띄웠는지. 띄웠으면 그 위에 또 묻지 않는다.
  bool _updateDialogShown = false;

  /// 올리다 만 업로드가 있으면 이어서 올릴지 묻는다.
  ///
  /// 여기(RootPage.initState)에 붙인 이유:
  /// - `main.dart` 는 로그인 전에 돈다. 큐의 게시물을 올리려면 토큰이 필요하고,
  ///   `AppPages.INITIAL` 은 `/AuthPage` 라 거기서 물으면 로그인 화면 위에 뜬다.
  /// - RootPage 는 인증을 통과한 뒤 처음 서는 하단탭 메인 컨테이너이고, 이미
  ///   `checkAppVersion()` 같은 부트 시퀀스를 여기서 돌린다. 같은 자리에 잇는 게 맞다.
  Future<void> _askPendingUploads() async {
    if (_updateDialogShown) return;
    // 첫 프레임과 진입 애니메이션이 끝난 뒤에 띄운다.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await PendingUploadPrompt.showIfAny();
  }

  Future<void> checkAppVersion() async {
    // Android: 공식 In-App Update(Play Core) API로 판단·업데이트.
    // 스토어에 새 버전이 게시되면 스크래핑 없이 versionCode로 안정적으로 감지해 네이티브 업데이트 플로우를 띄운다.
    // (Play 스토어로 설치된 빌드에서만 동작 — 디버그/사이드로드는 예외로 조용히 무시)
    if (Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          // 네이티브 업데이트 UI가 뜬다 — 그 위에 대기 업로드를 묻지 않는다.
          _updateDialogShown = true;
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
        final String minVersion =
            resData.data['minVersion']?.toString() ?? '0.0.0';
        final bool force =
            (resData.data['forceUpdate']?.toString() ?? 'N') == 'Y';
        if (force &&
            currentVersion.isNotEmpty &&
            _compareVersion(currentVersion, minVersion)) {
          lo.g(
              'checkAppVersion: 백엔드 강제업데이트 (현재=$currentVersion, 최소=$minVersion)');
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
          appleId: AppConfig.appleId,
          playStoreId: AppConfig.playStoreId,
          country: 'kr');
      if (data.canUpdate == true) {
        if (kDebugMode) {
          Utils.alert("앱 최신버전으로 업데이트가 필요합니다.");
        } else if (mounted) {
          // 스크래핑이 URL을 못 채워주는 경우가 있어 공식 스토어 URL로 폴백을 보장한다.
          final String url =
              (data.storeUrl != null && data.storeUrl!.startsWith('http'))
                  ? data.storeUrl!
                  : _storeUrl();
          _updateDialogShown = true;
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
    _updateDialogShown = true;
    Utils.appUpdateAlert(context, _storeUrl());
  }

  onClick(index) {
    if (index == 2) {
      goRecord();
      return;
    }
    // 지연 생성은 [_ensureTabBuilt]가 build 경로에서 책임진다(아래 주석 참고).
    RootCntr.to.changeRootPageIndex(index);
    // 탭 전환 시 하단 플로팅 메뉴바는 항상 표시한다.
    // (이전: Feed 진입 시 add(index != 1)로 무조건 숨겨, 영상을 스와이프해야 다시 나오는 버그가 있었음)
    RootCntr.to.bottomBarStreamController.sink.add(true);
  }

  /// 지금 보여줄 탭의 화면을 아직 안 만들었으면 그때 만든다.
  ///
  /// **[onClick]이 아니라 build 경로에 두는 이유**: 탭은 하단바 말고도 바뀐다.
  ///  - `video_list_page.dart` 가 내정보(4)로,
  ///  - `app_route.dart` 의 딥링크가 앨범(3)으로
  /// `RootCntr.to.changeRootPageIndex()` 를 직접 부른다. 생성 로직이 onClick 에만 있으면
  /// 그 경로로 들어왔을 때 화면이 빈 채로 뜬다. 여기에 두면 어느 경로로 오든 안전하다.
  void _ensureTabBuilt(int index) {
    if (index < 0 || index >= mainlist.length) return;
    if (mainlist[index] is! SizedBox) return; // 이미 만들어 둠
    switch (index) {
      case 1:
        mainlist[1] = const VideoListPage();
        break;
      case 3:
        mainlist[3] = const AlbumListPage();
        break;
      case 4:
        mainlist[4] = const MyPage();
        break;
      default:
        break; // 2번(추가)은 화면이 아니라 카메라 모달이라 비워 둔다
    }
  }

  DateTime? currentBackPressTime = DateTime.now();

  //뒤로가기 로직(핸드폰 뒤로가기 버튼 클릭시)
  Future<void> onGoBack(didPop) async {
    lo.g('didPop : $didPop ');
    if (didPop) return;

    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!).inMilliseconds > 2000) {
      currentBackPressTime = now;
      Utils.alertIcon(
          '뒤로가기 버튼을 누르면 앱이 종료됩니다.', // Page No : ${RootCntr.to.rootPageIndex.value}',
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
              child: Obx(() {
                final int idx = RootCntr.to.rootPageIndex.value;
                // 보여줄 탭만 그 순간에 만든다(무거운 탭을 앱 시작에 안 물기 위해).
                _ensureTabBuilt(idx);
                return FadeIndexedStack(
                    index: idx, key: scaffoldKey, children: mainlist);
              }),
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
        floatingActionButtonLocation: Platform.isIOS
            ? FloatingActionButtonLocation.centerDocked
            : FloatingActionButtonLocation.centerFloat,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        // floatingActionButton: makeBottomItem(),
        bottomSheet: const Padding(padding: EdgeInsets.only(bottom: 0.0)),

        floatingActionButton:
            Obx(() => HideBottomBar(childWdiget: makeBottomItem())),
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

  /// 하단탭 아이템 — [icon]=비선택(Bold), [activeIcon]=선택(Fill).
  /// [special]이면 가운데 "추가" 탭처럼 항상 민트 단색 원 배지로 그린다.
  BottomNavigationBarItem bottomItem(
      IconData icon, IconData activeIcon, String label,
      {bool special = false}) {
    if (special) {
      final Widget badge = _addTabBadge();
      return BottomNavigationBarItem(
          icon: badge, label: label, activeIcon: badge);
    }
    // 영상 피드 위에서만 어두운 바를 쓰고, 일반 화면은 밝은 바를 유지한다.
    bool onDarkBar() {
      final index = RootCntr.to.rootPageIndex.value;
      return index == 1;
    }

    return BottomNavigationBarItem(
      icon: Obx(() => PhosphorIcon(
            icon,
            // 어두운 필 위: 또렷한 흰색, 낮의 밝은 필 위: 짙은 보조색
            color: onDarkBar()
                ? Colors.white.withValues(alpha: 0.85)
                : SaColorsLight.textSecondary,
          )),
      label: label,
      // 선택 아이콘도 바에 맞춰: 어두운 필엔 흰색, 밝은 필엔 브랜드 민트
      activeIcon: Obx(() => PhosphorIcon(
            activeIcon,
            color: onDarkBar() ? Colors.white : SaColorsLight.accentTeal,
          )),
    );
  }

  /// 가운데 "추가"(카메라) 탭 — 민트 단색 원 배지. 탭해도 currentIndex는 바뀌지
  /// 않고 카메라를 모달로 띄우므로(onClick의 index==2 분기) 선택 상태를 그리지 않는다.
  Widget _addTabBadge() {
    // 앨범 탭의 검색·QR 버튼과 같은 흰 원 + 회색 아이콘 + 얇은 테두리.
    // 포인트색 원은 다른 탭 아이콘 사이에서 혼자 튀었다(2026-09-05, 사용자 요청).
    // 어두운 바(하늘·영상) 위에서도 흰 원이라 그대로 보인다.
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SaColorsLight.surface,
        border: Border.all(color: SaColorsLight.borderStrong, width: 1),
      ),
      child: const PhosphorIcon(PhosphorIconsBold.plus,
          size: 18, color: SaColorsLight.textSecondary),
    );
  }

  Widget makeBottomItem() {
    final bool onVideo = RootCntr.to.rootPageIndex.value == 1;
    final radius = BorderRadius.circular(20);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: onVideo
            ? SaColorsDark.surface.withValues(alpha: 0.72)
            : SaColorsLight.surface,
        borderRadius: radius,
        border: Border.all(
          color: onVideo
              ? Colors.white.withValues(alpha: 0.22)
              : SaColorsLight.border,
        ),
        boxShadow: onVideo ? null : [
          BoxShadow(
            color: SaColorsLight.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: RootCntr.to.rootPageIndex.value,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            iconSize: 22,
            onTap: onClick,
            selectedIconTheme: const IconThemeData(size: 24),
            selectedFontSize: 13,
            selectedItemColor: onVideo ? Colors.white : SaColorsLight.accentTeal,
            unselectedFontSize: 11,
            unselectedItemColor: onVideo
                ? Colors.white.withValues(alpha: 0.85)
                : SaColorsLight.textTertiary,
            unselectedIconTheme: const IconThemeData(size: 22),
            items: bottomItemList,
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
          color: Colors.black.withValues(alpha: 0.7),
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
