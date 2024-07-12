import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/api/google_api.dart';
import 'package:project1/repo/api/kakao_api.dart';
import 'package:project1/repo/api/naver_api.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
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
    super.initState();
  }

  Future signIn(String provider) async {
    isLoading.value = true;
    bool result = false;
    if ("kakao" == provider) {
      result = await KakaoApi().signInWithKakaoApp();
    } else if ("naver" == provider) {
      result = await NaverApi().signInWithNaver();
    } else if ("google" == provider) {
      result = await GoogleApi().signInWithGoogle();
    }
    if (!result) {
      Utils.alert("소셜 로그인 실패되었습니다. 다시 시도 해주세요.");
      isLoading.value = false;
      return;
    }
    Get.offAllNamed('/AuthPage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color.fromARGB(255, 81, 139, 79),
      backgroundColor: const Color(0xFF262B49),
      //  appBar: AppBar(title: const Text('Login')),
      body: Container(
        width: 400,
        // decoration: const BoxDecoration(
        //   image: DecorationImage(
        //     image: AssetImage('assets/bg.jpg'),
        //     fit: BoxFit.cover,
        //   ),
        // ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Gap(85),
                    const Center(
                        child: Text(
                      'SKYSNAP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        // child: Card(
                        //   elevation: 18.0,
                        //   clipBehavior: Clip.antiAlias,
                        //   shape: RoundedRectangleBorder(
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Image.asset('assets/skysnap.png'),
                        // ),
                        ),
                    const Spacer(),
                    InkWell(
                      onTap: () async => signIn('kakao'),
                      splashColor: Colors.brown.withOpacity(0.5),
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width * 0.6,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 0.7),
                          image: const DecorationImage(
                            image: AssetImage(
                              "assets/login/kakao_login.png",
                            ),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                    const Gap(20),
                    InkWell(
                      onTap: () async => signIn('naver'),
                      splashColor: Colors.brown.withOpacity(0.5),
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width * 0.6,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 0.7),
                          image: const DecorationImage(
                            image: AssetImage(
                              "assets/login/naver_login.png",
                            ),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                    const Gap(20),
                    InkWell(
                      onTap: () async => signIn('google'),
                      splashColor: Colors.brown.withOpacity(0.5),
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width * 0.6,
                        decoration: const BoxDecoration(
                          // shape: BoxShape.rectangle,
                          image: DecorationImage(
                            image: AssetImage(
                              "assets/login/google_login.png",
                            ),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                    const Gap(20),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, value, child) {
                  return CustomIndicatorOffstage(isLoading: !value, color: const Color(0xFFEA3799), opacity: 0.5);
                })
          ],
        ),
      ),
    );
  }
}
