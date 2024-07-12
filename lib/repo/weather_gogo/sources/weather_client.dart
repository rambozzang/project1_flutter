import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiClient {
  static const _baseURL =
      'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';

  static Dio createDio({required bool isLog, PrettyDioLogger? customLogger}) {
    var dio = Dio(BaseOptions(baseUrl: _baseURL));

    if (isLog) {
      final logger = customLogger ?? PrettyDioLogger();
      dio.interceptors.add(logger);
    }

    return dio;
  }
}
