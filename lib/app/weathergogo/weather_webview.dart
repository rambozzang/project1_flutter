import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/webview/common_webview.dart';

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
  static const String _rainviewerUrl =
      'https://www.rainviewer.com/map.html?loc=36.5,127.8,4&oAP=1&oF=1&oCS=1&oC=1&c=3&o=83&sm=1&ts=1';

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _RadarPanel(
          title: '실시간 레이더',
          url: _rainviewerUrl,
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
  static String get _url {
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
          url: _url,
          icon: Icons.satellite_alt,
          // 팝업 자동 닫기 + 타임랩스 자동 재생을 함께 주입한다.
          injectJs: '$_dismissContinuePopupJs\n$_autoPlayJs',
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
