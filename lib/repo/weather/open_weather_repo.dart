import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:project1/config/open_weather_api_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/utils/log_utils.dart';

class OpenWheatherRepo {
  Future<ResData> getWeather(Position position) async {
    final dio = Dio(BaseOptions(
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json'
        },
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 60)));
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
      maxWidth: 120,
    ));

    try {
      log(position.toString());
      var url =
          '${OpenWeatherApiConfig.apiUrl}?q=seoul&lang=kr&units=metric&lat=${position!.latitude}&lon=${position.longitude}&appid=${OpenWeatherApiConfig.apiKey}';
      log(url);

      Response response = await dio.get(url);
      log(response.toString());
      if (response.statusCode == 200) {
        return ResData.fromJson(
            jsonEncode({'code': '00', 'data': response.data}));
      } else {
        return ResData.fromJson(jsonEncode(
            {'code': response.statusCode, 'message': response.statusMessage}));
      }
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }
}
