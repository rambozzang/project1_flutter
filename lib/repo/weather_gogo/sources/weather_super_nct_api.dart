import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/utils/log_utils.dart';

import '../adapter/adapter.dart';
import '../models/models.dart';
import 'weather_client.dart';

class NctAPI {
  // late Dio  AuthDio.instance.getNoAuthCathDio();
  final _date = DateTimeAdapter();

  //

  // NctAPI({bool? isLog, PrettyDioLogger? customLogger}) asyn {
  //   //  AuthDio.instance.getNoAuthCathDio() = ApiClient.createDio(
  //   //   isLog: isLog ?? true,
  //   //   customLogger: customLogger,
  //   // );
  //    AuthDio.instance.getNoAuthCathDio() = await  AuthDio.instance.getNoAuthCathDio();
  // }

  static const _getURL = 'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst';

  // 초단기 실황 과거 24시간 내정보
  Future<List<dynamic>> getYesterDayJsonData(Weather weather, bool isChache) async {
    late Response response;
    List<dynamic> resultList = [];
    final dio = isChache ? await AuthDio.instance.getNoAuthCathDio(debug: true) : await AuthDio.instance.getNoAuthDio(debug: true);

    try {
      final now = DateTime.now();

      // for (int i = 0; i < 24; i += 3) {
      //   DateTime dateTime = now.subtract(Duration(hours: i));
      //   String baseDate = '${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}';
      //   String baseTime = '${(dateTime.hour ~/ 3 * 3).toString().padLeft(2, '0')}00';

      // 매시 40분 보다 작으면 1시간전으로 보내야 한다.
      int j = now.minute <= 40 ? 0 : 1;
      int max = now.hour == 0 ? 24 : 25;

      for (int i = j; i < 25; i++) {
        DateTime dateTime = now.subtract(Duration(hours: i));

        lo.g('dateTime $i: $dateTime');
        String baseDate = '${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}';
        String baseTime = '${dateTime.hour.toString().padLeft(2, '0')}00';
        lo.g('dateTime 1111111');
        // 00000 즉24시면 하루전달로 셋팅후 2400 으로 보내야 한다.
        if (baseTime == '0000') {
          DateTime dateTime2 = now.subtract(const Duration(days: 1));
          baseDate = '${dateTime2.year}${dateTime2.month.toString().padLeft(2, '0')}${dateTime2.day.toString().padLeft(2, '0')}';
        }
        lo.g('dateTime 2222');

        DateTime nowDate = DateTime.parse('$baseDate $baseTime');
        Future.delayed(const Duration(milliseconds: 400));
        lo.g('dateTime 33333');

        var json = weather.copyWith(dateTime: nowDate).toJson();
        lo.g('json $i: $json');

        json['base_time'] = baseTime == '0000' ? '2400' : baseTime;
        lo.g('dateTime 444444');

        response = await dio.get(
          _getURL,
          queryParameters: json,
        );
        lo.g('dateTime 555555');

        if (response.statusCode == 200 || response.statusCode == 304) {
          Map<String, dynamic> data = response.data;
          if (data['response']['header']['resultCode'] == '00') {
            List<dynamic> items = data['response']['body']['items']['item'];

            resultList.addAll(items);
          } else {
            print('Error: ${data['response']['header']['resultMsg']}');
            // throw Exception('Error: ${data['response']['header']['resultMsg']}');
          }
        } else {
          print('어제 날씨 가져오기 실패!!!!!!!!');
        }
      }
    } on DioException catch (e) {
      lo.g('dateTime 6666666666666');

      debugPrint(e.message);
      throw Exception(e.message);
    }

    return resultList;
  }

  /// 초단기실황정보 Json Data
  Future getJsonData(Weather weather) async {
    late Response response;
    final dio = await AuthDio.instance.getNoAuthCathDio(debug: true);

    try {
      final nowDate = _date.getSuperNctDate(weather.date);
      response = await dio.get(
        _getURL,
        queryParameters: weather.copyWith(dateTime: nowDate).toJson(),
      );
    } on DioException catch (e) {
      debugPrint(e.message);
      throw Exception(e.message);
    }

    return response.data;
  }

  /// 초단기실황정보 XML Data
  Future getXmlData(Weather weather) async {
    late Response response;
    final dio = await AuthDio.instance.getNoAuthCathDio(debug: true);

    try {
      final nowDate = _date.getSuperNctDate(weather.date);
      response = await dio.get(
        _getURL,
        queryParameters: weather.copyWith(dataType: DataType.xml, dateTime: nowDate).toJson(),
      );
    } on DioException catch (e) {
      debugPrint(e.message);
      throw Exception(e.message);
    }

    return response.data;
  }
}
