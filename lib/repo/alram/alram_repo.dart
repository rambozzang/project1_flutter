import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/alram/data/alram_req_data.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

class AlramRepo {
  final dio = authDio();
  // Alram list 가져오기
  Future<ResData> getAlramList(AlramReqData reqData) async {
    try {
      var url = '${UrlConfig.baseURL}/comm/searchalram';

      Response response = await dio.post(url, data: reqData.toJson());
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }
}
