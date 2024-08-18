import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/repo/weather_gogo/sources/http_client.dart';
import 'package:project1/utils/log_utils.dart';

import '../adapter/adapter.dart';
import '../models/models.dart';
import 'weather_client.dart';
import 'package:http/http.dart' as http;

class FctVersionAPI {
  late Dio _dio;
  final _date = DateTimeAdapter();

  final HttpService _httpService = HttpService();

  FctVersionAPI({bool? isLog, PrettyDioLogger? customLogger}) {
    _dio = ApiClient.createDio(
      isLog: isLog ?? true,
      customLogger: customLogger,
    );
  }
  static const _baseURL = 'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';

  static const _getURL = '$_baseURL/getFcstVersion';

  /// 예보버전정보 Json Data
  Future getJsonDataDio(WeatherVersion version) async {
    late Response response;

    try {
      final nowDate = _date.nowDate(minute: version.date.month - 30);

      response = await _dio.get(
        _getURL,
        queryParameters: version.copyWith(dateTime: nowDate).toJson(),
      );
    } on DioError catch (e) {
      debugPrint(e.message);
      throw Exception(e.message);
    }

    return response.data;
  }

  /// 예보버전정보 Json Data
  Future getJsonData(WeatherVersion version) async {
    late http.Response response;
    late Uri uri;
    try {
      final nowDate = _date.nowDate(minute: version.date.month - 30);

      // weather 객체를 JSON으로 변환
      Map<String, dynamic> weatherJson = version.copyWith(dateTime: nowDate).toJson();
      // 모든 값을 문자열로 변환
      Map<String, String> queryParams = weatherJson.map((key, value) => MapEntry(key, value.toString()));

      uri = Uri.parse(_getURL).replace(queryParameters: queryParams);
      return await _httpService.getWithRetry(uri);
      // response = await http.get(uri);

      // if (response.statusCode == 200 || response.statusCode == 304) {
      //   return json.decode(response.body);
      // } else {
      //   throw Exception('Failed to load data. Status code: ${response.statusCode}');
      // }
    } catch (e) {
      debugPrint(e.toString());

      lo.g('FctVersionAPI() -> Error fetching data for ${e.toString()} ${uri.toString()}');

      throw Exception('Request failed: ${e.toString()}');
    }
  }

  /// 예보버전정보 XML Data
  Future getXmlData(WeatherVersion version) async {
    late Response response;

    try {
      final nowDate = _date.nowDate(minute: version.date.month - 30);

      response = await _dio.get(
        _getURL,
        queryParameters: version.copyWith(dataType: DataType.xml, dateTime: nowDate).toJson(),
      );
    } on DioError catch (e) {
      debugPrint(e.message);
      throw Exception(e.message);
    }

    return response.data;
  }
}
