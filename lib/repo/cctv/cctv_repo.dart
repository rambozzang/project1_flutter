import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';

import 'package:project1/repo/cctv/data/cctv_req_data.dart';
import 'package:project1/repo/cctv/data/cctv_res_data.dart';
import 'package:project1/repo/cctv/data/cctv_seoul_req_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:xml2json/xml2json.dart';
import 'dart:convert' as convert;

// http://openapi.its.go.kr/key/login.do
//  -> https://www.its.go.kr/user/signUpComplete
// https://www.its.go.kr/user/mypage

// 신규 api 확인 필요  req 항목이 다름
//https://www.its.go.kr/opendata/opendataList?service=cctv

// 서울시내
// https://www.utic.go.kr/guide/newUtisDataWrite.do
class CctvRepo {
  var distance = Distance();
  final dio = authDio();

  Future<List<CctvResData>> fetchCctv(LatLng southWest, LatLng northEast, double lat, double lng) async {
    List<CctvResData> cctvs = [];

    ///
    ///
    CctvReqData req = CctvReqData();
    //req.apiKey = 'test';
    req.apiKey = '347fd434194345e184b3e15b362d30d8';
    req.cctvType = '1'; // CCTV 유형(1: 실시간 스트리밍(HLS) / 2: 동영상 파일 / 3: 정지 영상)
    req.type = 'its'; // its : 국도 / ex : 고속도로
    req.getType = 'xml'; // 출력 결과 형식(xml, json / 기본: xml)

    req.minX = southWest.longitude;
    req.minY = southWest.latitude;
    req.maxX = northEast.longitude;
    req.maxY = northEast.latitude;

    // String url = 'http://openapi.its.go.kr:8081/api/NCCTVInfo';
    String url = 'https://openapi.its.go.kr:9443/cctvInfo';

    final res = await Dio().get(url, queryParameters: req.toMap());

    if (res.statusCode == 200) {
      // Lo.g('re : ${res}');
      final xml = res.data;
      //  Lo.g('xml : $xml');
      final xml2json = Xml2Json()..parse(xml);
      final json = xml2json.toParker();
      // Lo.g('json : $json'); // => json : {"rs": "  미승인 공개키 입니다.   "}
      final jsonResult = convert.jsonDecode(json);
      final jsonCctvs = jsonResult['response']['data'];
      Lo.g('jsonCctvs : $jsonCctvs');
      // Lo.g('jsonCctvs : ${jsonCctvs!.length}');
      if (jsonCctvs == null || jsonCctvs == 'null') {
        return [];
      }

      List<CctvResData> _list = ((jsonCctvs) as List).map((data) => CctvResData.fromMap(data)).toList();
      return _list;

      // 내 위치 기준으로 해당 cctv 위치까지의 거리를 ResponseCctv 에 추가.
      // _list.forEach((CctvResData cctv) {
      //   // final cctv = CctvResData.fromJson(e.toString());
      //   final km = distance.as(LengthUnit.Kilometer, LatLng(double.parse(cctv.coordx!), double.parse(cctv.coordy!)), LatLng(lat, lng));
      //   cctv.km = km;
      //   cctvs.add(cctv);
      //   Lo.g('json11 : $json');
      // });
      // return cctvs.toList()..sort((a, b) => a.km!.compareTo(b.km!));
    } else {
      Lo.g('${res.statusCode} : ${res.statusMessage}');
      return [];
    }
  }

  // 서울 시내 cctv
  Future<ResData> fetchCctvSeoul(CctvSeoulReqData req) async {
    try {
      var url = '${UrlConfig.baseURL}/cctv/list';
      Response response = await dio.post(url, data: req.toMap());
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }
              
  
}
