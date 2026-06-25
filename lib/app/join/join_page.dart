import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';
import 'package:project1/app/join/widget/ConstellationPainter.dart';
import 'package:project1/app/join/widget/TwinklingStar.dart';
import 'package:project1/repo/api/apple_api.dart';
import 'package:project1/repo/api/google_api.dart';
import 'package:project1/repo/api/kakao_api.dart';
import 'package:project1/repo/api/naver_api.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

// 회원가입 페이지 위젯
class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // 로딩 상태를 관리하는 ValueNotifier
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  List<MovingConstellations> constellations = [];
  Timer? _animationTimer;
  late AnimationController _controller;
  late Animation<double> _animation;

  List<TwinklingStar> twinklingStars = [];

  void createConstellations() {
    constellations = [
      MovingConstellations(
          190,
          180,
          [
            const Offset(0.6, 0.2),
            const Offset(0.62, 0.25),
            const Offset(0.64, 0.3),
            const Offset(0.58, 0.28),
            const Offset(0.66, 0.28),
            const Offset(0.6, 0.35),
            const Offset(0.64, 0.35),
          ],
          rotationSpeed: 0.03),
      /** 카시오페이 */
      MovingConstellations(
          40,
          30,
          [
            const Offset(20, 40),
            const Offset(60, 20),
            const Offset(100, 60),
            const Offset(140, 20),
            const Offset(180, 40),
          ],
          rotationSpeed: 0.077),
      /** 북두실청 */
      MovingConstellations(
          40,
          430,
          [
            const Offset(20, 80),
            const Offset(40, 60),
            const Offset(60, 50),
            const Offset(80, 40),
            const Offset(100, 30),
            const Offset(110, 50),
            const Offset(120, 70),
          ],
          rotationSpeed: 0.077),
      /**사자 자리 */
      MovingConstellations(
          200,
          400,
          [
            const Offset(40, 40),
            const Offset(120, 40),
            const Offset(120, 120),
            const Offset(40, 120),
            const Offset(40, 40),
            const Offset(80, 80),
          ],
          rotationSpeed: 0.055),
      /**곰 자리 */
      MovingConstellations(
          140,
          300,
          [
            const Offset(40, 40),
            const Offset(60, 32),
            const Offset(80, 40),
            const Offset(100, 60),
            const Offset(120, 80),
            const Offset(140, 72),
            const Offset(160, 88),
          ],
          rotationSpeed: 0.09),
      MovingConstellations(
          60,
          160,
          [
            const Offset(40, 20),
            const Offset(60, 40),
            const Offset(80, 60),
            const Offset(100, 80),
            const Offset(120, 100),
            const Offset(70, 70),
            const Offset(90, 70),
            const Offset(20, 80),
            const Offset(140, 80),
          ],
          rotationSpeed: 0.09),
    ];
  }

  void startObjectMovement() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        updateObjectPositions();
        updateStarPositions();
      } else {
        timer.cancel();
      }
    });
  }

  void updateObjectPositions() {
    setState(() {
      for (var constellation in constellations) {
        constellation.move();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // createConstellations();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 950),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // createTwinklingStars();
    // startObjectMovement();
  }

  void createTwinklingStars() {
    for (int i = 0; i < 100; i++) {
      twinklingStars.add(TwinklingStar(
          Random().nextDouble() * MediaQuery.of(context).size.width, Random().nextDouble() * MediaQuery.of(context).size.height));
    }
  }

  void updateStarPositions() {
    setState(() {
      for (var star in twinklingStars) {
        star.twinkle();
      }
    });
  }

  // 소셜 로그인 처리 함수
  Future signIn(String provider) async {
    try {
      isLoading.value = true;
      ResData<String> result = ResData<String>();

      // 선택된 제공자에 따라 적절한 로그인 API 호출
      switch (provider) {
        case "kakao":
          result = await KakaoApi().signInWithKakaoApp();
          break;
        case "naver":
          result = await NaverApi().signInWithNaver();
          break;
        case "google":
          result = await GoogleApi().signInWithGoogle();
          break;
        case "apple":
          result = await AppleApi().signInWithApple();
          break;
      }

      if (result.code != "00") {
        Utils.alert("다시 시도해 주세요!");
        isLoading.value = false;
        return;
      }

      lo.g(result.data.toString());

      isLoading.value = false;
      Get.offAllNamed('/AgreePage/${result.data}');
    } catch (e) {
      Utils.alert(e.toString());
      isLoading.value = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    isLoading.value = false;
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            // gradient: LinearGradient(
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            //   colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            // ),

            // gradient: LinearGradient(
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            //   colors: [
            //     // Color(0xFF0D1B2A),
            //     Color.fromARGB(255, 44, 68, 112),
            //     Color.fromARGB(255, 57, 82, 113),
            //     Color.fromARGB(255, 60, 81, 108),
            //   ],
            // ),
            ),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
              child: Lottie.asset('assets/login/join_ani.json', fit: BoxFit.fill),
            ),
            Padding(
              padding: const EdgeInsets.all(26.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Gap(95),
                    // 앱 소개 텍스트
                    _buildAppIntroText(),
                    const Spacer(),
                    // 회원가입 섹션
                    _buildSignUpSection(),
                    const Gap(65),
                    // 푸터
                    _buildFooter(),
                  ],
                ),
              ),
            ),
            // 로딩 인디케이터
            _buildLoadingIndicator(),
            ...constellations.map((constellation) => Positioned(
                  left: constellation.x,
                  top: constellation.y,
                  child: CustomPaint(
                    painter: constellation.constellationPainter,
                  ),
                )),
            ...twinklingStars.map((star) => Positioned(
                  left: star.x,
                  top: star.y,
                  child: Opacity(
                    opacity: star.opacity,
                    child: Container(
                      width: star.opacity * 5,
                      height: star.opacity * 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // 앱 소개 텍스트 위젯
  Widget _buildAppIntroText() {
    return const Column(
      children: [
        // Text(
        //   '날씨, 일상의 모든 영상 공유',
        //   style: TextStyle(
        //     color: Colors.white,
        //     fontSize: 15,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        OffsetText(
          text: '날씨, 일상의 모든 영상 공유',
          duration: Duration(milliseconds: 450),
          type: AnimationType.letter,
          mode: AnimationMode.repeatNoReverse,
          textStyle: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          slideType: SlideAnimationType.topBottom,
        ),
        OffsetText(
          text: 'SKYSNAP',
          duration: Duration(milliseconds: 5500),
          type: AnimationType.word,
          mode: AnimationMode.repeatNoReverse,
          textStyle: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
          slideType: SlideAnimationType.bottomTop,
        ),
        // Text(
        //   'SKYSNAP',
        //   style: TextStyle(
        //     color: Colors.white,
        //     fontSize: 35,
        //     fontWeight: FontWeight.w900,
        //   ),
        // ),
      ],
    );
  }

  // 회원가입 섹션 위젯
  Widget _buildSignUpSection() {
    return Column(
      children: [
        // const Text(
        //   'SIGN UP',
        //   style: TextStyle(
        //     color: Colors.white,
        //     fontSize: 15,
        //     fontWeight: FontWeight.w900,
        //   ),
        // ),
        const OffsetText(
          text: 'SIGN UP',
          duration: Duration(milliseconds: 350),
          type: AnimationType.letter,
          mode: AnimationMode.repeatWithReverse,
          textStyle: TextStyle(fontSize: 15, color: Colors.amber, fontWeight: FontWeight.w900),
          slideType: SlideAnimationType.rightLeft,
        ),
        // const Gap(10),
        // const Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 60.0),
        //   child: Divider(color: Colors.white),
        // ),
        const Gap(25),
        // 소셜 로그인 버튼들
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialLoginButton('kakao', "assets/login/kakao_circle.png", '카카오'),
            const Gap(20),
            // _buildSocialLoginButton('naver', "assets/login/naver_circle.png", '네이버'),
            // const Gap(20),
            _buildSocialLoginButton('google', "assets/login/google_circle.png", '구글'),
            if (Platform.isIOS) ...[const Gap(20), _buildSocialLoginButton('apple', "assets/login/apple_login.png", '애플')]
          ],
        ),
        const Gap(25),
        FadeTransition(
          opacity: _animation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(95, 1, 22, 50),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              '💥1.8초면 가입가능🐯',
              style: TextStyle(color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  // 소셜 로그인 버튼 위젯
  Widget _buildSocialLoginButton(String provider, String imagePath, String label) {
    return InkWell(
      onTap: () async => signIn(provider),
      splashColor: Colors.brown.withOpacity(0.5),
      child: Column(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.fill,
              ),
            ),
          ),
          const Gap(10),
          // Text(
          //   label,
          //   style: const TextStyle(color: Colors.white, fontSize: 15),
          // )
        ],
      ),
    );
  }

  // 푸터 위젯
  Widget _buildFooter() {
    return const Text(
      'CodeLabTiger',
      style: TextStyle(color: Colors.white, fontSize: 8),
    );
  }

  // 로딩 인디케이터 위젯
  Widget _buildLoadingIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoading,
      builder: (context, value, child) {
        return CustomIndicatorOffstage(
          isLoading: !value,
          color: const Color(0xFFEA3799),
          opacity: 0.5,
        );
      },
    );
  }
}
