import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/weather_accu/accu_res_data.dart';
import 'package:project1/utils/log_utils.dart';

// https://developer.accuweather.com/weather-icons
// https://developer.accuweather.com/accuweather-current-conditions-api/apis/get/currentconditions/v1/%7BlocationKey%7D
// 12시간 까지만 무료 => https://developer.accuweather.com/packages
class AccuRepo {
  final apikey = '9Dpql374txlRZGgiECCDS2gGcvuqdmeT';
  final baseUrl = 'http://dataservice.accuweather.com';

  // location
  Future<String> getLocation(LatLng latlng) async {
    final dio = await AuthDio.instance.getNoAuthDio();
    // http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=${process.env.NEXT_PUBLIC_ACCUWEATHER_KEY}&q=${lat}%2C${lng}&language=ko-kr
    try {
      Response res = await dio
          .get('$baseUrl/locations/v1/cities/geoposition/search?apikey=$apikey&q=${latlng.latitude}%2C${latlng.longitude}&language=ko-kr');
      if (res.statusCode != 200) {
        lo.g('res.statusCode : ${res.statusCode}');
        return '';
      }
      return res.data['ParentCity']['Key'];
    } catch (e) {
      lo.g(e.toString());
      return '';
    }
  }

  // current weather
  /*
  [
  {
    "LocalObservationDateTime": "2024-07-08T17:17:00+09:00",
    "EpochTime": 1720426620,
    "WeatherText": "구름과 해",
    "WeatherIcon": 4,
    "HasPrecipitation": false,
    "PrecipitationType": null,
    "IsDayTime": true,
    "Temperature": {
      "Metric": {
        "Value": 24.5,
        "Unit": "C",
        "UnitType": 17
      },
      "Imperial": {
        "Value": 76,
        "Unit": "F",
        "UnitType": 18
      }
    },
    "MobileLink": "http://www.accuweather.com/ko/kr/seodaemun-gu/226002/current-weather/226002",
    "Link": "http://www.accuweather.com/ko/kr/seodaemun-gu/226002/current-weather/226002"
  }
]*/
  Future<List<AccuResData>> getCurrentWeather(String locationKey) async {
    final dio = await AuthDio.instance.getNoAuthDio();
    try {
      // 현재 날씨
      Response res = await dio.get('$baseUrl/currentconditions/v1/$locationKey?apikey=$apikey&language=ko-kr');
      if (res.statusCode != 200) {
        lo.g('res.statusCode : ${res.statusCode}');
      }
      lo.g('res : $res');

      List<AccuResData> list = [];
      list = (res.data as List).map((e) => AccuResData.fromMap(e)).toList();

      return list;
    } catch (e) {
      print(e);
      return [];
    }
  }

  // 12시간 예보
  Future<List<AccuResData>> get12HoursWeather(String locationKey) async {
    final dio = await AuthDio.instance.getNoAuthDio();
    try {
      // 24시 예보
      Response res = await dio.get('$baseUrl/forecasts/v1/hourly/12hour/$locationKey?apikey=$apikey&language=ko-kr&metric=true');
      if (res.statusCode != 200) {
        lo.g('res.statusCode : ${res.statusCode}');
      }
      List<AccuResData> list = [];
      list = (res.data as List).map((e) => AccuResData.fromMap(e)).toList();
      lo.g('res : $res');
      return list;
    } catch (e) {
      lo.g(e.toString());
      return [];
    }
  }
}
