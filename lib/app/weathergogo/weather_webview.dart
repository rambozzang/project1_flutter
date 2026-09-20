import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/webview/common_webview.dart';
import 'package:visibility_detector/visibility_detector.dart';

class WeatherWEbviewPage extends StatelessWidget {
  const WeatherWEbviewPage({super.key});

  // 대기 흐름(earth.nullschool) — 레이더 패널과 동일 구조(지연 로드 + 터치 토글 + 전체화면).
  // 레이더처럼 2초 지연 로드해 초기 페이지 렌더 부담을 줄인다(그 전엔 스피너).
  static const String _url =
      'https://earth.nullschool.net/#current/wind/surface/level/orthographic=126.12,37.16,1280/loc=127.030,37.221';

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _RadarPanel(title: '대기 흐름', url: _url, icon: Icons.air),
        Gap(40),
      ],
    );
  }
}

/// 실시간 대기정보 — 국가대기질정보(NIER) 위성 GIS 사이트를 임베드.
/// "대기 흐름"과 동일 레이아웃이되, 페이지 초기화 2초 후 비동기로 웹뷰를 로딩해
/// 초기 렌더 부담을 줄인다(그 전에는 로딩 인디케이터 표시).
class RealtimeAirWebviewPage extends StatefulWidget {
  const RealtimeAirWebviewPage({super.key});

  @override
  State<RealtimeAirWebviewPage> createState() => _RealtimeAirWebviewPageState();
}

class _RealtimeAirWebviewPageState extends State<RealtimeAirWebviewPage> {
  static const String _url =
      'https://nesc.nier.go.kr/ko/html/satellite/gis/index.do';
  bool _showWeb = false;

  @override
  void initState() {
    super.initState();
    // 페이지 초기화 후 2초 뒤에 외부 웹뷰를 비동기로 로딩
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showWeb = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Row(
            children: [
              Icon(Icons.satellite_alt, color: Colors.white),
              SizedBox(width: 4.0),
              Text(
                '실시간 대기정보',
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              Spacer(),
            ],
          ),
          const Gap(15),
          SizedBox(
            height: 600,
            child: _showWeb
                ? const CommonWebView(
                    isBackBtn: false,
                    url: _url,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                  ),
          ),
          const Gap(10),
          if (_showWeb)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                minimumSize: const Size(50, 22),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AirInfoFullPage(
                          title: '실시간 대기정보',
                          url: _url,
                        )),
              ),
              child:
                  Text('전체화면으로 ', style: semiboldText.copyWith(fontSize: 11.0)),
            ),
          const Gap(40)
        ],
      ),
    );
  }
}

/// 실시간 레이더 비교 — RainViewer(임베드용 map.html) + 기상청(KMA) 레이더를 세로로 나란히.
/// 두 소스를 한 화면에서 비교하려고 각각 독립 WebView 패널로 렌더한다.
class RealtimeRadarPage extends StatelessWidget {
  const RealtimeRadarPage({super.key});

  // RainViewer 임베드 전용 지도(경량·프레임 허용). loc=위도,경도,줌 으로 한국 중심·축소(줌 4).
  // 컨트롤 표시: oAP=재생/일시정지, oF=전체화면, oCS=범례, oC=커버리지 / c=색상, o=불투명도, sm=부드러운전환.
  // ts=1 → 라이트 모드 강제(미지정 시 기기 prefers-color-scheme를 따라 다크폰에선 다크가 됨).
  // (기본값은 컨트롤이 꺼져 있어 각 토글을 1로 켠다.) 현재위치 요청은 denyLocation으로 자동 거부.
  /// 전체화면 뷰어도 같은 URL 을 쓴다.
  static const String rainviewerUrl =
      'https://www.rainviewer.com/map.html?loc=36.5,127.8,4&oAP=1&oF=1&oCS=1&oC=1&c=3&o=83&sm=1&ts=1';

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _RadarPanel(
          title: '실시간 레이더',
          url: rainviewerUrl,
          denyLocation: true,
          touchToggleBelow: true,
          loadDelay: Duration(seconds: 2),
        ),
        Gap(40),
      ],
    );
  }
}

/// 실시간 위성영상 — Zoom Earth 위성 지도를 한국 인근 중심으로 표시한다.
/// 첫 로드 때 나타나는 앱 안내 레이어는 [CommonWebView]의 JS 주입으로 자동 닫는다.
class RealtimeSatellitePage extends StatelessWidget {
  const RealtimeSatellitePage({super.key});

  // URL의 날짜와 시각은 기기 시간대와 무관하게 한국 표준시(UTC+9)의 현재 값을 사용한다.
  /// 전체화면 뷰어도 같은 URL 을 쓴다. 현재 시각이 들어가므로 매번 새로 만든다.
  /// 안내 레이어 닫기 + 타임랩스 자동재생. 전체화면 뷰어도 같은 것을 쓴다.
  static String get viewerInjectJs => '$_dismissContinuePopupJs\n$_autoPlayJs';

  static String get satelliteUrl {
    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final year = nowKst.year.toString().padLeft(4, '0');
    final month = nowKst.month.toString().padLeft(2, '0');
    final day = nowKst.day.toString().padLeft(2, '0');
    final hour = nowKst.hour.toString().padLeft(2, '0');
    final minute = nowKst.minute.toString().padLeft(2, '0');
    return 'https://zoom.earth/maps/satellite/#view=34.086,126.899,6z/date=$year-$month-$day,$hour:$minute,+9';
  }

  // 안내 레이어가 비동기로 나타날 수 있어 DOM 변경과 짧은 폴링을 함께 감시한다.
  // 앱 다운로드 요소는 건드리지 않고 "Continue/계속" 버튼만 클릭한다.
  static const String _dismissContinuePopupJs = r'''
(() => {
  if (window.__skySnapDismissZoomEarthOverlaysV2) return;
  window.__skySnapDismissZoomEarthOverlaysV2 = true;

  const appLinkStyle = document.createElement('style');
  appLinkStyle.textContent = '.panel.id-app-link { display: none !important; }';
  (document.head || document.documentElement).appendChild(appLinkStyle);

  const labels = new Set(['continue', '계속']);
  const dismiss = () => {
    const candidates = document.querySelectorAll(
      'button, [role="button"], input[type="button"], input[type="submit"]'
    );
    for (const element of candidates) {
      const label = (element.innerText || element.textContent || element.value || '')
        .trim()
        .toLocaleLowerCase();
      if (labels.has(label)) {
        element.click();
        return true;
      }
    }

    // Zoom Earth 앱 다운로드 패널의 닫기 버튼만 정확히 클릭한다.
    const appDownloadPanel = document.querySelector('.panel.id-app-link');
    if (appDownloadPanel) {
      const appDownloadClose = appDownloadPanel.querySelector('button.close');
      if (appDownloadClose) appDownloadClose.click();
      // 사이트의 클릭 핸들러가 동작하지 않는 WebView에서도 확실히 보이지 않게 한다.
      appDownloadPanel.style.setProperty('display', 'none', 'important');
      appDownloadPanel.setAttribute('aria-hidden', 'true');
      return true;
    }
    return false;
  };

  // 첫 번째 레이어를 닫은 뒤 앱 다운로드 레이어가 연이어 나타날 수 있으므로
  // 성공해도 즉시 종료하지 않고 제한 시간 동안 계속 감시한다.
  dismiss();
  const observer = new MutationObserver(dismiss);
  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
    characterData: true,
  });

  let attempts = 0;
  const timer = setInterval(() => {
    attempts += 1;
    dismiss();
    if (attempts >= 120) {
      clearInterval(timer);
      // 폴링만 중단하고 DOM 감시는 유지해 나중에 다시 나타나는 레이어도 처리한다.
    }
  }, 500);
})();
''';

  // 로드 완료 후 타임랩스 애니메이션을 자동 재생한다.
  // 재생 버튼은 재생 중이면 aria-label이 '일시정지'로 바뀌므로, '재생' 상태일 때만 한 번 누른다.
  // 타임라인이 비동기로 붙을 수 있어 짧게 폴링하고, 한 번 눌렀으면 즉시 종료한다(사용자가 다시 멈추면 재개하지 않음).
  static const String _autoPlayJs = r'''
(() => {
  if (window.__skySnapAutoPlaySatellite) return;
  window.__skySnapAutoPlaySatellite = true;

  let started = false;
  const clickPlay = () => {
    if (started) return true;
    const playBtn = document.querySelector('button.play[aria-label*="재생"]');
    if (playBtn) {
      playBtn.click();
      started = true;
      return true;
    }
    return false;
  };

  clickPlay();
  let attempts = 0;
  const timer = setInterval(() => {
    attempts += 1;
    if (clickPlay() || attempts >= 40) clearInterval(timer);
  }, 500);
})();
''';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RadarPanel(
          title: '실시간 위성영상',
          url: satelliteUrl,
          icon: Icons.satellite_alt,
          // 팝업 자동 닫기 + 타임랩스 자동 재생을 함께 주입한다.
          injectJs: viewerInjectJs,
          touchToggleBelow: true,
          loadDelay: const Duration(seconds: 4),
        ),
        const Gap(40),
      ],
    );
  }
}

/// 레이더 패널 한 개 — 제목 + 600px WebView + 전체화면 버튼.
/// 웹뷰는 패널 생성 후 loadDelay 뒤에 로드한다(페이지 오픈 직후 동시 로드 스파이크 완화).
/// 로드 전엔 스피너를 보인다.
class _RadarPanel extends StatefulWidget {
  final String title;
  final String url;
  final bool denyLocation; // true면 웹 위치권한 프롬프트 자동 거부.
  final IconData icon; // 헤더 아이콘(레이더/대기흐름 등)
  final String? injectJs; // 페이지 로드 완료 후 실행할 선택적 JS.
  final bool touchToggleBelow; // 지도 조작 버튼을 WebView 아래에 표시.
  final Duration loadDelay; // 패널 생성 후 웹뷰 로드까지의 지연 시간.
  const _RadarPanel(
      {required this.title,
      required this.url,
      this.denyLocation = false,
      this.icon = Icons.radar,
      this.injectJs,
      this.touchToggleBelow = false,
      this.loadDelay = const Duration(seconds: 2)});

  @override
  State<_RadarPanel> createState() => _RadarPanelState();
}

class _RadarPanelState extends State<_RadarPanel> {
  bool _showWeb = false;
  ValueNotifier<bool>? _externalTouchEnabled;

  @override
  void initState() {
    super.initState();
    if (widget.touchToggleBelow) {
      _externalTouchEnabled = ValueNotifier<bool>(false);
    }
    // 스크롤 진입을 기다리지 않고, 패널 생성 후 일정 시간 뒤에 웹뷰를 로드한다.
    // 부모 ListView의 cacheExtent(5000) 덕에 이 패널은 페이지 오픈 직후 만들어지므로
    // 타이머는 사실상 페이지 오픈 기준으로 동작하고, 사용자가 아래로 스크롤할 때쯤엔 로드가 끝나 있다.
    // (한번 로드하면 keepAlive로 유지돼 스크롤 시 깜빡임이 없다.)
    Future.delayed(widget.loadDelay, () {
      if (mounted) setState(() => _showWeb = true);
    });
  }

  @override
  void dispose() {
    _externalTouchEnabled?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 4.0),
              Text(
                widget.title,
                style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
            ],
          ),
          const Gap(15),
          SizedBox(
            height: 600,
            child: _showWeb
                ? CommonWebView(
                    isBackBtn: false,
                    url: widget.url,
                    denyLocation: widget.denyLocation,
                    injectJs: widget.injectJs,
                    touchToggle: true, // 기본 스크롤 통과, 하단 버튼으로 조작 on/off
                    externalTouchEnabled: _externalTouchEnabled,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                  ),
          ),
          if (_showWeb && _externalTouchEnabled != null) ...[
            const Gap(10),
            Center(child: _buildExternalTouchButton()),
          ],
          const Gap(10),
          if (_showWeb)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                minimumSize: const Size(50, 22),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => AirInfoFullPage(
                          title: widget.title,
                          url: widget.url,
                          injectJs: widget.injectJs,
                          denyLocation: widget.denyLocation,
                        )),
              ),
              child:
                  Text('전체화면으로 ', style: semiboldText.copyWith(fontSize: 11.0)),
            ),
        ],
      ),
    );
  }

  Widget _buildExternalTouchButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _externalTouchEnabled!,
      builder: (context, enabled, child) {
        return GestureDetector(
          onTap: () => _externalTouchEnabled!.value = !enabled,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: (enabled ? Colors.teal.shade600 : Colors.black).withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(enabled ? Icons.lock_open_rounded : Icons.touch_app, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  enabled ? '조작 켜짐 · 탭하여 잠금' : '지도 조작하기 (탭)',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 넓은 위성 GIS 지도를 크게 보도록 가로 보기를 허용하고, 나가면 세로 고정으로 복귀한다.
/// 대기정보 전체화면 보기 — 타이틀 바 + 웹뷰 전체.
/// 넓은 위성 GIS 지도를 크게 보도록 가로 보기를 허용하고, 나가면 세로 고정으로 복귀한다.
class AirInfoFullPage extends StatefulWidget {
  final String title;
  final String url;
  final String? injectJs;
  final bool denyLocation;
  const AirInfoFullPage(
      {super.key,
      required this.title,
      required this.url,
      this.injectJs,
      this.denyLocation = false});

  @override
  State<AirInfoFullPage> createState() => _AirInfoFullPageState();
}

class _AirInfoFullPageState extends State<AirInfoFullPage> {
  @override
  void initState() {
    super.initState();
    // 위성 지도는 가로가 넓어 가로 보기 허용(전역 세로고정 일시 해제)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // 나갈 때 다시 세로 고정으로 복귀
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: CommonWebView(
            isBackBtn: false,
            url: widget.url,
            injectJs: widget.injectJs,
            denyLocation: widget.denyLocation),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 지도를 **열었을 때만** 만든다
//
// 예전에는 레이더·위성 지도를 날씨 페이지 안에 상시 붙여 두었다. 날씨 화면은
// `FadeIndexedStack` 안이라 앱이 끝날 때까지 살아 있고, 한 번 스크롤해 내려가
// 웹뷰가 뜨면 **Feed 를 보든 앨범을 보든 지도는 계속 돌았다** — 실측으로
// 크로미움 스레드가 CPU 14% 를 계속 먹었다(2026-09-20, SM-N976N, 프로파일 빌드).
//
// ⚠️ 떠 있는 웹뷰를 JS 로 재우는 것은 **실패했다.** `requestAnimationFrame` 을
// 끊으면 13.9% → 27.3%, 1초로 늦추면 21.6% 로 **오히려 올랐다.** 지도
// 라이브러리는 콜백이 제때 안 오면 루프가 끝난 줄 알고 계속 다시 요청한다.
// 그래서 재우는 게 아니라 **안 만드는** 쪽으로 간다 — 안 만들면 크로미움
// 프로세스 자체가 안 뜬다.
//
// 사용자 불편을 줄이려고 두 가지를 같이 한다:
//  1. 원래 있던 자리(스크롤 하단)에 **같은 제목의 카드**를 남긴다 — 찾던 곳에서
//     그대로 찾을 수 있다.
//  2. 상단 검색줄에도 바로 가는 버튼을 둔다 — 스크롤 없이 한 번에 연다.
//
// 덤으로 조작이 나아진다. 페이지 안에 박힌 지도는 스크롤과 싸워서 '지도 조작하기'
// 토글을 눌러야 움직였는데, 전체화면에서는 그 단계가 필요 없다.
// ─────────────────────────────────────────────────────────────────────────────

/// 지도 한 장을 전체화면으로 연다. 이 화면을 닫으면 웹뷰도 함께 사라진다.
class WeatherMapViewerPage extends StatelessWidget {
  const WeatherMapViewerPage({
    super.key,
    required this.title,
    required this.url,
    this.injectJs,
    this.denyLocation = false,
    this.radarEcho = false,
  });

  final String title;
  final String url;
  final String? injectJs;
  final bool denyLocation;
  final bool radarEcho;

  /// 실시간 레이더(RainViewer).
  static void openRadar() => Get.to(
        () => WeatherMapViewerPage(
          title: '실시간 레이더',
          url: RealtimeRadarPage.rainviewerUrl,
          denyLocation: true,
          radarEcho: true,
        ),
        transition: Transition.cupertino,
      );

  /// 실시간 위성영상(Zoom Earth). URL 에 현재 시각이 들어가므로 열 때 만든다.
  static void openSatellite() => Get.to(
        () => WeatherMapViewerPage(
          title: '실시간 위성영상',
          url: RealtimeSatellitePage.satelliteUrl,
          injectJs: RealtimeSatellitePage.viewerInjectJs,
        ),
        transition: Transition.cupertino,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      // touchToggle 을 주지 않는다 — 전체화면에서는 스크롤과 싸울 일이 없어서
      // '지도 조작하기' 를 누르지 않고 바로 줌·이동할 수 있다.
      body: CommonWebView(
        isBackBtn: false,
        url: url,
        injectJs: injectJs,
        denyLocation: denyLocation,
        // 카드에서 보던 그림을 그대로 깔아 화면이 이어져 보이게 한다.
        loadingBackground: WeatherMapPreview(radarEcho: radarEcho),
      ),
    );
  }
}

/// 날씨 페이지 하단에 남는 **진입 섹션**. 웹뷰를 만들지 않는다.
///
/// 줄 하나짜리 메뉴로 뒀더니 "눌러서 들어갈 것 같지 않다"는 지적을 받았고
/// (2026-09-20), 넓은 배너 두 장을 세로로 쌓았더니 같은 사진이 두 번 반복돼
/// 광고처럼 보였다. 그래서 **한 섹션에 반폭 타일 두 개**로 둔다 — 이웃한
/// '일출 · 일몰' 과 같은 헤더 문법을 쓰고, 타일마다 얼굴이 다르다
/// (레이더는 채도를 뺀 지도 + 거리 원·스윕·에코, 위성은 구름 사진 그대로).
///
/// ⚠️ 타일의 그림은 **실시간 데이터가 아니다.** 헤더 오른쪽에 '탭하면 실시간
/// 지도가 열려요' 를 적어 두는 이유다 — 미리보기를 실제 관측으로 오해하면
/// 안 된다. 실시간을 그대로 쓰려면 웹뷰를 띄워야 하는데, 그게 바로 없애려던
/// 비용이다.
class WeatherMapEntrySection extends StatelessWidget {
  const WeatherMapEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 이웃 섹션(SunTimesView)과 같은 좌우 8, 위 14.
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.mapTrifold,
                    color: Colors.white, size: 20),
                SizedBox(width: 5),
                Text('실시간 지도',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Spacer(),
                // 미리보기임을 한 번만, 섹션 단위로 밝힌다.
                Text('탭하면 실시간 지도가 열려요',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: -0.1)),
              ],
            ),
          ),
          const Gap(8),
          SizedBox(
            height: 152,
            child: Row(
              children: [
                Expanded(
                  child: _MapTile(
                    title: '실시간 레이더',
                    desc: '비구름이 어디로 가는지',
                    radarEcho: true,
                    onTap: WeatherMapViewerPage.openRadar,
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: _MapTile(
                    title: '실시간 위성영상',
                    desc: '구름 흐름을 타임랩스로',
                    onTap: WeatherMapViewerPage.openSatellite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 타일 한 장 — 지도 미리보기 + 글자 아래만 짧게 깐 스크림 + 열기 화살표.
///
/// 그림은 **덮지 않는다.** 두 번 실패한 자리다(2026-09-20): 검정 0.72 를
/// 전체에 깔았더니 카드가 먹빛으로 가라앉았고, 흰색으로 뒤집었더니 지도가
/// 빛바래고 채도 높은 버튼만 튀어 촌스러웠다. 스크림은 **글자가 있는
/// 아래쪽 절반에만**, 검정이 아니라 하늘 남색 계열로 깐다.
///
/// **움직임은 화면에 보일 때만 돈다.** 날씨 홈은 IndexedStack 안에 살아
/// 있어서, 가시성으로 막지 않으면 Feed 를 보는 동안에도 두 타일이 계속
/// 그려진다 — 웹뷰가 CPU 14% 를 먹던 것과 같은 함정이다. 시스템의
/// '동작 줄이기' 가 켜져 있으면 아예 돌리지 않는다.
class _MapTile extends StatefulWidget {
  const _MapTile({
    required this.title,
    required this.desc,
    required this.onTap,
    this.radarEcho = false,
  });

  final String title;
  final String desc;
  final VoidCallback onTap;
  final bool radarEcho;

  @override
  State<_MapTile> createState() => _MapTileState();
}

class _MapTileState extends State<_MapTile>
    with SingleTickerProviderStateMixin {
  // 레이더는 스윕이 한 방향으로 돌고(7초에 한 바퀴), 위성은 아주 느리게
  // 당겼다 놓는다(18초 왕복). 둘 다 "살아 있다" 정도만 느껴지는 속도다.
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.radarEcho ? 7 : 18),
  );
  bool _visible = false;

  void _syncMotion() {
    if (!mounted) return;
    final bool allowed = _visible && !MediaQuery.disableAnimationsOf(context);
    if (allowed) {
      if (!_motion.isAnimating) {
        _motion.repeat(reverse: !widget.radarEcho);
      }
    } else if (_motion.isAnimating) {
      _motion.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion(); // '동작 줄이기' 가 바뀌면 여기로 온다.
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('weather-map-tile-${widget.radarEcho ? 'radar' : 'satellite'}'),
      onVisibilityChanged: (info) {
        _visible = info.visibleFraction > 0.1;
        _syncMotion();
      },
      child: _PressScale(
        onTap: widget.onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          // 이웃 카드와 같은 옅은 흰 테두리 — 사진 가장자리가 배경에 녹지 않게.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              WeatherMapPreview(radarEcho: widget.radarEcho, motion: _motion),

              // 글자 자리만 눌러 준다. 0.55 위로는 손대지 않는다.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF071523).withValues(alpha: 0.78),
                        const Color(0xFF071523).withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.58],
                    ),
                  ),
                ),
              ),

              // 열기 화살표 — '열기' 글자 대신 오른쪽 위 화살표로 "들어간다"를 알린다.
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.42),
                        width: 0.8),
                  ),
                  child: const Center(
                    child: PhosphorIcon(PhosphorIconsBold.arrowUpRight,
                        size: 13, color: Colors.white),
                  ),
                ),
              ),

              Positioned(
                left: 12,
                right: 12,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.15,
                            letterSpacing: -0.2,
                            fontWeight: FontWeight.w700)),
                    const Gap(3),
                    Text(widget.desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.15,
                            fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 누르는 동안 살짝 눌리는 반응. 사진 타일은 버튼처럼 색이 바뀌지 않아서
/// 이 반응이 없으면 눌렀는지 알 수 없다.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// 타일과 로딩 배경이 함께 쓰는 **지도 미리보기 그림.**
/// 실시간 데이터가 아니라 "여기가 어떤 화면인지" 알리는 그림이다.
///
/// [motion] 을 주면 살아 움직인다(레이더: 스윕 회전 + 에코 표류, 위성: 느린 줌).
/// 비싼 그림(사진, 블러 에코)은 [RepaintBoundary] 로 한 번만 래스터하고
/// 프레임마다 옮기거나 키우기만 한다 — 매 프레임 블러를 다시 그리면 안 된다.
class WeatherMapPreview extends StatelessWidget {
  const WeatherMapPreview({super.key, this.radarEcho = false, this.motion});

  final bool radarEcho;
  final Animation<double>? motion;

  @override
  Widget build(BuildContext context) {
    final Widget earth =
        const RepaintBoundary(child: _EarthCrop(degreesWide: 46));
    if (!radarEcho) {
      final Animation<double>? m = motion;
      if (m == null) return earth;
      // 켄 번즈 — 1.00 ↔ 1.06 을 18초에 왕복. 한반도가 중앙이라 줌 중심을
      // 따로 잡지 않아도 된다.
      return AnimatedBuilder(
        animation: m,
        builder: (context, child) => Transform.scale(
          scale: 1.0 + 0.06 * Curves.easeInOutSine.transform(m.value),
          child: child,
        ),
        child: earth,
      );
    }

    // 레이더는 위성과 한눈에 구분돼야 한다. 사진의 **색조만** 청색으로 옮긴다
    // (hue 블렌드 — 밝기와 질감은 사진 그대로). 레이더 앱의 단색 베이스맵처럼
    // 보이고, 그 위에서 에코(초록·노랑·주황·빨강)가 보색으로 또렷이 뜬다.
    //
    // 세 번 실패한 자리다(2026-09-20): 남색으로 어둡게 누르면 밤 화면 같고,
    // 채도를 빼면 잿빛으로 가라앉고, 하늘색을 얹으면 빛바랜다. 밝기를 건드리지
    // 않는 것이 답이었다.
    const Widget echoes =
        RepaintBoundary(child: CustomPaint(painter: _RadarEchoPainter()));
    final Animation<double>? m = motion;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter:
              const ColorFilter.mode(Color(0xFF3B8FD1), BlendMode.hue),
          child: earth,
        ),
        const RepaintBoundary(
            child: CustomPaint(painter: _RadarGridPainter())),
        if (m == null)
          echoes
        else
          // 비구름이 아주 조금 흐른다(±3px). 캐시된 층을 옮기기만 한다.
          AnimatedBuilder(
            animation: m,
            builder: (context, child) {
              final double a = 2 * math.pi * m.value;
              return Transform.translate(
                offset: Offset(3.0 * math.sin(a), 1.5 * math.sin(a + 1.3)),
                child: child,
              );
            },
            child: echoes,
          ),
        if (m == null)
          const CustomPaint(painter: _RadarSweepPainter(_RadarSweepPainter.rest))
        else
          AnimatedBuilder(
            animation: m,
            builder: (context, _) => CustomPaint(
                painter: _RadarSweepPainter(2 * math.pi * m.value)),
          ),
      ],
    );
  }
}

/// 동아시아를 잘라 둔 지구 사진에서 **한반도를 중앙에** 오도록 보여 준다.
///
/// 에셋은 NASA Blue Marble(구름 포함, 8192×4096)에서 경도 96–160°E,
/// 위도 8–58°N 만 잘라 낸 것이다. 세계지도 1024×512 를 쓰던 때는 46° 를
/// 131px 에서 늘려 그려 흐렸다(2026-09-20). 지금은 타일 폭에 1,456px 중
/// 1,047px 이 들어와 기기 해상도(3x, ≈550px)보다 촘촘하다.
///
/// ⚠️ `BoxFit.cover` + `alignment` 만으로는 원하는 지역이 안 잡힌다 — 상자
/// 비율에 따라 잘리는 축이 바뀐다. 그래서 크기를 **직접 계산한다.**
/// [degreesWide] 만큼의 경도가 가로에 들어오게 배율을 정하고, 한반도가 상자
/// 중앙에 오는 alignment 를 푼다. 상자가 그보다 크면(전체화면 로딩 배경)
/// 빈 곳이 생기지 않게 배율을 낮춰 채운다.
class _EarthCrop extends StatelessWidget {
  const _EarthCrop({required this.degreesWide});

  /// 가로에 들어올 경도 범위(도). 타일은 46 — 중국 동해안부터 일본까지.
  final double degreesWide;

  static const String _asset = 'assets/images/earth_east_asia.jpg';
  static const double _imgW = 1456, _imgH = 1138;
  static const double _lonMin = 96, _lonMax = 160, _latMax = 58;
  static const double _pxPerDeg = _imgW / (_lonMax - _lonMin);

  /// 원본 픽셀 좌표의 한반도(127.5°E, 36.5°N).
  static const Offset _korea =
      Offset((127.5 - _lonMin) * _pxPerDeg, (_latMax - 36.5) * _pxPerDeg);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final double w = c.maxWidth, h = c.maxHeight;
      // 이미지 픽셀 / 논리 픽셀. 작을수록 크게 보인다. 상자를 못 채우면 낮춘다.
      final double scale = math.min(
          degreesWide * _pxPerDeg / w, math.min(_imgW / w, _imgH / h));
      final double imgW = _imgW / scale, imgH = _imgH / scale;
      final double kx = _korea.dx / scale, ky = _korea.dy / scale;
      // RenderImage 는 (box - image) 의 (a+1)/2 지점에 이미지를 놓는다.
      // 한반도가 상자 중앙에 오도록 a 를 푼다. 상자가 이미지보다 크면 0.
      double solve(double box, double img, double k) {
        final double d = box - img;
        if (d.abs() < 1e-6) return 0;
        return (2 * (box / 2 - k) / d - 1).clamp(-1.0, 1.0);
      }

      return Image.asset(
        _asset,
        fit: BoxFit.none,
        scale: scale,
        alignment: Alignment(solve(w, imgW, kx), solve(h, imgH, ky)),
        filterQuality: FilterQuality.medium,
      );
    });
  }
}

/// 레이더 눈금 — 거리 원 3개와 십자선. 청색 바탕이라 흰 선이 눈금처럼 읽힌다.
class _RadarGridPainter extends CustomPainter {
  const _RadarGridPainter();

  static List<double> radii(Size size) =>
      [0.24, 0.44, 0.64].map((r) => size.shortestSide * r).toList();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final List<double> rs = radii(size);
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.38);
    for (final r in rs) {
      canvas.drawCircle(center, r, ring);
    }
    final Paint cross = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.20);
    canvas.drawLine(Offset(center.dx - rs.last, center.dy),
        Offset(center.dx + rs.last, center.dy), cross);
    canvas.drawLine(Offset(center.dx, center.dy - rs.last),
        Offset(center.dx, center.dy + rs.last), cross);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 비구름 에코 — 약한 비(초록) → 강한 비(노랑·주황·빨강) 순으로 겹친다.
/// 실제 관측이 아니라 "이게 레이더 화면"임을 알리는 그림이다.
/// 블러가 비싸므로 한 번만 그리고(RepaintBoundary) 움직임은 밖에서 옮긴다.
class _RadarEchoPainter extends CustomPainter {
  const _RadarEchoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.shortestSide;
    void echo(double fx, double fy, double fr, Color c, double a) {
      canvas.drawCircle(
        Offset(size.width * fx, size.height * fy),
        unit * fr,
        Paint()
          ..color = c.withValues(alpha: a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    echo(0.34, 0.42, 0.15, const Color(0xFF22C55E), 0.85);
    echo(0.41, 0.33, 0.10, const Color(0xFFFACC15), 0.85);
    echo(0.45, 0.30, 0.05, const Color(0xFFF97316), 0.80);
    echo(0.63, 0.55, 0.12, const Color(0xFF22C55E), 0.80);
    echo(0.67, 0.50, 0.06, const Color(0xFFEF4444), 0.75);
    echo(0.52, 0.66, 0.09, const Color(0xFF22C55E), 0.60);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 스윕 — 레이더를 레이더답게 만드는 한 조각. 앞날 뒤 70° 를 옅은 민트로
/// 밝히고 앞날은 선으로 긋는다. [angle] 은 앞날의 각(시계 방향, 라디안).
///
/// ⚠️ SweepGradient 의 각은 반드시 [0, 2π) 안에서 준다. 음수 각을 넘겼더니
/// 전 구간을 범위 밖으로 보고 끝 색으로 채워 그라데이션 없는 부채꼴 판이
/// 찍혔다(2026-09-20). 그래서 캔버스를 돌리고 고정된 각으로 그린다.
class _RadarSweepPainter extends CustomPainter {
  const _RadarSweepPainter(this.angle);

  /// 움직이지 않을 때(로딩 배경) 앞날을 둘 각 — 2시 방향.
  static const double rest = -0.35;

  final double angle;

  static const Color _mint = Color(0xFF5EEAD4);
  static const double _arc = 1.22; // ≈70°

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double r = _RadarGridPainter.radii(size).last;
    // 캔버스를 돌려 앞날이 항상 3시(0 rad)에 오게 한다 — 그라데이션 각이
    // 고정되므로 위 함정을 피한다.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final Rect rect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawArc(
      rect,
      2 * math.pi - _arc,
      _arc,
      true,
      Paint()
        ..shader = SweepGradient(
          startAngle: 2 * math.pi - _arc,
          endAngle: 2 * math.pi,
          colors: [
            _mint.withValues(alpha: 0.0),
            _mint.withValues(alpha: 0.30),
          ],
        ).createShader(rect),
    );
    canvas.drawLine(
      Offset.zero,
      Offset(r, 0),
      Paint()
        ..strokeWidth = 1.4
        ..color = _mint.withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
