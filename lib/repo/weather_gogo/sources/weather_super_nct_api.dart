import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/utils/log_utils.dart';

import '../adapter/adapter.dart';
import '../models/models.dart';
import 'package:http/http.dart' as http;

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
    final dio =
        isCache ? await AuthDio.instance.getNoAuthCathDio(debug: true, cachehour: 1) : await AuthDio.instance.getNoAuthDio(debug: true);
    final now = DateTime.now();

    // 매시 40분 보다 작으면 1시간전으로 보내야 한다.
    int startHour = now.minute <= 40 ? 0 : 1;
    int endHour = now.hour == 0 ? 24 : 25;

    List<Future<List<dynamic>>> futures = [];

    for (int i = startHour; i < endHour; i++) {
      futures.add(_fetchData(dio, now, i, weather));
    }

    try {
      List<List<dynamic>> results = await Future.wait(futures);
      return results.expand((x) => x).toList();
    } catch (e) {
      lo.g('어제 날씨 가져오기 실패!!!!!!!!');
      debugPrint(e.toString());
      throw Exception('날씨 데이터 가져오기 실패');
    }
  }

  Future<List<dynamic>> _fetchData(Dio dio, DateTime now, int hoursAgo, Weather weather) async {
    DateTime dateTime = now.subtract(Duration(hours: hoursAgo));
    String baseDate = '${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}';
    String baseTime = '${dateTime.hour.toString().padLeft(2, '0')}00';

    if (baseTime == '0000') {
      DateTime dateTime2 = now.subtract(const Duration(days: 1));
      baseDate = '${dateTime2.year}${dateTime2.month.toString().padLeft(2, '0')}${dateTime2.day.toString().padLeft(2, '0')}';
    }

    DateTime nowDate = DateTime.parse('$baseDate $baseTime');
    var json = weather.copyWith(dateTime: nowDate).toJson();
    json['base_time'] = baseTime == '0000' ? '2400' : baseTime;

    try {
      final response = await dio.get(_getURL, queryParameters: json);

      // Map<String, dynamic?> query = {
      //   "ServiceKey": weather.serviceKey,
      //   "pageNo": weather.pageNo.toString(),
      //   "numOfRows": weather.numOfRows.toString(),
      //   "dataType": "JSON",
      //   "base_date": baseDate.toString(),
      //   "base_time": baseTime.toString(),
      //   "nx": weather.nx.toString(),
      //   "ny": weather.ny.toString()
      // };
      // Uri url = Uri.https('apis.data.go.kr', '/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst', query);

      // final http.Response response = await http.get(url, headers: {
      //   "Content-Type": "application/json",
      //   "Accept": "application/json",
      //   'Cache-Control': 'max-age=604800',
      //   'Last-Modified': _formatHttpDate(),
      // });
      // lo.g("http : ${response.toString()}");
      // lo.g("http : ${response.body.toString()}");
      if (response.statusCode == 200 || response.statusCode == 304) {
        // Dio 사용시
        Map<String, dynamic> data = response.data;
        // http 사용시
        // Map<String, dynamic> data = jsonDecode(response.body);
        if (data['response']['header']['resultCode'] == '00') {
          return data['response']['body']['items']['item'];
        }
      }
    } catch (e) {
      lo.g('Error fetching data for $baseDate $baseTime: ${e.toString()}');
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
