import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:project1/repo/weather_gogo/models/request/midland_fct_req.dart';
import 'package:project1/repo/weather_gogo/models/request/midta_fct_req.dart';
import 'package:project1/repo/weather_gogo/models/response/midland_fct/midlan_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/midta_fct/midta_fct_res.dart';
import 'package:project1/repo/weather_gogo/sources/http_client.dart';
import 'package:project1/utils/log_utils.dart';

class MidlanFctRepo {
  final HttpService _httpService = HttpService();

  Future<MidLandFcstResponse> getMidLandFcst(MidLandFcstRequest request) async {
    final Uri url =
        Uri.parse('http://apis.data.go.kr/1360000/MidFcstInfoService/getMidLandFcst').replace(queryParameters: request.toQueryParameters());
    try {
      var response = await _httpService.getWithRetry(url);
      if (response is String) {
        response = json.decode(response);
      }

      if (response is Map<String, dynamic>) {
        if (response['response']['header']['resultCode'] == '00') {
          return MidLandFcstResponse.fromMap(response['response']['body']['items']['item'][0]);
        } else {
          lo.g('getMidLandFcst() 1 -> Error fetching data for ${response.toString()} ${url.toString()}');
          throw Exception('API 응답 코드 오류: ${response['response']['header']['resultCode']}');
        }
      } else {
        lo.g('getMidLandFcst() 2 -> Error fetching data for ${response.toString()} ${url.toString()}');
        throw Exception('예상치 못한 응답 형식');
      }

      // final response = await http.get(url);
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   final item = data['response']['body']['items']['item'][0];
      //   return MidLandFcstResponse.fromMap(item);
      // } else {
      //   lo.g('getMidLandFcst() -> Error fetching data for ${response.body.toString()} ${url.toString()}');
      //   throw Exception('Failed to load mid-term land forecast');
      // }
    } catch (e) {
      debugPrint(e.toString());
      lo.g('getMidLandFcst() 3 -> Error fetching data for ${e.toString()} ${url.toString()}');

      throw Exception('Request failed: ${e.toString()}');
    }
  }

  Future<MidTaResponse> getMidTa(MidTaRequest request) async {
    final Uri url =
        Uri.parse('http://apis.data.go.kr/1360000/MidFcstInfoService/getMidTa').replace(queryParameters: request.toQueryParameters());

    try {
      var response = await _httpService.getWithRetry(url);
      if (response is String) {
        response = json.decode(response);
      }

      if (response is Map<String, dynamic>) {
        if (response['response']['header']['resultCode'] == '00') {
          return MidTaResponse.fromMap(response['response']['body']['items']['item'][0]);
        } else {
          lo.g('getMidTa() 1 -> Error fetching data for ${response.toString()} ${url.toString()}');
          throw Exception('API 응답 코드 오류: ${response['response']['header']['resultCode']}');
        }
      } else {
        lo.g('getMidTa() 2 -> Error fetching data for ${response.toString()} ${url.toString()}');
        throw Exception('예상치 못한 응답 형식');
      }
      // final response = await http.get(url);
      // lo.g(response.body);

      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   final item = data['response']['body']['items']['item'][0];
      //   return MidTaResponse.fromMap(item);
      // } else {
      //   lo.g('getMidTa() -> Error fetching data for ${response.body.toString()} ${url.toString()}');
      //   throw Exception('Failed to load mid-term temperature forecast');
      // }
    } catch (e) {
      debugPrint(e.toString());
      lo.g('getMidTa() 3-> Error fetching data for ${e.toString()} ${url.toString()}');

      throw Exception('Request failed: ${e.toString()}');
    }
  }
}
