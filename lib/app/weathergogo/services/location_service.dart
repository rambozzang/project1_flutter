import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/repo/mist_gogoapi/mist_repo.dart';
import 'package:project1/repo/weather/data/weather_view_data.dart';
import 'package:project1/utils/log_utils.dart';

import 'package:dio/src/response.dart' as dioRes;

class LocationService {
  //  좌료를 통해 동네이름 주소 가져오기
  Future<(String?, String?)> getLocalName(LatLng posi) async {
    String? localName;
    try {
      // 좌료를 통해 동네이름 가져오기
      // MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      // ResData resData2 = await myLocatorRepo.getLocationName(posi);
      KakaoRepo kakaoRepo = KakaoRepo();
      var (localNm1, localNm2, localNm3) = await kakaoRepo.getAddressbylatlon(posi.latitude, posi.longitude);
      localName = localNm3 == '' ? '$localNm1, $localNm2' : '$localNm2, $localNm3';
      return (localNm1, localName);
    } catch (e) {
      Lo.g('동네이름 조회 오류 ${posi.latitude} , ${posi.longitude}: $e');
      return ('', localName);
    }
  }
  //  37.4462920026041 , 126.372737043106:

  // 미세먼지 가져오기
  Future<MistViewData?> getMistData(String localName) async {
    try {
      MistRepo mistRepo = MistRepo();
      Lo.g('미세먼지 가져오기 시작 :  $localName');

      dioRes.Response? res = await mistRepo.getMistData(localName);
      MistData mistData = MistData.fromJson(jsonEncode(res!.data['response']['body']));
      // 단위 ㎍/㎥
      MistViewData _mistViewData = MistViewData(
        mist10: mistData.items![0].pm10Value!,
        mist25: mistData.items![0].pm25Value!,
        mist10Grade: mistRepo.getMist10Grade(mistData.items![0].pm10Value!),
        mist25Grade: mistRepo.getMist25Grade(mistData.items![0].pm25Value!),
      );

      return _mistViewData;
    } catch (e) {
      Lo.g('미세먼지 가져오기 오류 : $e');
      return null;
    }
  }
}
