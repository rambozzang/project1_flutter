import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
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
    Get.find<WeatherGogoCntr>().requestLocation().then((value) {
      Get.offAllNamed('/rootPage');
    });
    // Get.offAllNamed('/rootPage');
  }

  @override
  Widget build(BuildContext context) {
    // log(AuthCntr.to.custId.value);

    return GetBuilder<AuthCntr>(
        init: AuthCntr(),
        builder: (controller) {
          if (controller.isLogged.value) {
            if (isInitSYn == false) {
              isInitSYn = true;
              initS();
            }
          }
          return Scaffold(
            backgroundColor: Color(0xFF262B49),
            body: Stack(
              children: [
                Hero(
                  tag: 'bg1',
                  child: SizedBox(
                    width: double.infinity,
                    child: Lottie.asset(
                      'assets/login/bg1.json',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Center(
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Lottie.asset(
                            //   'assets/lottie/sun5.json',
                            //   height: 50.0,
                            //   width: 50.0,
                            // ),
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
