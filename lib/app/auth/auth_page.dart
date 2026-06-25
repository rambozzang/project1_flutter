import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/WeatherLottie.dart';
import 'package:project1/utils/log_utils.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with WidgetsBindingObserver {
  bool isInitSYn = false;
  bool isGoRoot = false;
  // GPS 위치 요청 future. 로그인 완료를 기다리지 않고 앱 부팅 즉시 시작한다.
  Future<dynamic>? _locationFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initLottie();
    // 자동로그인 흐름: 로그인(토큰 갱신)과 "병렬"로 GPS·날씨를 미리 가져온다.
    // (날씨 백엔드 호출은 저장된 토큰으로 동작하므로 로그인 완료를 기다릴 필요 없음)
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

  void initLottie() async {
    await WeatherLottie.precacheAllAnimations(context);
  }

  Future<void> initS() async {
    try {
      // GPS·날씨는 부팅 시 이미 선행 시작됨(_prefetchLocationAndWeather).
      // 로그인 완료 후, 진행 중이던 위치 요청이 끝나면 root로 이동한다.
      // (root의 영상 피드가 lat/lon을 필요로 하므로 위치 완료를 기다림)
      await (_locationFuture ?? Get.find<WeatherGogoCntr>().requestLocation());
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
      // 달 애니메이션 스플래시 제거 → 로고 + 로딩바(빠른 실행감).
      // 네이티브 스플래시(#262B49)와 동일 무드로 끊김 없이 이어진다.
      return Scaffold(
        backgroundColor: const Color(0xFF262B49),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/skysnap1.png', width: 110, height: 110),
                  const SizedBox(height: 16),
                  const Text(
                    "SkySnap",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "CodeLabTiger",
                  style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
