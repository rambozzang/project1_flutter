// ignore_for_file: public_member_api_docs, sort_constructors_first
// // 연결 주소 : https://developers.naver.com/docs/login/api/api.md

import 'dart:convert';

import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/naver_join_data.dart';
import 'package:project1/repo/secure_storge.dart';

import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

//  연결 주소 : https://developers.naver.com/docs/login/api/api.md
class NaverApi with SecureStorage {
  Future<void> signInWithNaver() async {
    NaverLoginResult result = await FlutterNaverLogin.logIn();
    log('Naver Login Result : $result');

    CustRepo repo = CustRepo();
    NaverJoinData naverJoinData = NaverJoinData();
    naverJoinData.stauts = result.status.toString();
    NaverAccount naverAccount = NaverAccount();
    naverAccount.nickname = result.account.nickname;
    naverAccount.id = result.account.id.toString();
    naverAccount.name = result.account.name;
    naverAccount.email = result.account.email;
    naverAccount.gender = result.account.gender;
    naverAccount.age = result.account.age;
    naverAccount.birthday = result.account.birthday;
    naverAccount.birthyear = result.account.birthyear;
    naverAccount.profileImage = result.account.profileImage;
    naverAccount.mobile = result.account.mobile;

    naverJoinData.account = naverAccount;

    ResData res = await repo.createNaverCust(naverJoinData);
    if (res.code != "00") {
      Utils.alert(res.msg.toString());
      return;
    }

    Utils.alert("회원가입 성공 :  ${res.data}");

    Get.toNamed('/rootPage');
    AuthCntr.to.signUpProc(naverJoinData.account!.id.toString());
    return;
  }

  Future<void> buttonTokenPressed() async {
    try {
      final NaverAccessToken res = await FlutterNaverLogin.currentAccessToken;

      String refreshToken = res.refreshToken;
      String accesToken = res.accessToken;
      String tokenType = res.tokenType;
    } catch (error) {
      log('Naver Login Result : $error');
    }
  }
}
