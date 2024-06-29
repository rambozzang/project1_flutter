import 'dart:convert';

import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/data/cust_update_data.dart';
import 'package:project1/repo/cust/data/google_join_data.dart';
import 'package:project1/repo/cust/data/kakao_join_data.dart';
import 'package:project1/repo/cust/data/naver_join_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:dio/dio.dart';

class CustRepo {
  // KAKAO 회원가입
  Future<ResData> createKakaoCust(KakaoJoinData data) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/auth/kakaojoin';
      log(url.toString());
      log(data.toString());
      Response response = await dio.post(url, data: data.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // Naver 회원가입
  Future<ResData> createNaverCust(NaverJoinData data) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/auth/naverjoin';

      log(data.toString());
      Response response = await dio.post(url, data: data.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // Google 회원가입
  Future<ResData> createGoogleCust(GoogleJoinData data) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      //var url = 'http://localhost:7010/api/auth/googlejoin';
      var url = '${UrlConfig.baseURL}/auth/googlejoin';

      log(data.toString());
      Response response = await dio.post(url, data: data.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 회원정보 수정
  Future<ResData> updateCust(CustUpdataData data) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/cust/updateCustInfo';

      // log(data.toString());
      Response response = await dio.post(url, data: data.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 회원정보 수정
  Future<ResData> getCustInfo(String custId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/cust/getCustInfo?custId=$custId';
      Response response = await dio.get(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 회원탈퇴
  Future<void> deleteCust() async {
    // Delete customer
  }
  // 회원정보 조회
  Future<ResData> login(String custId, String fcmId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/auth/login';
      Response response = await dio.post(url, data: {'custId': custId, 'fcmId': fcmId});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // Tag 저장
  Future<ResData> saveTag(String custId, String tag) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/tag/save';
      Response response = await dio.post(url, data: {'custId': custId, 'tagNm': tag});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // Tag 삭제
  Future<ResData> deleteTag(String custId, String tag) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/tag/delete';
      Response response = await dio.post(url, data: {'custId': custId, 'tagNm': tag});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // Tag 조회
  Future<ResData> getTagList(String custId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/tag/getTagList?custId=$custId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 회원 사진 Url 수정
  Future<ResData> modiProfilePath(String custId, String photoUrl) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/cust/modiProfilePath';
      Response response = await dio.post(url, data: {'custId': custId, 'profilePath': photoUrl});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
