import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/log_utils.dart';

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
      // GPS·날씨는 부팅 시 이미 선행 시작됨(_prefetchLocationAndWeather).
      // 로그인 완료 즉시 root로 이동 — 위치/날씨는 백그라운드에서 계속 로딩.
      if (isGoRoot == false) {
        Get.offAllNamed('/rootPage');
        isGoRoot = true;
      }
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
        Get.find<WeatherGogoCntr>().requestLocation().then((value) {
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
    return GetBuilder<AuthCntr>(builder: (controller) {
      if (controller.isLogged.value) {
        if (isInitSYn == false) {
          isInitSYn = true;
          initS();
        }
      }
      // 화이트 클린 로딩화면 — 네이티브 스플래시(흰 배경+로고)와 끊김 없이 이어진다.
      // 순백 대신 아주 옅은 하늘빛 틴트를 더해 브랜드 톤을 살짝 머금는다.
      return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF2F7FE)],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고 — 부드럽게 확대+페이드 등장
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _fade,
                        child: Image.asset(
                          'assets/icon/app_icon_v9.png',
                          width: 104,
                          height: 104,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fade,
                      child: const Text(
                        "SkySnap",
                        style: TextStyle(
                          fontSize: 23,
                          color: Color(0xFF1B2A4A),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // 얇은 진행바
                    FadeTransition(
                      opacity: _fade,
                      child: SizedBox(
                        width: 128,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Color(0xFFE3EBF6),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "CodeLabTiger",
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFAAB3C5),
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
