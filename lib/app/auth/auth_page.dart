import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/play_lottie.dart';

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
    Get.find<WeatherCntr>().requestLocation().then((value) {
      Get.offAllNamed('/rootPage');
    });

    //Future.delayed(const Duration(milliseconds: 500), () {

    // });
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

          return const Scaffold(
            backgroundColor: Color(0xFF262B49),
            body: Center(
              child: SizedBox(
                // height: 105,
                width: 125,
                child: PlayLottie(lottie: 'assets/lottie/loading_weather.json'),
              ),
            ),
          );
        });
  }
}
