import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

class LikeRepo {
  // like 저장
  Future<ResData> save(String boardId, String custId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/like/save?boardId=$boardId&custId=$custId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // like 건수 조회
  Future<ResData> count(String boardId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/like/count?boardId=$boardId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // like 삭제
  Future<ResData> cancle(String boardId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/like/cancle?boardId=$boardId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
