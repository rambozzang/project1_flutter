import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/config/vworld_api_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';

class MyLocatorRepo {
  // MyLocatorRepo._();

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best, timeLimit: const Duration(seconds: 5));
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  Future<ResData> getLocationName(Position position) async {
    final dio = Dio(BaseOptions(
        headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 60)));
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
      maxWidth: 120,
    ));

    try {
      log(position.toString());

      Map<String, dynamic> mapData = {};
      mapData['y'] = position.latitude.toString();
      mapData['x'] = position.longitude.toString();
      mapData['output'] = 'json';
      mapData['epsg'] = 'epsg:4326';
      mapData['apiKey'] = VworldApiConfig.apiKey;

      Response response = await dio.get(VworldApiConfig.apiUrl, queryParameters: mapData);

      log(response.toString());
      if (response.statusCode == 200) {
        return ResData.fromJson(jsonEncode({'code': '00', 'data': response.data}));
      } else {
        return ResData.fromJson(jsonEncode({'code': response.statusCode, 'message': response.statusMessage}));
      }
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // https://www.data.go.kr/data/15101106/openapi.do?recommendDataYn=Y
  // 7C166CC8-B88A-3DD1-816A-FF86922C17AF
  // https://api.vworld.kr/req/address?service=address&request=getcoord&version=2.0&crs=epsg:4326&address=%ED%9A%A8%EB%A0%B9%EB%A1%9C72%EA%B8%B8%2060&refine=true&simple=false&format=xml&type=road&key=[KEY]

  Future<dynamic> getPlaceAddress(Position position) async {
    String google_api_key = 'AIzaSyDgEZ4xNo5WXYthA1l8y9XLK118y6gbTpg';
    final dio = Dio(BaseOptions(
        headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 60)));
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
      maxWidth: 120,
    ));

    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$google_api_key&language=ko';
    Response response = await dio.get(url);

    if (response.statusCode == 200) {
      return ResData.fromJson(jsonEncode({'code': '00', 'data': response.data}));
    } else {
      return ResData.fromJson(jsonEncode({'code': response.statusCode, 'message': response.statusMessage}));
    }
  }
}
