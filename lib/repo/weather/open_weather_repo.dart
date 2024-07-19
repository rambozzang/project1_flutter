import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:project1/config/open_weather_api_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';

import 'package:project1/utils/log_utils.dart';

class OpenWheatherRepo {
  Future<ResData> getWeather(LatLng position) async {
    lo.g('OpenWheatherRepo : getWeather() 1');
    final dio = await AuthDio.instance.getNoAuthDio();
    // final dio = await AuthDio.instance.getNoAuthCathDio(cachehour: 1);
    try {
      // final dio = Dio();
      lo.g('OpenWheatherRepo : getWeather() 2');

      Response response = await dio.get(
        OpenWeatherApiConfig.apiUrl,
        queryParameters: {
          'lang': 'kr',
          'lat': position.latitude,
          'lon': position.longitude,
          'units': 'metric',
          'appid': OpenWeatherApiConfig.apiKey,
        },
      );
      lo.g('OpenWheatherRepo : getWeather() 3 ${response.statusCode} : ${response.data}');

      // 304도 추가 캐싱 떄문에 304로 넘어온다. 200이랑 똑같이 처리해야함
      // 왜냐면 200하고 결과가 같기 때문에
      if (response.statusCode == 200) {
        lo.g('OpenWheatherRepo : getWeather() 3-2 ${response.data}');
        return ResData.fromJson(jsonEncode({'code': '00', 'data': response.data}));
      }

      if (response.statusCode == 304) {
        var cacheData = response.data;
        lo.g('OpenWheatherRepo : getWeather() 3-1 ${cacheData}');
        ResData res = ResData();
        res.code = '00';
        res.data = cacheData;

        return res;
      }

      return ResData.fromJson(jsonEncode({'code': response.statusCode, 'message': response.statusMessage}));
    } on DioException catch (e) {
      lo.g('OpenWheatherRepo : getWeather() 4 ${e}');
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  Future<ResData> getOneCallWeather(LatLng position) async {
    // final dio = await AuthDio.instance.getNoAuthCathDio(cachehour: 1);
    final dio = await AuthDio.instance.getNoAuthDio();
    try {
      Response response = await dio.get(
        OpenWeatherApiConfig.oneCallUrl,
        queryParameters: {
          'lang': 'kr',
          'lat': position.latitude,
          'lon': position.longitude,
          'units': 'metric',
          'exclude': 'minutely,alerts', //제외 정보
          'appid': OpenWeatherApiConfig.apiKey,
        },
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Cache-Control': 'max-age=604800',
            'Etg': '${position.latitude}${position.longitude}',
          },
        ),
      );

      log(response.toString());
      if (response.statusCode == 200) {
        return ResData.fromJson(jsonEncode({'code': '00', 'data': response.data}));
      } else {
        return ResData.fromJson(jsonEncode({'code': response.statusCode, 'message': response.statusMessage}));
      }
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  Map<dynamic, dynamic> weatherDescKo = {
    201: '가벼운 비를 동반한 천둥구름',
    200: '비를 동반한 천둥구름',
    202: '폭우를 동반한 천둥구름',
    210: '약한 천둥구름',
    211: '천둥구름',
    212: '강한 천둥구름',
    221: '불규칙적 천둥구름',
    230: '약한 연무를 동반한 천둥구름',
    231: '연무를 동반한 천둥구름',
    232: '강한 안개비를 동반한 천둥구름',
    300: '가벼운 안개비',
    301: '안개비',
    302: '강한 안개비',
    310: '가벼운 적은비',
    311: '적은비',
    312: '강한 적은비',
    313: '소나기와 안개비',
    314: '강한 소나기와 안개비',
    321: '소나기',
    500: '악한 비',
    501: '중간 비',
    502: '강한 비',
    503: '매우 강한 비',
    504: '극심한 비',
    511: '우박',
    520: '약한 소나기 비',
    521: '소나기 비',
    522: '강한 소나기 비',
    531: '불규칙적 소나기 비',
    600: '가벼운 눈',
    601: '눈',
    602: '강한 눈',
    611: '진눈깨비',
    612: '소나기 진눈깨비',
    615: '약한 비와 눈',
    616: '비와 눈',
    620: '약한 소나기 눈',
    621: '소나기 눈',
    622: '강한 소나기 눈',
    701: '박무',
    711: '연기',
    721: '연무',
    731: '모래 먼지',
    741: '안개',
    751: '모래',
    761: '먼지',
    762: '화산재',
    771: '돌풍',
    781: '토네이도',
    800: '구름 한 점 없는 맑은 하늘',
    801: '약간의 구름이 낀 하늘',
    802: '드문드문 구름이 낀 하늘',
    803: '구름이 거의 없는 하늘',
    804: '구름으로 뒤덮인 흐린 하늘',
    900: '토네이도',
    901: '태풍',
    902: '허리케인',
    903: '한랭',
    904: '고온',
    905: '바람부는',
    906: '우박',
    951: '바람이 거의 없는',
    952: '약한 바람',
    953: '부드러운 바람',
    954: '중간 세기 바람',
    955: '신선한 바람',
    956: '센 바람',
    957: '돌풍에 가까운 센 바람',
    958: '돌풍',
    959: '심각한 돌풍',
    960: '폭풍',
    961: '강한 폭풍',
    962: '허리케인',
  };
}
