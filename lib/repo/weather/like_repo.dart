import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

class LikeRepo {
  final dio = authDio();

  // like 저장
  Future<ResData> save(String boardId) async {
    try {
      var url = '${UrlConfig.baseURL}/like/save?boardId=$boardId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // like 건수 조회
  Future<ResData> count(String boardId) async {
    try {
      var url = '${UrlConfig.baseURL}/like/count?boardId=$boardId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // like 삭제
  Future<ResData> cancle(String boardId) async {
    try {
      var url = '${UrlConfig.baseURL}/like/cancle?boardId=$boardId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }
}
