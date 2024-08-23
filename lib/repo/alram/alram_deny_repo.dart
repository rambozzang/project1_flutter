import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

class AlramDenyRepo {
  // Alram list 가져오기
  Future<ResData> getDenyalramCdlist() async {
    final dio = await AuthDio.instance.getDio(debug: false);
    try {
      var url = '${UrlConfig.baseURL}/alram/denyalramCdlist';

      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // alram 거부 추가
  Future<ResData> adddeny(String alramCd) async {
    final dio = await AuthDio.instance.getDio(debug: false);
    try {
      var url = '${UrlConfig.baseURL}/alram/adddeny?alramCd=$alramCd';

      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // alram 겁부 삭제
  Future<ResData> deleteAlram(String alramCd) async {
    final dio = await AuthDio.instance.getDio(debug: false);
    try {
      var url = '${UrlConfig.baseURL}/alram/deletedeny?alramCd=$alramCd';

      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
