import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';

class MyLocatorRepo {
  // MyLocatorRepo._();

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 5));
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  // https://www.data.go.kr/data/15101106/openapi.do?recommendDataYn=Y
  // 7C166CC8-B88A-3DD1-816A-FF86922C17AF
  // 지번
  // https://apis.vworld.kr/coord2jibun.do?x=126.961862449327&y=37.3952998720615&output=xml&epsg=epsg:4326&apiKey=[KEY]
  // 도로
  // https://apis.vworld.kr/coord2new.do?x=126.961862449327&y=37.3952998720615&output=xml&epsg=epsg:4326&apiKey=[KEY]
  Future<ResData> getLocationName(Position position) async {
    final dio = Dio(BaseOptions(
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json'
        },
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
      var url = 'https://apis.vworld.kr/coord2jibun.do';

      Map<String, dynamic> mapData = {};
      mapData['x'] = position.latitude.toString();
      mapData['y'] = position.longitude.toString();
      mapData['output'] = 'json';
      mapData['epsg'] = 'epsg:4326';
      mapData['apiKey'] = '7C166CC8-B88A-3DD1-816A-FF86922C17AF';

      Response response = await dio.get(url, queryParameters: mapData);

      log(response.toString());
      if (response.statusCode == 200) {
        return ResData.fromJson(
            jsonEncode({'code': '00', 'data': response.data}));
      } else {
        return ResData.fromJson(jsonEncode(
            {'code': response.statusCode, 'message': response.statusMessage}));
      }
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }
}
