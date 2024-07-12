import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/utils/log_utils.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isInitSYn = false;
  @override
  void initState() {
    super.initState();
  }

  Future<void> initS() async {
    Stopwatch stopwatch = Stopwatch()..start();
    Get.find<WeatherCntr>().requestLocation().then((value) {
      stopwatch.stop();
      lo.g('@@@  auth page   =>. ${stopwatch.elapsed}');
      Get.offAllNamed('/rootPage');
    });
  }

  @override
  Widget build(BuildContext context) {
    // log(AuthCntr.to.custId.value);

    return GetBuilder(
        init: AuthCntr(),
        builder: (context) {
          if (Get.find<AuthCntr>().isLogged.value) {
            if (isInitSYn == false) {
              isInitSYn = true;
              initS();
            }
          }

          return Scaffold(
            backgroundColor: const Color(0xFF262B49),
            body: Center(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/lottie/sun5.json',
                          height: 50.0,
                          width: 50.0,
                        ),
                        const Gap(1),
                        const Text(
                          "SkySnap",
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Text(
                        "CodeLabTiger",
                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
              // child: Text(
              //   'GPS ...',
              //   style: TextStyle(color: Colors.white, fontSize: 11),
              // ),
            ),
          );
        });
  }
}
