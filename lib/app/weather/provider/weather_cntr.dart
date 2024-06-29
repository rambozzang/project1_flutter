import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weather/models/additionalWeatherData.dart';
import 'package:project1/app/weather/models/dailyWeather.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/models/hourlyWeather.dart';
import 'package:project1/app/weather/models/weather.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/repo/mist_gogoapi/mist_repo.dart';

import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/data/weather_view_data.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';

import 'package:geolocator/geolocator.dart';

// ignore: implementation_imports
import 'package:dio/src/response.dart' as dioRes;
import 'package:project1/utils/utils.dart';

class WeatherCntrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeatherCntr>(
      () => WeatherCntr(),
    );
  }
}

class WeatherCntr extends GetxController {
  // 현재 위치 : 동네이름 , 위도 경도
  late Rx<GeocodeData?> currentLocation = GeocodeData(name: '', latLng: const LatLng(0.0, 0.0)).obs;
  late Position positionData;
  // 현재 날씨 정보
  Rx<CurrentWeather?> currentWeather = CurrentWeather().obs;
  Rx<Weather?> weather = Weather().obs;

  // 날씨 업데이트 시간
  Rx<DateTime?> lastUpdated = DateTime.now().obs;
  // 미세먼지 정보
  Rx<MistViewData?> mistViewData = MistViewData().obs;

  // 시간별 날씨 정보
  List<HourlyWeather> hourlyWeather = <HourlyWeather>[].obs;
  // 일별 날씨 정보
  List<DailyWeather> dailyWeather = <DailyWeather>[].obs;
  Rx<AdditionalWeatherData> additionalWeatherData = AdditionalWeatherData().obs;

  // 날씨 가져오는 상태
  Rx<bool> isCompleted = false.obs;
  Rx<bool> isLoading = true.obs;
  Rx<bool> isCelsius = true.obs;

  Rx<bool> isRequestError = false.obs;
  Rx<bool> isSearchError = false.obs;
  Rx<bool> isLocationserviceEnabled = false.obs;

  late LocationPermission locationPermission;

  String get measurementUnit => isCelsius.value ? '°C' : '°F';

  // 주간이 최저 최고 온도
  late double sevenDayMinTemp;
  late double sevenDayMaxTemp;

  @override
  void onInit() {
    super.onInit();
    // getWeatherData();
    // requestLocation();
  }

  // video_list_cntr.dart 에서 데이터를 가져온후 호출한다.
  Future<void> getWeatherData() async {
    // if (isLoading.value == true) return;

    isLoading.value = true;
    isRequestError.value = false;
    isSearchError.value = false;

    // 날씨 가져오기
    //  Position? positionData = await requestLocation();
    // Position positionData = await Geolocator.getCurrentPosition();
    // currentLocation.value!.latLng = LatLng(positionData.latitude, positionData.longitude);
    // update();

    // if (positionData == null) {
    //   isLoading.value = false;
    //   Utils.alert('날씨 권한 및 위치정보 가져오기 오류!');
    //   return;
    // }
    // 위치만 가져와도 완료로 찍어 리스트를 호출하게 한다.
    isCompleted.value = true;

    try {
      // Position positionData = Position(latitude: currentLocation.value!.latLng , longitude: currentLocation.value!.latLng);

      await getLocalName(positionData);
      await getCurrentWeather(currentLocation.value!.latLng);
      // await getDailyWeather(currentLocation.value!.latLng);

      // await Isolate.spawn(getLocalName, positionData);
      // await Isolate.spawn(getCurrentWeather, currentLocation.value!.latLng);
      // await Isolate.spawn(getDailyWeather, currentLocation.value!.latLng);
    } catch (e) {
      Lo.g('getWeatherData1 e =>$e');
      isRequestError.value = true;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // 1 위치 권한 확인 및 요청
  Future<Position> requestLocation() async {
    isLocationserviceEnabled.value = await Geolocator.isLocationServiceEnabled();
    if (!isLocationserviceEnabled.value) {
      Utils.alert('Location services are disabled.');
      update();
      return Future.error('Location services are disabled.');
    }

    locationPermission = await Geolocator.checkPermission();
    lo.g(locationPermission.toString());

    if (locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      if (locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) {
        Utils.alert('Location permissions are denied');
        update();
        return Future.error('Location permissions are disabled.');
      }
    }
    Position position = await Geolocator.getCurrentPosition();
    lo.g("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    lo.g("Position : $position");
    lo.g("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");

    positionData = position;
    currentLocation.value!.latLng = LatLng(position.latitude, position.longitude);
    return position;
  }

  // 현재 날씨 가져오기
  Future<void> getCurrentWeather(LatLng location) async {
    try {
      Lo.g('getCurrentWeather() 1 ');

      OpenWheatherRepo repo = OpenWheatherRepo();
      ResData resData = await repo.getWeather(location);
      Lo.g('getCurrentWeather() 2 ');

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      // Lo.g('getCurrentWeather() resData : ${resData.data}');
      Lo.g('getCurrentWeather() 3 ');

      currentWeather.value = CurrentWeather.fromMap(resData.data);
      Lo.g('getCurrentWeather() 4 ');

      weather.value = Weather(
        temp: currentWeather.value!.main?.temp,
        tempMax: currentWeather.value!.main?.temp_max,
        tempMin: currentWeather.value!.main?.temp_min,
        lat: currentWeather.value!.coord!.lat,
        long: currentWeather.value!.coord!.lon,
        feelsLike: currentWeather.value!.main?.feels_like,
        pressure: currentWeather.value!.main?.pressure,
        description: currentWeather.value!.weather![0].description,
        weatherCategory: currentWeather.value!.weather![0].main,
        humidity: currentWeather.value!.main?.humidity,
        windSpeed: currentWeather.value!.wind?.speed,
        city: currentWeather.value!.name,
        countryCode: currentWeather.value!.sys?.country,
      );
      Lo.g('getCurrentWeather() 5 ');

      lastUpdated.value = DateTime.now();
      update();
      await getDailyWeather(currentLocation.value!.latLng);
      Lo.g('getCurrentWeather() 6 ');
    } catch (e) {
      Lo.g('getCurrentWeather e =>$e');
      isLoading.value = false;
      isRequestError.value = true;
    }
  }

  // 일별 날씨 가져오기
  Future<void> getDailyWeather(LatLng location) async {
    isLoading.value = true;

    try {
      OpenWheatherRepo repo = OpenWheatherRepo();
      ResData resData = await repo.getDailyWeather(location);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Lo.g('getDailyWeather() resData : ${resData.data}');

      final dailyData = resData.data as Map<String, dynamic>;
      additionalWeatherData.value = AdditionalWeatherData(
        precipitation: (dailyData['daily'][0]['pop'] * 100).toStringAsFixed(0),
        uvi: (dailyData['daily'][0]['uvi']).toDouble(),
        clouds: dailyData['daily'][0]['clouds'] ?? 0,
      );

      List dailyList = dailyData['daily'];
      List hourlyList = dailyData['hourly'];
      hourlyWeather = hourlyList.map((item) => HourlyWeather.fromJson(item)).toList().take(24).toList();
      dailyWeather = dailyList.map((item) => DailyWeather.fromDailyJson(item)).toList();

      sevenDayMinTemp = dailyWeather.map((e) => e.tempMin).reduce((value, element) => value < element ? value : element);
      sevenDayMaxTemp = dailyWeather.map((e) => e.tempMax).reduce((value, element) => value > element ? value : element);
      update();
    } catch (e) {
      Lo.g('getDailyWeather e =>$e');
      isLoading.value = false;
      isRequestError.value = true;
    }
  }

  //  좌료를 통해 동네이름 주소 가져오기
  Future<void> getLocalName(Position posi) async {
    try {
      // 좌료를 통해 동네이름 가져오기
      MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      ResData resData2 = await myLocatorRepo.getLocationName(posi);
      if (resData2.code != '00') {
        Utils.alert(resData2.msg.toString());
        return;
      }
      Lo.g('동네이름() resData2 : ${resData2.data['ADDR']}');
      var localNm = resData2.data['ADDR'].toString().split(' ')[0];
      localNm = '${Utils.localReplace(localNm)}, ${resData2.data['ADDR'].toString().split(' ')[1]}';
      currentLocation.value?.name = localNm;
      getMistData(localNm);
      // update();
    } catch (e) {
      Lo.g('동네이름 조회 오류 : $e');
    }
  }

  // 미세먼지 가져오기
  void getMistData(String localName) async {
    try {
      MistRepo mistRepo = MistRepo();

      // 동이름 가져오기
      String _localName = localName.split(' ')[1];
      Lo.g('미세먼지 가져오기 시작 :  $_localName');

      dioRes.Response? res = await mistRepo.getMistData(_localName);
      MistData mistData = MistData.fromJson(jsonEncode(res!.data['response']['body']));
      // 단위 ㎍/㎥
      MistViewData _mistViewData = MistViewData(
        mist10: mistData.items![0].pm10Value!,
        mist25: mistData.items![0].pm25Value!,
        mist10Grade: mistRepo.getMist10Grade(mistData.items![0].pm10Value!),
        mist25Grade: mistRepo.getMist25Grade(mistData.items![0].pm25Value!),
      );

      mistViewData.value = _mistViewData;
      update();
    } catch (e) {
      Lo.g('미세먼지 가져오기 오류 : $e');
    }
  }

  // searchWeather 대체 카카오로 검색후 호출한다.
  Future<void> searchWeatherKakao(GeocodeData geocodeData) async {
    isLoading.value = true;

    isRequestError.value = false;
    print('search');
    try {
      if (geocodeData == null) throw Exception('Unable to Find Location');
      await getCurrentWeather(geocodeData.latLng);
      await getDailyWeather(geocodeData.latLng);
      // replace location name with data from geocode
      // because data from certain lat long might return local area name
      weather.value!.city = geocodeData.name;
      update();
    } catch (e) {
      Lo.g('searchWeatherKakao e =>$e');

      isSearchError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
