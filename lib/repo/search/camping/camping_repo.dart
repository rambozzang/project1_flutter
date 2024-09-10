import 'dart:io';

import 'package:dio/dio.dart';

import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/search/camping/camping_req_data.dart';
import 'package:project1/repo/search/camping/camping_res_data.dart';
import 'package:project1/repo/search/school/school_req_data.dart';
import 'package:project1/repo/search/school/school_res_data.dart';
import 'package:project1/utils/log_utils.dart';

class CampingRepo {
  // api 상세 정보 : https://www.data.go.kr/data/15101933/openapi.do#/API%20%EB%AA%A9%EB%A1%9D/searchList

  // String apiKey = 'CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==';
  String apiKey = 'CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D';

  String baseUrl = 'https://apis.data.go.kr/B551011/GoCamping/searchList';
//'https://apis.data.go.kr/B551011/GoCamping/searchList?numOfRows=5&pageNo=1&MobileOS=IOS&MobileApp=add&serviceKey=111&_type=111&keyword=33' \

  Future<List<CampingResData>> searchCamping(String searchWord) async {
    List<CampingResData> list = [];
    try {
      // 기본 필수값
      CampingReqData reqData = CampingReqData();
      reqData.serviceKey = apiKey;
      reqData.MobileOS = Platform.isIOS ? 'IOS' : 'AND';
      reqData.MobileApp = 'skysnap';
      reqData.keyword = searchWord;

      Map<String, dynamic> map = reqData.toMap();
      map['_type'] = 'json';

      final dio = await AuthDio.instance.getNoAuthCathDio(cachehour: 4000);
      Response response = await dio.get(baseUrl, queryParameters: map);
      if (response.statusCode == 200) {
        List<CampingResData> list = [];
        for (var item in response.data['body']['items']['item']) {
          list.add(CampingResData.fromMap(item));
        }
        return list;
      } else {
        lo.g('error');
        return list;
      }
    } catch (e) {
      lo.g(e.toString());
      return list;
    }
  }
}
