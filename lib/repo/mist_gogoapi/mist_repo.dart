import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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

class MistRepo {
  String endPoint = 'http://apis.data.go.kr/B552584/ArpltnStatsSvc';
  String apiKey = 'CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D';
  //Decoding :  CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==

  Future<Response?> getMistData(String stationNm) async {
    try {
      String airConditon = 'http://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty?'
          'stationName=$stationNm&dataTerm=DAILY&pageNo=1&ver=1.0'
          '&numOfRows=1&returnType=json&serviceKey=$apiKey';

      Dio dio = Dio();
      // dio.interceptors.add(PrettyDioLogger(
      //   requestHeader: true,
      //   requestBody: true,
      //   responseBody: true,
      //   responseHeader: true,
      //   error: true,
      //   compact: true,
      //   maxWidth: 120,
      // ));
      Response response = await dio.get(airConditon);
      // debugPrint(response.data);
      return response;
    } catch (e) {
      print(e);
      // return e.toString();
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

