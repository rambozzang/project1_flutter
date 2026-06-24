import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initLottie();
  }

  void initLottie() async {
    await WeatherLottie.precacheAllAnimations(context);
  }

  Future<void> initS() async {
    try {
      Get.find<WeatherGogoCntr>().requestLocation().then((value) {
        // 위치 확보 즉시 날씨를 비동기로 선로딩한다(await 안 함).
        // 로그인/네비게이션과 병렬로 받아두어, 날씨 화면 진입 시 렉이 없게 한다.
        // (날씨 컨트롤러는 main.dart 영구 바인딩이라 라우트 전환에도 안전)
        // 비디오는 rootPage에서 생성·로드되므로 여기서 건드리지 않는다.
        Get.find<WeatherGogoCntr>().getInitWeatherData(true);

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
      return Scaffold(
        backgroundColor: const Color(0xFF262B49),
        body: Stack(
          children: [
            SizedBox.expand(
              child: WeatherLottie.background(),
            ),
            const Center(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Gap(1),
                        Text(
                          "SkySnap",
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    child: Center(
                      child: Text(
                        "CodeLabTiger",
                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
