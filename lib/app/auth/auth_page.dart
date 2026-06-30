import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/log_utils.dart';

const String _logoSvg = '''
<svg viewBox="0 0 100 100" width="96" height="96">
  <g fill="#ffffff">
    <circle cx="38" cy="50" r="19"/>
    <circle cx="60" cy="45" r="23"/>
    <circle cx="27" cy="59" r="13"/>
    <circle cx="74" cy="59" r="14"/>
    <rect x="25" y="55" width="54" height="20" rx="10"/>
    <path d="M45 71 L37 90 L56 73 Z"/>
  </g>
</svg>
''';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool isInitSYn = false;
  bool isGoRoot = false;
  // GPS 위치 요청 future. 로그인 완료를 기다리지 않고 앱 부팅 즉시 시작한다.
  Future<dynamic>? _locationFuture;

  // 로고 등장 애니메이션(페이드+살짝 확대) — 한 번만 부드럽게 재생.
  late final AnimationController _introCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _introCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _introCtrl, curve: const Interval(0.1, 1.0, curve: Curves.easeOut));
    _introCtrl.forward();

    // 자동로그인 흐름: 로그인(토큰 갱신)과 "병렬"로 GPS·날씨를 미리 가져온다.
    // (날씨 백엔드 호출은 저장된 토큰으로 동작하므로 로그인 완료를 기다릴 필요 없음)
    // ※ Lottie 전체 프리캐시(27개)는 시작 부하가 커서 제거 → 홈에서 필요한 1개만 즉시 디코딩됨.
    _prefetchLocationAndWeather();
  }

  void _prefetchLocationAndWeather() {
    try {
      final cntr = Get.find<WeatherGogoCntr>();
      _locationFuture = cntr.requestLocation();
      _locationFuture!.then((_) {
        // 위치 확보 즉시 날씨 선로딩(로그인과 병렬). 날씨 화면 진입 시 렉 없음.
        cntr.getInitWeatherData(true);
      }).catchError((e) {
        lo.g('prefetch location/weather error: $e');
      });
    } catch (e) {
      lo.g('prefetch init error: $e');
    }
  }

  Future<void> initS() async {
    try {
      // build 중 네비게이션 충돌 방지: 다음 프레임에서 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isGoRoot == false) {
          Get.offAllNamed('/rootPage');
          isGoRoot = true;
        }
      });
    } catch (e) {
      lo.g(e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final cntr = Get.find<AuthCntr>();
      if (!cntr.isLogged.value) {
        return;
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        Get.find<WeatherGogoCntr>()
            .requestLocation()
            .then((_) => Get.offAllNamed('/rootPage'))
            .catchError((e) {
          lo.g('resume location error: $e');
          // 위치 재요청 실패하더라도 메인으로 이동해야 멈춰 보이지 않는다.
          Get.offAllNamed('/rootPage');
        });
      });
    }
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLogged = Get.find<AuthCntr>().isLogged.value;
      if (isLogged && !isInitSYn) {
        isInitSYn = true;
        initS();
      }
      // 그라데이션 및 로고/문구 레이아웃 반영 (Skysnap 로고 및 앱 아이콘 적용)
      return Scaffold(
        backgroundColor: const Color(0xFFFF8F8F),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFCB6B),
                Color(0xFFFF8F8F),
                Color(0xFFFF6FA6),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고 — 부드럽게 확대+페이드 등장 및 커스텀 SVG 드롭섀도우 효과 적용
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _fade,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 섀도우 레이어 (ImageFiltered 및 blur 필터를 활용한 고성능 그림자)
                            Transform.translate(
                              offset: const Offset(0, 8),
                              child: ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                                child: SvgPicture.string(
                                  _logoSvg.replaceAll('#ffffff', '#AA285A').replaceAll('#fff', '#AA285A'),
                                  width: 96,
                                  height: 96,
                                ),
                              ),
                            ),
                            // 포그라운드 로고 레이어
                            SvgPicture.string(
                              _logoSvg,
                              width: 96,
                              height: 96,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeTransition(
                      opacity: _fade,
                      child: Text(
                        "skysnap",
                        style: GoogleFonts.quicksand(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fade,
                      child: Text(
                        "오늘의 하늘을 나누다",
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 얇은 화이트 반투명 진행바
                    FadeTransition(
                      opacity: _fade,
                      child: SizedBox(
                        width: 128,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "CodeLabTiger",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
