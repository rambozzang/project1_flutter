import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_caching.dart';
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
  final WeatherCache _cache = WeatherCache();

  void saveYesterDayJsonData(LatLng latLng, List<dynamic> list) async {
    try {
      List<ItemSuperNct> itemList = [];
      // 캐쉬에 저장
      itemList = list.map((data) => ItemSuperNct.fromJson(data)).toList();

      lo.g('saveYesterDayJsonData() -> ${itemList.length}');

      await _cache.saveYesterDayWeatherData(latLng, ForecastType.superNctYesterDay, itemList);
    } catch (e) {
      lo.g('saveYesterDayJsonData() -> Error saving data for ${e.toString()}');
    }
  }

  // 어제 날씨 가져오기
  Future<List<dynamic>> getYesterDayJsonData(Weather weather, bool isCache) async {
    final now = DateTime.now();
    final startTime = now.minute <= 40 ? now.subtract(const Duration(hours: 24)) : now.subtract(const Duration(hours: 23));
    LatLng latLng = LatLng(weather.nx.toDouble(), weather.ny.toDouble());

    List<Future<List<dynamic>>> futures = [];

    try {
      final stopwatch = Stopwatch()..start();
      lo.g('===================== getYesterDayJsonData start ');

      for (int i = 0; i < 24; i++) {
        futures.add(_fetchData(startTime.add(Duration(hours: i)), weather));
      }
      List<List<dynamic>> results = await Future.wait(futures);

      lo.g("getYesterDayJsonData() results: ${results.length}");

      // results 가 24개의 리스트가 아니면 나머지를 다시 요청해서 24개로 만든다.
      if (results.length <= 22) {
        results = await _fillMissingData(results, startTime, weather);
      }
      if (results.length <= 22) {
        results = await _fillMissingData(results, startTime, weather);
      }
      lo.g("0000");

      if (results.length <= 22) {
        throw Exception('날씨 데이터 가져오기 실패');
      }
      lo.g("111111111111111111111111111111111111");

      // try {
      //   // 데이터가 있는건 캐쉬에 저장
      //   saveYesterDayJsonData(latLng, results.expand((x) => x).toList());
      // } catch (e) {
      //   lo.g('getYesterDayJsonData() -> Error saving data for ${e.toString()}');
      // }
      lo.g("2222222222222222222222");

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

    LatLng latLng = LatLng(weather.nx.toDouble(), weather.ny.toDouble());

    final uri = Uri.parse(_getURL).replace(queryParameters: queryParams);
    // lo.g('getYesterDayJsonData() -> ${uri.toString()} ');
    try {
      var response = await _httpService.getWithRetry(uri);
      if (response is String) {
        response = json.decode(response);
      }

      if (response is Map<String, dynamic>) {
        if (response['response']['header']['resultCode'] == '00') {
          List<dynamic> results = response['response']['body']['items']['item'] as List<dynamic>;

          return results;
        }
        return [];
      }
      return [];
    } catch (e) {
      lo.g('getYesterDayJsonData() -> Error fetching data for ${e.toString()} ${uri.toString()}');
      return [];
    }
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
