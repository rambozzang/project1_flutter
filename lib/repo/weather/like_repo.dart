import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

class LikeRepo {
  // like 저장 — custId는 게시물 작성자(좋아요 푸시 수신자). 백엔드 /like/save는 pushYn 필수 파라미터.
  Future<ResData> save(String boardId, String custId, {String pushYn = 'Y', String alramCd = '08'}) async {
    final dio = await AuthDio.instance.getDio(debug: false);
    try {
      var url = '${UrlConfig.baseURL}/like/save?boardId=$boardId&custId=$custId&pushYn=$pushYn&alramCd=$alramCd';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // like 건수 조회
  Future<ResData> count(String boardId) async {
    final dio = await AuthDio.instance.getDio(debug: false);
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
    final dio = await AuthDio.instance.getDio(debug: false);
    try {
      var url = '${UrlConfig.baseURL}/like/cancle?boardId=$boardId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
