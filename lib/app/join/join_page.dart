import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/repo/api/apple_api.dart';
import 'package:project1/repo/api/google_api.dart';
import 'package:project1/repo/api/kakao_api.dart';
import 'package:project1/repo/api/naver_api.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

// 회원가입 페이지 위젯
class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  // 로딩 상태를 관리하는 ValueNotifier
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
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

      isLoading.value = false;

      if (result.code != "00") {
        Utils.alert("오류가 발생했습니다. 다시 시도해 주세요. ${result.msg}");
        return;
      }

      // Get.offAllNamed('/AuthPage');
      Get.offAllNamed('/AgreePage/${result.data}');
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage('assets/images/girl-6356393_640.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          blendMode: BlendMode.srcIn,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(26.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Gap(85),
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
            ],
          ),
        ),
      ),
    );
  }

  // 앱 소개 텍스트 위젯
  Widget _buildAppIntroText() {
    return const Column(
      children: [
        Text(
          '날씨, 일상의 모든 영상 공유',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'SKYSNAP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 35,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // 회원가입 섹션 위젯
  Widget _buildSignUpSection() {
    return Column(
      children: [
        const Text(
          'SIGN UP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Gap(10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 60.0),
          child: Divider(color: Colors.white),
        ),
        const Gap(20),
        // 소셜 로그인 버튼들
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialLoginButton('kakao', "assets/login/kakao_circle.png", '카카오'),
            const Gap(20),
            _buildSocialLoginButton('naver', "assets/login/naver_circle.png", '네이버'),
            const Gap(20),
            _buildSocialLoginButton('google', "assets/login/google_circle.png", '구글'),
            if (Platform.isIOS) ...[const Gap(20), _buildSocialLoginButton('apple', "assets/login/apple_login.png", '애플')]
          ],
        ),
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
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          )
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
