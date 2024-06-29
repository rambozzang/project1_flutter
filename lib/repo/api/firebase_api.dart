import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

class FirebaseApi {
  // final dio = authDio();
  // firebase custom token 생성
  // /auth/getFirebaseCustomToken
  Future<ResData> createCustomToken(Map<String, dynamic> user) async {
    try {
      // 사용자 정보 uri
      String userInfoUri = '/auth/getFirebaseCustomToken';
      String callurl = "${UrlConfig.baseURL}$userInfoUri";

      // rest Api 호출 한다.
      log("$callurl");
      final dio = await AuthDio.instance.getDio();
      Response response = await dio.post(callurl);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }
}
