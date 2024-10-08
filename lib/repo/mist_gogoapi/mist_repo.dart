import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/repo/api/auth_dio.dart';

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
  String endPoint = 'http://apis.data.go.kr/B552584/ArpltnStatsSvc';
  String apiKey = 'CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D';

  //Decoding :  CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==

  Future<Response?> getMistData(String stationNm) async {
    try {
      //시도명 2글자로 정리
      //시도 이름(전국, 서울, 부산, 대구, 인천, 광주, 대전, 울산, 경기, 강원, 충북, 충남, 전북, 전남, 경북, 경남, 제주, 세종)
      if (stationNm == '전라남도') {
        stationNm = '전남';
      } else if (stationNm == '전라북도') {
        stationNm = '전북';
      } else if (stationNm == '충청남도') {
        stationNm = '충남';
      } else if (stationNm == '충청북도') {
        stationNm = '충북';
      } else if (stationNm == '강원도' || stationNm == '강원특별자치도') {
        stationNm = '강원';
      } else if (stationNm == '제주특별자치도') {
        stationNm = '제주';
      } else if (stationNm == '서울특별시') {
        stationNm = '서울';
      } else if (stationNm == '경기도') {
        stationNm = '경기';
      } else if (stationNm == '경상남도') {
        stationNm = '경남';
      } else if (stationNm == '경상북도') {
        stationNm = '경북';
      } else if (stationNm == '광주광역시') {
        stationNm = '광주';
      } else if (stationNm == '대구광역시') {
        stationNm = '대구';
      } else if (stationNm == '대전광역시') {
        stationNm = '대전';
      } else if (stationNm == '부산광역시') {
        stationNm = '부산';
      } else if (stationNm == '울산광역시') {
        stationNm = '울산';
      }

      // String airConditon = 'http://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty?'
      //     'stationName=$stationNm&dataTerm=DAILY&pageNo=1&ver=1.0'
      //     '&numOfRows=1&returnType=json&serviceKey=$apiKey';

      // 지역별 도시별 대기질 현황이 넘어오지만 갯수를 1개만 가져와 보녀준다.
      String airConditon = 'http://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty?'
          'sidoName=$stationNm&dataTerm=DAILY&pageNo=1&ver=1.0'
          '&numOfRows=1&returnType=json&serviceKey=$apiKey';

      final dio = await AuthDio.instance.getNoAuthDio();
      Response response = await dio.get(airConditon);

      return response;
    } catch (e) {
      print(e);
    }
  }

  String getMist10Grade(String str) {
    int value = int.parse(str.toString());

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
    int value = int.parse(str.toString());
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


// String airConditon = 'http://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty?'
//         'stationName=강남구&dataTerm=DAILY&pageNo=1&ver=1.0'
//         '&numOfRows=1&returnType=json&serviceKey=CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D';


// http://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty?stationName=강남구&dataTerm=DAILY&pageNo=1&ver=1.0&numOfRows=1&returnType=json&serviceKey=CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D

