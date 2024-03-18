import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/repo/api/token_data.dart';
import 'package:project1/repo/data/login_data.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';

import 'package:project1/utils/log_utils.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthCntr>(
      () => AuthCntr(),
    );
  }
}

class AuthCntr extends GetxController with SecureStorage {
  static AuthCntr get to => Get.find();

  Rx<LoginRes> resLoginData = LoginRes().obs;
  RxBool isLogged = false.obs;
  //로그인 방식
  RxString authMethod = "".obs;
  //로그인 방식
  RxString membNo = "".obs;

  @override
  void onInit() async {
    super.onInit();
    loginCheck();
  }

  // 회원 가입
  void signIn(User user) async {
    log(user.toString());
  }

  //스토리지에서 membNo 존재 여부 판단
  //  -> 온보딩 화면으로 이동 - 회원가입 화면
  //  -> 로그인 화면 이동
  void loginCheck() async {
    // 테스트를 위한 하드코딩
    //대표계정(홍길동1)
    // membNo.value = '202309120001';
    // membNo.value = '202402190004';
    //소속직원계정
    // membNo.value = '202402190004';
    // membNo.value = '111111111111';
    // await saveMembNo(membNo.value);

    //회원번호 가져오기
    membNo.value = (await getMembNo()) ?? '';
    //로그인 방식이 존재하지 않는다면 pin방식으로 로그인을 진행한다.
    authMethod.value = (await getAuthMethod()) ?? 'PIN';

    Lo.g("membNo : ${membNo.value}");
    Lo.g("authMethod : ${authMethod.value}");

    if (StringUtils.isEmpty(membNo.value)) {
      //   await Future.delayed(const Duration(milliseconds: 10), () => Get.offAndToNamed("/onBoarding"));
      Get.offAndToNamed("/onBoarding");
      return;
    }

    isLogged.value = true;
    Get.toNamed("/login");

    return;
  }
}
