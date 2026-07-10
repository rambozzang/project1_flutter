import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/webview/common_webview.dart';

class WeatherWEbviewPage extends StatelessWidget {
  const WeatherWEbviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // const webViewUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=127.20,36.33,2780/loc=';
    const webViewUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=126.12,37.16,1280/loc=127.030,37.221';
    // const webViewUrl = 'https://www.windy.com/37.567/126.978?radar,37.073,126.978,8';
    // const webViewUrl = 'https://www.ventusky.com/ko';

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
              PhosphorIcon(PhosphorIconsRegular.wind, color: Colors.white),
              SizedBox(width: 4.0),
              Text(
                '대기 흐름',
                style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Spacer(),
            ],
          ),
          const Gap(15),
          const SizedBox(
            height: 600,
            child: CommonWebView(
              isBackBtn: false,
              url: webViewUrl,
            ),
          ),
          const Gap(10),
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
                        title: '대기 흐름',
                        url: webViewUrl,
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

/// 실시간 레이더 영상 — Windy.com 날씨 레이더를 임베드.
class WindyRadarPage extends StatefulWidget {
  const WindyRadarPage({super.key});

  @override
  State<WindyRadarPage> createState() => _WindyRadarPageState();
}

class _WindyRadarPageState extends State<WindyRadarPage> {
  static const String _url =
      'https://www.windy.com/ko/-%EB%82%A0%EC%94%A8-%EB%A0%88%EC%9D%B4%EB%8D%94-radar?radar,37.934,127.064,6';
  bool _showWeb = false;

  @override
  void initState() {
    super.initState();
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
              Icon(Icons.radar, color: Colors.white),
              SizedBox(width: 4.0),
              Text(
                '실시간 레이더 영상',
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
                          title: '실시간 레이더 영상',
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
/// 넓은 위성 GIS 지도를 크게 보도록 가로 보기를 허용하고, 나가면 세로 고정으로 복귀한다.
/// 대기정보 전체화면 보기 — 타이틀 바 + 웹뷰 전체.
/// 넓은 위성 GIS 지도를 크게 보도록 가로 보기를 허용하고, 나가면 세로 고정으로 복귀한다.
class AirInfoFullPage extends StatefulWidget {
  final String title;
  final String url;
  const AirInfoFullPage({super.key, required this.title, required this.url});

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
        child: CommonWebView(isBackBtn: false, url: widget.url),
      ),
    );
  }
}
