import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:get/get.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    return OnBoardingSlider(
      finishButtonText: '회원 가입',
      onFinish: () {
        Get.toNamed('/LoginPage');
      },
      finishButtonTextStyle: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      finishButtonStyle: FinishButtonStyle(
        backgroundColor: const Color.fromARGB(255, 81, 139, 79),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(35),
        ),
      ),
      // skipTextButton: const Text(
      //   'Skip',
      //   style: TextStyle(
      //     fontSize: 18,
      //     color: Colors.black,
      //     fontWeight: FontWeight.w600,
      //   ),
      // ),
      // trailing: Text(
      //   'Login',
      //   style: TextStyle(
      //     fontSize: 20,
      //     color: kDarkBlueColor,
      //     fontWeight: FontWeight.bold,
      //   ),
      // ),
      // trailingFunction: () {
      //   Get.toNamed("/login");
      // },
      controllerColor: const Color.fromARGB(255, 81, 139, 79),
      totalPage: 3,
      headerBackgroundColor: Colors.white,
      pageBackgroundColor: Colors.white,
      background: const [
        Padding(
          padding: EdgeInsets.only(left: 28.0),
        ),
        Padding(
          padding: EdgeInsets.only(left: 28.0),
        ),
        Padding(
          padding: EdgeInsets.only(left: 28.0),
        ),
      ],
      speed: 1.8,
      pageBodies: [
        Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 40,
              ),
              const Text(
                '내가 맡은 수임사건을\n한눈에 확인해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                height: MediaQuery.of(context).size.height / 2,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10),
                decoration: BoxDecoration(
                  //  color: Colors.brown,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset('assets/images/onboarding/slide_1.png'),
              ),
            ],
          ),
        ),
        Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 40,
              ),
              const Text(
                '대출금 지급요청 및 등기업무를\n쉽게 진행할 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                height: MediaQuery.of(context).size.height / 2,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10),
                decoration: BoxDecoration(
                  //   color: Colors.indigo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset('assets/images/onboarding/slide_2.png'),
              ),
            ],
          ),
        ),
        Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 40,
              ),
              const Text(
                '관심지역 이전등기 사건을 쉽고\n빠르게 수임하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                height: MediaQuery.of(context).size.height / 2,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10),
                decoration: BoxDecoration(
                  // color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset('assets/images/onboarding/slide_3.png'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
