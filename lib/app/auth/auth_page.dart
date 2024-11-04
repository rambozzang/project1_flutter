import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/WeatherLottie.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

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
