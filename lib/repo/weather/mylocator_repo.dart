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
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best, timeLimit: const Duration(seconds: 2));
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  // 네이버로 변경 해야지
  // https://velog.io/@sonagidev/Flutter-%EC%9C%84%EC%B9%98-%EC%A0%95%EB%B3%B4%EB%A5%BC-%EB%B0%9B%EC%95%84%EC%84%9C-%EC%8B%9C-%EA%B5%AC-%EB%A5%BC-%ED%99%94%EB%A9%B4%EC%97%90-%EB%9D%84%EC%9A%B0%EA%B8%B0
  // Future<List> fetchData() async {
  //   Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //   //현재위치를 position이라는 변수로 저장
  //   String lat = position.latitude.toString();
  //   String lon = position.longitude.toString();
  //   //위도와 경도를 나눠서 변수 선언
  //   print(lat);
  //   print(lon);
  //   // 잘 나오는지 확인!
  //   Map<String, String> headerss = {
  //     "X-NCP-APIGW-API-KEY-ID": "Client ID", // 개인 클라이언트 아이디
  //     "X-NCP-APIGW-API-KEY": "Client secret" // 개인 시크릿 키
  //   };
  //   Response response = await get(Uri.parse(//이 부분이 코딩셰프님 영상과 차이가 있다. 플러터 버젼업이 되면서 이 메소드를 써야 제대로 uri를 인식한다.
  //           "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?request=coordsToaddr&coords=${lon},${lat}&sourcecrs=epsg:4326&output=json"),
  //       headers: headerss);
  //   // 미리 만들어둔 headers map을 헤더에 넣어준다.
  //   String jsonData = response.body;
  //   //response에서 body부분만 받아주는 변수 만들어주공~
  //   print(jsonData); // 확인한번하고
  //   var myJson_gu = jsonDecode(jsonData)["results"][1]['region']['area2']['name'];
  //   var myJson_si = jsonDecode(jsonData)["results"][1]['region']['area1']['name'];

  //   List<String> gusi = [myJson_si, myJson_gu];

  //   return gusi; //구랑 시를 받아서 gusi라는 귀여운 이름으로 받는다...?
  // }

  Future<ResData> getLocationName(Position position) async {
    final dio = Dio(BaseOptions(
        headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 60)));
    // dio.interceptors.add(PrettyDioLogger(
    //   requestHeader: true,
    //   requestBody: true,
    //   responseBody: true,
    //   responseHeader: true,
    //   error: true,
    //   compact: true,
    //   maxWidth: 120,
    // ));

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
      return AuthDio.instance.dioException(e);
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
