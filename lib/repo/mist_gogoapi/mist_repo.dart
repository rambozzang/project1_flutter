import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/repo/weather_gogo/sources/backend_weather_api.dart';

/*
환경부 등급 기준
미세먼지[PM-10]
  좋음 0~30
  보통 31~80
  나쁨 81~150
  매우나쁨 151~

초미세먼지[Pm-25]
  좋음 0~15
  보통 16~35
  나쁨 36~75
  매우나쁨 76~
*/
// https://www.data.go.kr/tcs/dss/selectApiDataDetailView.do?publicDataPk=15073861
class MistRepo {
  Future<MistData?> getMistData(String stationNm) async {
    try {
      String sidoName = _convertSidoName(stationNm);

      final data = await BackendWeatherApi().getMistData(sidoName);
      if (data == null) return null;

      return MistData.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      print(e);
    }
    return null;
  }

  String _convertSidoName(String stationNm) {
    if (stationNm == '전라남도') {
      return '전남';
    } else if (stationNm == '전라북도') {
      return '전북';
    } else if (stationNm == '충청남도') {
      return '충남';
    } else if (stationNm == '충청북도') {
      return '충북';
    } else if (stationNm == '강원도' || stationNm == '강원특별자치도') {
      return '강원';
    } else if (stationNm == '제주특별자치도') {
      return '제주';
    } else if (stationNm == '서울특별시') {
      return '서울';
    } else if (stationNm == '경기도') {
      return '경기';
    } else if (stationNm == '경상남도') {
      return '경남';
    } else if (stationNm == '경상북도') {
      return '경북';
    } else if (stationNm == '광주광역시') {
      return '광주';
    } else if (stationNm == '대구광역시') {
      return '대구';
    } else if (stationNm == '대전광역시') {
      return '대전';
    } else if (stationNm == '부산광역시') {
      return '부산';
    } else if (stationNm == '울산광역시') {
      return '울산';
    }
    return stationNm;
  }

  String getMist10Grade(String str) {
    final value = int.tryParse(str.toString().trim());
    if (value == null) return '-'; // "-"·빈값 등 측정없음 → int.parse 크래시 방지(예: 경기 부천 pm25 없음)

    if (value >= 0 && value <= 30) {
      return '좋음';
    } else if (value >= 31 && value <= 80) {
      return '보통';
    } else if (value >= 81 && value <= 150) {
      return '나쁨';
    } else {
      return '매우나쁨';
    }
  }

  String getMist25Grade(String str) {
    final value = int.tryParse(str.toString().trim());
    if (value == null) return '-'; // "-"·빈값 등 측정없음 → int.parse 크래시 방지(예: 경기 부천 pm25 없음)
    if (value >= 0 && value <= 15) {
      return '좋음';
    } else if (value >= 16 && value <= 35) {
      return '보통';
    } else if (value >= 36 && value <= 75) {
      return '나쁨';
    } else {
      return '매우나쁨';
    }
  }
}
