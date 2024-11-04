import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/code_data.dart';
import 'package:project1/repo/common/res_data.dart';

class CommRepo {
  Future<ResData> searchCode(CodeReq reqData) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/comm/searchcommcode';
      Response response = await dio.post(url, data: reqData.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
