import 'dart:convert';

import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/data/create_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:dio/dio.dart';

class CustRepo {
  final dio = authDio();
  // 회원가입
  Future<ResData> createCust(CreateData data) async {
    try {
      var url = 'http://localhost:7010/api/auth/joinbytoken';
      // var url = '${UrlConfig.baseURL}/auth/joinbytoken';

      Response response = await dio.post(url, data: data.toJson());

      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 회원정보 수정
  Future<void> updateCust() async {
    // Update customer
  }
  // 회원탈퇴
  Future<void> deleteCust() async {
    // Delete customer
  }
  // 회원정보 조회
  Future<void> getCust() async {
    // Get customer
    try {
      // AuthDio.run().get(path);
    } catch (e) {}
  }
}
