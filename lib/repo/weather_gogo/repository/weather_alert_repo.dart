// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:project1/app/weathergogo/services/WeatherStation_utils.dart';
import 'package:project1/repo/weather_gogo/models/request/special_alert_req.dart';
import 'package:project1/repo/weather_gogo/models/response/special_alert/special_alert_res.dart';
import 'package:project1/repo/weather_gogo/sources/http_client.dart';
import 'package:project1/utils/log_utils.dart';

/*
{
  "response": {
    "header": {
      "resultCode": "00",
      "resultMsg": "NORMAL_SERVICE"
    },
    "body": {
      "dataType": "JSON",
      "items": {
        "item": [
          {
            "stnId": "108",
            "title": "[특보] 제10-82호 : 2024.10.18.23:00 / 강풍주의보·호우주의보 해제 (*)",
            "tmFc": 202410182300,
            "tmSeq": 82
          },
          {
            "stnId": "108",
            "title": "[특보] 제10-81호 : 2024.10.18.22:30 / 호우경보 해제 (*)",
            "tmFc": 202410182230,
            "tmSeq": 81
          },
          {
            "stnId": "108",
            "title": "[특보] 제10-80호 : 2024.10.18.22:00 / 풍랑주의보 발표·호우경보·호우주의보 해제 (*)",
            "tmFc": 202410182200,
            "tmSeq": 80
          },
          {
            "stnId": "108",
            "title": "[특보] 제10-79호 : 2024.10.18.20:30 / 강풍주의보·호우주의보 발표 (*)",
            "tmFc": 202410182030,
            "tmSeq": 79
          },
          {
            "stnId": "108",
            "title": "[특보] 제10-78호 : 2024.10.18.20:10 / 호우경보 변경 (*)",
            "tmFc": 202410182010,
            "tmSeq": 78
          },
          {
            "stnId": "108",
            "title": "[특보] 제10-77호 : 2024.10.18.19:50 / 호우주의보 해제·호우주의보 발표 (*)",
            "tmFc": 202410181950,
            "tmSeq": 77
          },
          {
            "stnId": "108",
            "title": "[특보] 제10-76호 : 2024.10.18.19:10 / 호우주의보 발표 (*)",
            "tmFc": 202410181910,
            "tmSeq": 76
          },
          {
            "stnId": "108",
            "title": "[특보] 제10-75호 : 2024.10.18.18:50 / 강풍주의보·호우주의보 발표 (*)",
            "tmFc": 202410181850,
            "tmSeq": 75
          },
          {
            "stnId": "108",
            "title": "[특보] 제10-74호 : 2024.10.18.18:40 / 폭풍해일주의보 해제 (*)",
            "tmFc": 202410181840,
            "tmSeq": 74
          },
          {
            "stnId": "108",
            "title": "[특보] 제10-73호 : 2024.10.18.18:30 / 호우주의보 발표 (*)",
            "tmFc": 202410181830,
            "tmSeq": 73
          }
        ]
      },
      "pageNo": 1,
      "numOfRows": 10,
      "totalCount": 27
    }
  }
}
*/
class WeatherAlertRepo {
  final HttpService _httpService = HttpService();

  Future<WeatherAlertRes> getWeatherAlerts(SpecialAlertReq specialAlertReq) async {
    final Uri url =
        Uri.parse('http://apis.data.go.kr/1360000/WthrWrnInfoService/getWthrWrnList').replace(queryParameters: specialAlertReq.toMap());

    lo.g("00000 url :  ${url.toString()}");

    try {
      var response = await _httpService.getWithRetry(url);
      lo.g(response.toString());
      if (response is String) {
        response = json.decode(response);
      }

      if (response is Map<String, dynamic>) {
        if (response['response']['header']['resultCode'] == '00') {
          lo.g("2222");

          lo.g(response.toString());

          return WeatherAlertRes.fromMap(response['response']['body']['items']['item'][0]);
        } else {
          lo.g('getWeatherAlerts() 1 -> Error fetching data for ${response.toString()} ${url.toString()}');
          throw Exception('API 응답 코드 오류: ${response['response']['header']['resultCode']}');
        }
      } else {
        lo.g('getWeatherAlerts() 2 -> Error fetching data for ${response.toString()} ${url.toString()}');
        throw Exception('예상치 못한 응답 형식');
      }
    } catch (e) {
      debugPrint(e.toString());
      lo.g('getWeatherAlerts() 3-> Error fetching data for ${e.toString()} ${url.toString()}');

      throw Exception('getWeatherAlerts Request failed: ${e.toString()}');
    }
  }

  final String baseUrl = 'http://apis.data.go.kr/1360000/WthrWrnInfoService';
  String serviceKey = 'CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D';

  Future<List<WeatherAlertRes>> getWeatherAlerts2() async {
    final Map<String, String> mapData = await WeatherStationFinder.findNearestStation(37.5665, 126.9780);
    // 날짜 범위는 임의로 설정 오늘 부터 +6일까지

    final today = DateTime.now();
    final to = today.add(const Duration(days: 6));
    final fromTmFc = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    final toTmFc = '${to.year}${to.month.toString().padLeft(2, '0')}${to.day.toString().padLeft(2, '0')}';
    final url = Uri.parse('$baseUrl/getWthrWrnList'
        '?serviceKey=$serviceKey'
        '&numOfRows=10'
        '&pageNo=1'
        '&dataType=JSON'
        '&stnId=${mapData['stnId']}'
        '&fromTmFc=$fromTmFc'
        '&toTmFc=$toTmFc');

// https://apis.data.go.kr/1360000/WthrWrnInfoService/getWthrWrnList?
// serviceKey=CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D
// &pageNo=1
// &numOfRows=10
// &dataType=XML
// &stnId=184
// &fromTmFc=20170601
// &toTmFc=20170607
// http://apis.data.go.kr/1360000/WthrWrnInfoService/getWthrWrnList?serviceKey=CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==&numOfRows=10&pageNo=1&dataType=JSON

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final items = jsonResponse['response']['body']['items'];

      return List<WeatherAlertRes>.from(items.map((item) => WeatherAlertRes.fromJson(item)));
    } else {
      throw Exception('Failed to load weather alerts');
    }
  }
}
