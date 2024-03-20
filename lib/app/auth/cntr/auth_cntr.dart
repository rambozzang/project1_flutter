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

class AuthBinding implements Bindings {
  @override
  // List<Bind> dependencies() {
  //   return [
  //     Bind.lazyPut<AuthCntr>(() => AuthCntr()),
  //   ];
  // }
  void dependencies() {
    Get.lazyPut(() => AuthCntr());
  }
}

class AuthCntr extends GetxController with SecureStorage {
  static AuthCntr get to => Get.find();

  Rx<LoginRes> resLoginData = LoginRes().obs;
  RxBool isLogged = false.obs;

  //로그인 방식
  RxString custId = "".obs;

  @override
  void onInit() async {
    super.onInit();
    loginCheck();
  }

  //스토리지에서 custId 존재 여부 판단
  //  -> 온보딩 화면으로 이동 - 회원가입 화면
  //  -> 초기으로 화면 이동
  void loginCheck() async {
    //회원번호 가져오기
    custId.value = (await getCustId()) ?? '';
    Lo.g("custId : ${custId.value}");

    if (StringUtils.isEmpty(custId.value)) {
      Get.offAndToNamed("/onBoarding");
      return;
    }

    isLogged.value = true;
    Get.toNamed("/login");
    return;
  }
}
