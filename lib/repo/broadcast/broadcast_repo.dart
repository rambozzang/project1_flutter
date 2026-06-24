import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

class BroadcastRepo {
  Future<ResData> requestLicense({
    required int contentId,
    required String broadcasterNm,
    required String contactEmail,
    required String contactNm,
    required String purpose,
    required String usagePeriod,
  }) async {
    final dio = await AuthDio.instance.getDio();
    try {
      final response = await dio.post(
        '${UrlConfig.baseURL}/broadcast/request',
        data: {
          'contentId': contentId,
          'broadcasterNm': broadcasterNm,
          'contactEmail': contactEmail,
          'contactNm': contactNm,
          'purpose': purpose,
          'usagePeriod': usagePeriod,
        },
      );
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }
}
