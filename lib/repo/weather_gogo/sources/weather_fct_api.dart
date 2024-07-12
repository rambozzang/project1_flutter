import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../adapter/adapter.dart';
import '../models/models.dart';
import 'weather_client.dart';

class FctAPI {
  late Dio _dio;
  final _date = DateTimeAdapter();

  FctAPI({bool? isLog, PrettyDioLogger? customLogger}) {
    _dio = ApiClient.createDio(
      isLog: isLog ?? true,
      customLogger: customLogger,
    );
  }

  static const _getURL = '/getVilageFcst';

  /// 단기예보정보 Json Data
  Future getJsonData(Weather weather) async {
    late Response response;

    try {
      final nowDate = _date.getFctDate(weather.date);
      response = await _dio.get(
        _getURL,
        queryParameters: weather.copyWith(dateTime: nowDate).toJson(),
      );
    } on DioError catch (e) {
      debugPrint(e.message);
      throw Exception(e.message);
    }

    return response.data;
  }

  /// 단기예보정보 XML Data
  Future getXmlData(Weather weather) async {
    late Response response;

    try {
      final nowDate = _date.getFctDate(weather.date);
      response = await _dio.get(
        _getURL,
        queryParameters: weather
            .copyWith(dataType: DataType.xml, dateTime: nowDate)
            .toJson(),
      );
    } on DioError catch (e) {
      debugPrint(e.message);
      throw Exception(e.message);
    }

    return response.data;
  }
}
