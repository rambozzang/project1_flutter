import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/alram/data/alram_devy_data.dart';
import 'package:project1/repo/alram/data/alram_req_data.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

class AlramRepo {
  // Alram list 가져오기
  Future<ResData> getAlramList(AlramReqData reqData) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/comm/searchalram';

      Response response = await dio.post(url, data: reqData.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 알람 거부
  Future<ResData> denyAlram(AlramDenyData reqData) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/comm/denyalram';

      Response response = await dio.post(url, data: reqData.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // CustId 로 push 보내기
  Future<ResData> pushByCustId(String custId) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/comm/sendByCustId?CustId=$custId&alramCd=06';
      Response response = await dio.post(
        url,
      );
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
