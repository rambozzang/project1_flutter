import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

//  https://velog.io/@zinkiki/FlutterDart-OpenWeatherMap-Api-%EB%A1%9C-%EB%82%A0%EC%94%A8-%EB%B0%9B%EC%95%84%EC%98%A4%EA%B8%B0
//  https://mercyjemosop.medium.com/open-weather-api-with-flutter-app-a294fbbe2a7a
// https://unsungit.tistory.com/121
// https://hgko1207.github.io/2020/07/31/java-dev-3/
// https://gist.github.com/choipd/e73201a4653a5e56e830#file-openweathermap_api_translation_ko
// https://eory96study.tistory.com/33

class MachingData {
// 온도표시 하단의 날씨별 이미지
  Widget getWeatherIcon(int condition) {
    if (condition < 300) {
      return SvgPicture.asset(
        'svg/climacon-cloud_lightning.svg',
        // color: Colors.black87,
      );
    } else if (condition < 600) {
      return SvgPicture.asset(
        'svg/climacon-cloud_snow_alt.svg',
        // color: Colors.black87,
      );
    } else if (condition == 800) {
      return SvgPicture.asset(
        'svg/climacon-sun.svg',
        // color: Colors.black87,
      );
    } else if (condition <= 804) {
      return SvgPicture.asset(
        'svg/climacon-cloud_sun.svg',
        // color: Colors.black87,
      );
    }
    return SvgPicture.asset('svg/climacon-cloud_sun.svg');
  }

// AQI 등급별 이미지
  Widget getAirIcon(int condition) {
    if (condition == 1) {
      return Image.asset('image/good.png', width: 37.0, height: 35.0);
    } else if (condition == 2) {
      return Image.asset('image/fair.png', width: 37.0, height: 35.0);
    } else if (condition == 3) {
      return Image.asset('image/moderate.png', width: 37.0, height: 35.0);
    } else if (condition == 4) {
      return Image.asset('image/poor.png', width: 37.0, height: 35.0);
    } else if (condition == 5) {
      return Image.asset('image/bad.png', width: 37.0, height: 35.0);
    }
    return Image.asset('image/bad.png', width: 37.0, height: 35.0);
  }

// AQI 등급별 이미지 설명
  Widget getAirCondition(int condition) {
    if (condition == 1) {
      return const Text(
        '"매우좋음"',
        style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
      );
    } else if (condition == 2) {
      return const Text(
        '"좋음"',
        style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
      );
    } else if (condition == 3) {
      return const Text(
        '"보통"',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      );
    } else if (condition == 4) {
      return const Text(
        '"나븜"',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      );
    } else if (condition == 5) {
      return const Text(
        '"매우나쁨"',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      );
    }
    return const Text(
      '"매우나쁨"',
      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    );
  }
}
