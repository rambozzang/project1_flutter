import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/weather_gogo/sources/http_client.dart';
import 'package:project1/utils/log_utils.dart';
import 'dart:convert' as con;
import '../adapter/adapter.dart';
import '../models/models.dart';
import 'package:http/http.dart' as http;

class NctAPI {
  // late Dio  AuthDio.instance.getNoAuthCathDio();
  final _date = DateTimeAdapter();

  final HttpService _httpService = HttpService();

  //

  // NctAPI({bool? isLog, PrettyDioLogger? customLogger}) asyn {
  //   //  AuthDio.instance.getNoAuthCathDio() = ApiClient.createDio(
  //   //   isLog: isLog ?? true,
  //   //   customLogger: customLogger,
  //   // );
  //    AuthDio.instance.getNoAuthCathDio() = await  AuthDio.instance.getNoAuthCathDio();
  // }

  static const _baseURL = 'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';

  static const _getURL = '$_baseURL/getUltraSrtNcst';

  // 초단기 실황 과거 24시간 내정보
  // Future<List<dynamic>> getYesterDayJsonData(Weather weather, bool isChache) async {
  //   late Response response;
  //   List<dynamic> resultList = [];
  //   final dio = isChache ? await AuthDio.instance.getNoAuthCathDio(debug: true) : await AuthDio.instance.getNoAuthDio(debug: true);

  //   try {
  //     final now = DateTime.now();

  //     // 매시 40분 보다 작으면 1시간전으로 보내야 한다.
  //     int j = now.minute <= 40 ? 0 : 1;
  //     int max = now.hour == 0 ? 24 : 25;

  //     for (int i = j; i < 25; i++) {
  //       DateTime dateTime = now.subtract(Duration(hours: i));

  //       lo.g('dateTime $i: $dateTime');
  //       String baseDate = '${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}';
  //       String baseTime = '${dateTime.hour.toString().padLeft(2, '0')}00';
  //       // 00000 즉24시면 하루전달로 셋팅후 2400 으로 보내야 한다.
  //       if (baseTime == '0000') {
  //         DateTime dateTime2 = now.subtract(const Duration(days: 1));
  //         baseDate = '${dateTime2.year}${dateTime2.month.toString().padLeft(2, '0')}${dateTime2.day.toString().padLeft(2, '0')}';
  //       }
  //       DateTime nowDate = DateTime.parse('$baseDate $baseTime');
  //       // sleep(const Duration(milliseconds: 50));
  //       var json = weather.copyWith(dateTime: nowDate).toJson();
  //       json['base_time'] = baseTime == '0000' ? '2400' : baseTime;
  //       response = await dio.get(
  //         _getURL,
  //         queryParameters: json,
  //       );
  //       if (response.statusCode == 200 || response.statusCode == 304) {
  //         Map<String, dynamic> data = response.data;
  //         if (data['response']['header']['resultCode'] == '00') {
  //           List<dynamic> items = data['response']['body']['items']['item'];
  //           resultList.addAll(items);
  //         } else {}
  //       } else {
  //         lo.g('어제 날씨 가져오기 실패!!!!!!!!');
  //       }
  //     }
  //   } on DioException catch (e) {
  //     lo.g('dateTime 6666666666666');
  //     debugPrint(e.message);
  //     throw Exception(e.message);
  //   }

  //   return resultList;
  // }
  Future<List<dynamic>> getYesterDayJsonData(Weather weather, bool isCache) async {
    final now = DateTime.now();
    final startTime = now.minute <= 40 ? now.subtract(const Duration(hours: 24)) : now.subtract(const Duration(hours: 23));

    List<Future<List<dynamic>>> futures = [];

    try {
      final stopwatch = Stopwatch()..start();
      lo.g('===================== getYesterDayJsonData start ');

      for (int i = 0; i < 24; i++) {
        futures.add(_fetchData(startTime.add(Duration(hours: i)), weather));
      }
      List<List<dynamic>> results = await Future.wait(futures);

      // results 가 24개의 리스트가 아니면 나머지를 다시 요청해서 24개로 만든다.
      if (results.length <= 22) {
        results = await _fillMissingData(results, startTime, weather);
      }
      if (results.length <= 22) {
        results = await _fillMissingData(results, startTime, weather);
      }
      lo.g('===================== getYesterDayJsonData end  ${stopwatch.elapsedMilliseconds}ms , list : ${results.length}');
      return results.expand((x) => x).toList();
    } catch (e) {
      lo.g('어제 날씨 가져오기 실패!!!!!!!!');
      debugPrint(e.toString());
      throw Exception('날씨 데이터 가져오기 실패');
    }
  }

  Future<List<List<dynamic>>> _fillMissingData(List<List<dynamic>> results, DateTime startTime, Weather weather) async {
    List<Future<List<dynamic>>> futures = [];
    for (int i = 0; i < 25; i++) {
      if (results.where((element) => element.isNotEmpty).length >= 24) {
        break;
      }
      if (results[i].isEmpty) {
        lo.g('getYesterDayJsonData() -> 추가 호출 () : ${startTime.add(Duration(hours: i))}');
        futures.add(_fetchData(startTime.add(Duration(hours: i)), weather));
      }
    }
    List<List<dynamic>> additionalResults = await Future.wait(futures);
    results.addAll(additionalResults);
    return results;
  }

  Future<List<dynamic>> _fetchData(DateTime dateTime, Weather weather) async {
    // weather 객체를 JSON으로 변환
    Map<String, dynamic> weatherJson = weather.copyWith(dateTime: dateTime).toJson();
    // 모든 값을 문자열로 변환
    Map<String, String> queryParams = weatherJson.map((key, value) => MapEntry(key, value.toString()));
    final uri = Uri.parse(_getURL).replace(queryParameters: queryParams);
    // lo.g('getYesterDayJsonData() -> ${uri.toString()} ');
    try {
      var response = await _httpService.getWithRetry(uri);
      if (response is String) {
        response = json.decode(response);
      }

      if (response is Map<String, dynamic>) {
        if (response['response']['header']['resultCode'] == '00') {
          return response['response']['body']['items']['item'];
        } else {
          return [];
          // throw Exception('API 응답 코드 오류: ${response['response']['header']['resultCode']}');
        }
      } else {
        throw Exception('예상치 못한 응답 형식');
      }

      // final response = await http.get(uri);

      // if (response.statusCode == 200 ) {
      //   Map<String, dynamic> data = con.json.decode(response.body);
      //   if (data['response']['header']['resultCode'] == '00') {
      //     return data['response']['body']['items']['item'];
      //   }
      // }

      // final response = await dio.get(_getURL, queryParameters: json);
      // lo.g('response : ${response.data}');
      // if (response.statusCode == 200 || response.statusCode == 304) {
      //   Map<String, dynamic> data = response.data;
      //   if (data['response']['header']['resultCode'] == '00') {
      //     return data['response']['body']['items']['item'];
      //   }
      // }
      // return [];
    } catch (e) {
      lo.g('getYesterDayJsonData() -> Error fetching data for ${e.toString()} ${uri.toString()}');
      // Future.delayed(const Duration(milliseconds: 200), () {
      _fetchData(dateTime, weather);
      //   return;
      // });
    }
    return [];
  }

  String _formatHttpDate() {
    // Format the date as per HTTP-date format defined in RFC7231
    // Example: Tue, 15 Nov 1994 08:12:31 GMT
    DateTime date = DateTime.now().subtract(const Duration(days: 7));
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekDay = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekDay, ${date.day.toString().padLeft(2, '0')} $month ${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')} GMT';
  }

  /// 초단기실황정보 Json Data
  Future getJsonDataDio(Weather weather) async {
    late Response response;
    final dio = await AuthDio.instance.getNoAuthDio(debug: true);

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

  /// 초단기실황정보 Json Data
  Future getJsonData(Weather weather) async {
    late http.Response response;
    late Uri uri;

    try {
      final nowDate = _date.getSuperNctDate(weather.date);

      // weather 객체를 JSON으로 변환
      Map<String, dynamic> weatherJson = weather.copyWith(dateTime: nowDate).toJson();
      // 모든 값을 문자열로 변환
      Map<String, String> queryParams = weatherJson.map((key, value) => MapEntry(key, value.toString()));

      uri = Uri.parse(_getURL).replace(queryParameters: queryParams);
      lo.g('uri :$uri');
      // response = await dio.get(
      //   _getURL,
      //   queryParameters: weather.copyWith(dateTime: nowDate).toJson(),
      // );

      response = await http.get(uri);
      return json.decode(response.body);
    } on DioException catch (e) {
      debugPrint(e.toString());
      lo.g('NctAPI() -> Error fetching data for ${e.toString()} ${uri.toString()}');

      throw Exception('Request failed: ${e.toString()}');
    }
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
