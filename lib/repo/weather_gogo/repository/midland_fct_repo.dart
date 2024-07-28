import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:project1/repo/weather_gogo/models/request/midland_fct_req.dart';
import 'package:project1/repo/weather_gogo/models/request/midta_fct_req.dart';
import 'package:project1/repo/weather_gogo/models/response/midland_fct/midlan_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/midta_fct/midta_fct_res.dart';
import 'package:project1/utils/log_utils.dart';

class MidlanFctRepo {
  Future<MidLandFcstResponse> getMidLandFcst(MidLandFcstRequest request) async {
    final Uri url =
        Uri.parse('http://apis.data.go.kr/1360000/MidFcstInfoService/getMidLandFcst').replace(queryParameters: request.toQueryParameters());

    lo.g(url.toString());
    final response = await http.get(url);
    lo.g(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final item = data['response']['body']['items']['item'][0];
      return MidLandFcstResponse.fromMap(item);
    } else {
      throw Exception('Failed to load mid-term land forecast');
    }
  }

  Future<MidTaResponse> getMidTa(MidTaRequest request) async {
    final Uri url =
        Uri.parse('http://apis.data.go.kr/1360000/MidFcstInfoService/getMidTa').replace(queryParameters: request.toQueryParameters());

    lo.g(url.toString());
    final response = await http.get(url);
    lo.g(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final item = data['response']['body']['items']['item'][0];
      return MidTaResponse.fromMap(item);
    } else {
      throw Exception('Failed to load mid-term temperature forecast');
    }
  }
}
