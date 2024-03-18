import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/repo/api/google_api.dart';
import 'package:project1/repo/api/kakao_api.dart';
import 'package:project1/repo/api/naver_api.dart';
import 'package:project1/widget/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    aa();
  }

  aa() async {
    print(await KakaoSdk.origin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      //  appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                CustomButton(text: 'Google Login', type: 'XL', isEnable: true, onPressed: () => GoogleApi().signInWithGoogle()),
                const Gap(14),
                CustomButton(
                  text: 'Kakao Login',
                  type: 'XL',
                  isEnable: true,
                  onPressed: () => KakaoApi().signInWithKakaoApp(),
                ),
                const Gap(14),
                CustomButton(
                  text: 'Naver Login',
                  type: 'XL',
                  isEnable: true,
                  onPressed: () => NaverApi().signInWithNaver(),
                ),
                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
