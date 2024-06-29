import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

class FollowRepo {
  // 팔로우 저장
  Future<ResData> save(String followId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/follow/save?custId=$followId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 팔로우 건수 조회
  Future<ResData> count() async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/follow/count';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 팔로우 삭제
  Future<ResData> cancle(String followId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/follow/cancle?custId=$followId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 팔로우 리스트조회
  Future<ResData> list(String followId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/follow/find?followId=$followId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 내가 팔로한 사용자 리스트 조회 - FollowCustData
  // /follow/findFollowList
  Future<ResData> findFollowList() async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/follow/findFollowList';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 나를 팔로한 사용자 리스트 조회 - FollowCustData
  // /follow/findFollowerList
  Future<ResData> findFollowerList() async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/follow/findFollowerList';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
