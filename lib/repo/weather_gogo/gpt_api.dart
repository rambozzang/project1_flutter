import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:project1/repo/api/auth_dio.dart';

class GptApi {
  Future<void> fetchPast24HoursWeather(double lat, double lon) async {
    // 기상청 API 키
    // String apiKey = 'CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==';
    String apiKey = 'CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D';

    // 현재 시간
    DateTime now = DateTime.now();

    // 위도와 경도를 격자(X, Y) 좌표로 변환
    Map<String, int> coords = convertToGrid(lat, lon);
    int x = coords['x']!;
    int y = coords['y']!;

    // 과거 24시간 동안의 데이터를 저장할 리스트
    List<Map<String, dynamic>> past24HoursWeather = [];

    Dio dio = await AuthDio.instance.getNoAuthDio();

    // 현재 시간부터 24시간 전까지 3시간 단위로 데이터를 가져옴
    for (int i = 0; i < 24; i += 3) {
      DateTime dateTime = now.subtract(Duration(hours: i));
      String baseDate = '${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}';
      String baseTime = '${(dateTime.hour ~/ 3 * 3).toString().padLeft(2, '0')}00';

      // API URL 구성
      String url = 'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst'
          '?serviceKey=$apiKey'
          '&numOfRows=10'
          '&pageNo=1'
          '&dataType=JSON'
          '&base_date=$baseDate'
          '&base_time=$baseTime'
          '&nx=$x'
          '&ny=$y';

      // API 호출
      try {
        Response response = await dio.get(url);
        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.data);
          if (data['response']['header']['resultCode'] == '00') {
            List<dynamic> items = data['response']['body']['items']['item'];
            past24HoursWeather.add({
              'time': '$baseDate $baseTime',
              'data': items,
            });
          } else {
            print('Error: ${data['response']['header']['resultMsg']}');
          }
        } else {
          print('Failed to fetch weather data');
        }
      } catch (e) {
        print('Error: $e');
      }
    }

    // 결과 출력
    for (var weather in past24HoursWeather) {
      print('Time: ${weather['time']}');
      for (var item in weather['data']) {
        print('Category: ${item['category']}, Value: ${item['obsrValue']}');
      }
    }
  }

// 위도와 경도를 격자(X, Y) 좌표로 변환하는 함수
  Map<String, int> convertToGrid(double lat, double lon) {
    const double RE = 6371.00877; // 지도 반경
    const double GRID = 5.0; // 격자 간격
    const double SLAT1 = 30.0; // 투영 위도1
    const double SLAT2 = 60.0; // 투영 위도2
    const double OLON = 126.0; // 기준점 경도
    const double OLAT = 38.0; // 기준점 위도
    const double XO = 43; // 기준점 X좌표
    const double YO = 136; // 기준점 Y좌표

    double DEGRAD = pi / 180.0;
    double RADDEG = 180.0 / pi;

    double re = RE / GRID;
    double slat1 = SLAT1 * DEGRAD;
    double slat2 = SLAT2 * DEGRAD;
    double olon = OLON * DEGRAD;
    double olat = OLAT * DEGRAD;

    double sn = tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5);
    sn = log(cos(slat1) / cos(slat2)) / log(sn);
    double sf = tan(pi * 0.25 + slat1 * 0.5);
    sf = pow(sf, sn) * cos(slat1) / sn;
    double ro = tan(pi * 0.25 + olat * 0.5);
    ro = re * sf / pow(ro, sn);

    double ra = tan(pi * 0.25 + lat * DEGRAD * 0.5);
    ra = re * sf / pow(ra, sn);
    double theta = lon * DEGRAD - olon;
    if (theta > pi) theta -= 2.0 * pi;
    if (theta < -pi) theta += 2.0 * pi;
    theta *= sn;

    int x = (ra * sin(theta) + XO + 0.5).floor();
    int y = (ro - ra * cos(theta) + YO + 0.5).floor();
    return {'x': x, 'y': y};
  }
}
