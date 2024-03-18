// ignore_for_file: public_member_api_docs, sort_constructors_first
// // 연결 주소 : https://developers.naver.com/docs/login/api/api.md

import 'dart:convert';

import 'package:flutter_naver_login/flutter_naver_login.dart';

import 'package:project1/utils/log_utils.dart';

//  연결 주소 : https://developers.naver.com/docs/login/api/api.md
class NaverApi {
  Future<void> signInWithNaver() async {
    NaverLoginResult res = await FlutterNaverLogin.logIn();
    log('Naver Login Result : $res');
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
