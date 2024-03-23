import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/repo/api/google_api.dart';
import 'package:project1/repo/api/kakao_api.dart';
import 'package:project1/repo/api/naver_api.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Future signIn(String provider) async {
    isLoading.value = true;
    if ("kakao" == provider) {
      await KakaoApi().signInWithKakaoApp();
      isLoading.value = false;
    } else if ("naver" == provider) {
      await NaverApi().signInWithNaver();
      isLoading.value = false;
    } else if ("google" == provider) {
      await GoogleApi().signInWithGoogle();
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      //  appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    CustomButton(
                        text: 'Google Login',
                        type: 'XL',
                        isEnable: true,
                        onPressed: () async => signIn('google')),
                    const Gap(14),
                    CustomButton(
                      text: 'Kakao Login',
                      type: 'XL',
                      isEnable: true,
                      onPressed: () async => signIn('kakao'),
                    ),
                    const Gap(14),
                    CustomButton(
                      text: 'Naver Login',
                      type: 'XL',
                      isEnable: true,
                      onPressed: () async => signIn('naver'),
                    ),
                    const Gap(40),
                  ],
                ),
              ),
              ValueListenableBuilder<bool>(
                  valueListenable: isLoading,
                  builder: (context, value, child) {
                    return CustomIndicatorOffstage(
                        isLoading: !value,
                        color: const Color(0xFFEA3799),
                        opacity: 0.5);
                  })
            ],
          ),
        ),
      ),
    );
  }
}
