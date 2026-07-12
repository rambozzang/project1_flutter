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
  static const String _url = 'https://nesc.nier.go.kr/ko/html/satellite/gis/index.do';
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
                style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
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
              child: Text('전체화면으로 ', style: semiboldText.copyWith(fontSize: 11.0)),
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
        _RadarPanel(title: '실시간 레이더', url: _rainviewerUrl, denyLocation: true),
        Gap(40),
      ],
    );
  }
}

/// 레이더 패널 한 개 — 제목 + 600px WebView + 전체화면 버튼.
/// 웹뷰 초기화를 잠시 지연(동시 로드 스파이크 완화)하고, 로드 전엔 스피너를 보인다.
class _RadarPanel extends StatefulWidget {
  final String title;
  final String url;
  final bool denyLocation; // true면 웹 위치권한 프롬프트 자동 거부.
  final IconData icon; // 헤더 아이콘(레이더/대기흐름 등)
  const _RadarPanel(
      {required this.title, required this.url, this.denyLocation = false, this.icon = Icons.radar});

  @override
  State<_RadarPanel> createState() => _RadarPanelState();
}

class _RadarPanelState extends State<_RadarPanel> {
  bool _showWeb = false;

  @override
  void initState() {
    super.initState();
    // 초기 페이지 렌더 부담을 줄이려 웹뷰는 2초 지연 후 생성(그 전엔 스피너).
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
          Row(
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 4.0),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
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
                    touchToggle: true, // 기본 스크롤 통과, 하단 버튼으로 조작 on/off
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
                    builder: (context) => AirInfoFullPage(
                          title: widget.title,
                          url: widget.url,
                          denyLocation: widget.denyLocation,
                        )),
              ),
              child: Text('전체화면으로 ', style: semiboldText.copyWith(fontSize: 11.0)),
            ),
        ],
      ),
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
      {super.key, required this.title, required this.url, this.injectJs, this.denyLocation = false});

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
        title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: CommonWebView(
            isBackBtn: false, url: widget.url, injectJs: widget.injectJs, denyLocation: widget.denyLocation),
      ),
    );
  }
}
