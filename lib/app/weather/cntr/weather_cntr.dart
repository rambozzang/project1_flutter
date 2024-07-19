import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weather/models/additionalWeatherData.dart';
import 'package:project1/app/weather/models/dailyWeather.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/models/hourlyWeather.dart';
import 'package:project1/app/weather/models/oneCallCurrentWeather.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/weather_gogo/weather_gogo_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/repo/mist_gogoapi/mist_repo.dart';

import 'package:project1/repo/weather/data/weather_view_data.dart';
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
  // Rx<CurrentWeather?> currentWeather = CurrentWeather().obs;
  // Rx<Weather?> weather = Weather().obs;
  Rx<OneCallCurrentWeather?> oneCallCurrentWeather = OneCallCurrentWeather().obs;

  // OpeMapWhere 날씨 업데이트 시간
  Rx<DateTime?> openApiLastUpdated = DateTime.now().obs;

  // 기상청 날씨 업데이트 시간
  Rx<DateTime?> kmsLastUpdated = DateTime.now().obs;

  // 미세먼지 정보
  Rx<MistViewData?> mistViewData = MistViewData().obs;

  // 시간별 날씨 정보
  List<HourlyWeather> hourlyWeather = <HourlyWeather>[].obs;
  // 일별 날씨 정보
  List<DailyWeather> dailyWeather = <DailyWeather>[].obs;
  Rx<AdditionalWeatherData> additionalWeatherData = AdditionalWeatherData().obs;

  // 날씨 가져오는 상태
  Rx<bool> isLoading = true.obs;
  Rx<bool> isCelsius = true.obs;

  Rx<bool> isRequestError = false.obs;

  Rx<bool> isLocationserviceEnabled = false.obs;

  late LocationPermission locationPermission;

  String get measurementUnit => isCelsius.value ? '°C' : '°F';

  Rx<bool> isChangeLocation = false.obs;

  // 주간이 최저 최고 온도
  late double sevenDayMinTemp;
  late double sevenDayMaxTemp;

  //어제 날씨 정보
  late List<ItemSuperNct> yesterdayWeather = <ItemSuperNct>[].obs;
  List<HourlyWeather> yesterdayHourlyWeather = <HourlyWeather>[].obs;

  // 어제 날씨 높아요/낮아요 한글
  var yesterdayDesc = ''.obs;
  var geminiResult = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // getWeatherData();
    // requestLocation();
  }

  // video_list_cntr.dart 에서 데이터를 가져온후 호출한다.
  Future<void> getWeatherData() async {
    isLoading.value = true;
    isRequestError.value = false;

    // 날씨 가져오기
    //  Position? positionData = await requestLocation();
    Position positionData = await Geolocator.getCurrentPosition();
    currentLocation.value!.latLng = LatLng(positionData.latitude, positionData.longitude);

    try {
      await getOneCallWeather(currentLocation.value!.latLng, true);
    } catch (e) {
      Lo.g('getWeatherData1 e =>$e');
      isRequestError.value = true;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // 카메라 페이지에서 등록할때호출한다. video_reg_page.dart
  Future<void> getWeatherDataOnlyCurrentWeather() async {
    isLoading.value = true;
    isRequestError.value = false;

    try {
      // 날씨 가져오기
      Position positionData = await Geolocator.getCurrentPosition();
      currentLocation.value!.latLng = LatLng(positionData.latitude, positionData.longitude);
      // OpenWheatherRepo repo = OpenWheatherRepo();
      // ResData resData = await repo.getWeather(currentLocation.value!.latLng);
      // if (resData.code != '00') {
      //   Utils.alert(resData.msg.toString());
      //   return;
      // }
      //currentWeather.value = CurrentWeather.fromMap(resData.data);

      // weather.value = Weather(
      //   temp: currentWeather.value!.main?.temp,
      //   tempMax: currentWeather.value!.main?.temp_max,
      //   tempMin: currentWeather.value!.main?.temp_min,
      //   lat: currentWeather.value!.coord!.lat,
      //   long: currentWeather.value!.coord!.lon,
      //   feelsLike: currentWeather.value!.main?.feels_like,
      //   pressure: currentWeather.value!.main?.pressure,
      //   description: currentWeather.value!.weather![0].description,
      //   weatherCategory: currentWeather.value!.weather![0].main,
      //   humidity: currentWeather.value!.main?.humidity,
      //   windSpeed: currentWeather.value!.wind?.speed,
      //   city: currentWeather.value!.name,
      //   countryCode: currentWeather.value!.sys?.country,
      // );
      // openApiLastUpdated.value = DateTime.now();
      await getOneCallWeather(LatLng(currentLocation.value!.latLng.latitude, currentLocation.value!.latLng.longitude!), false);

      isLoading.value = false;
      update();
      // await getOneCallWeather(currentLocation.value!.latLng);
      Lo.g('getCurrentWeather() 6 ');
    } catch (e) {
      Lo.g('getWeatherData1 e =>$e');
      isRequestError.value = true;
      isLoading.value = false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Auth_page.dart 에서 호출한다.
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

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
    lo.g("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    lo.g("Position : $position");
    lo.g("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");

    positionData = position;
    currentLocation.value!.latLng = LatLng(position.latitude, position.longitude);
    return position;
  }

  // 전체 날씨 가져오기
  Future<void> getOneCallWeather(LatLng location, bool isCallYesterday) async {
    isLoading.value = true;
    update();
    try {
      OpenWheatherRepo repo = OpenWheatherRepo();
      ResData resData = await repo.getOneCallWeather(location);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Lo.g('getOneCallWeather() resData : ${resData.data}');

      final dailyData = resData.data as Map<String, dynamic>;

      additionalWeatherData.value = AdditionalWeatherData(
        precipitation: (dailyData['daily'][0]['pop'] * 100).toStringAsFixed(0), // 강수확률
        uvi: (dailyData['current']['uvi']).toDouble(),
        clouds: dailyData['current']['clouds'] ?? 0,
      );
      oneCallCurrentWeather.value = OneCallCurrentWeather.fromMap(dailyData['current']);
      isLoading.value = false;
      update();

      List dailyList = dailyData['daily'];
      List hourlyList = dailyData['hourly'];

      hourlyWeather = hourlyList.map((item) => HourlyWeather.fromJson(item)).toList().take(25).toList();
      // 임시용 그래프 때문에 삭제 어제날씨와 씽크를 맞추기 위해
      hourlyWeather.removeAt(0);
      dailyWeather = dailyList.map((item) => DailyWeather.fromDailyJson(item)).toList();

      await getLocalName(LatLng(location.latitude, location.longitude!));

      sevenDayMinTemp = dailyWeather.map((e) => e.tempMin).reduce((value, element) => value < element ? value : element);
      sevenDayMaxTemp = dailyWeather.map((e) => e.tempMax).reduce((value, element) => value > element ? value : element);

      if (isCallYesterday) {
        // await Future.delayed(1.seconds, () async => await getYesterdayWeather(location));
        await getYesterdayWeather(location);
      }
    } catch (e) {
      Lo.g('getOneCallWeather e =>$e');
      isLoading.value = false;
      isRequestError.value = true;
    }
  }

  //  좌료를 통해 동네이름 주소 가져오기
  Future<void> getLocalName(LatLng posi) async {
    try {
      // 좌료를 통해 동네이름 가져오기
      // MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      // ResData resData2 = await myLocatorRepo.getLocationName(posi);
      KakaoRepo kakaoRepo = KakaoRepo();
      var (localNm1, localNm2, localNm3) = await kakaoRepo.getAddressbylatlon(posi.latitude, posi.longitude);
      currentLocation.value?.name = localNm3 == '' ? '$localNm1, $localNm2' : '$localNm2, $localNm3';
      update();
      getMistData(localNm1);
    } catch (e) {
      Lo.g('동네이름 조회 오류 : $e');
    }
  }

  // 미세먼지 가져오기
  void getMistData(String localName) async {
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
    print('searchWeatherKakao :  ${geocodeData.latLng.latitude} ${geocodeData.latLng.longitude} ');
    try {
      await getOneCallWeather(geocodeData.latLng, true);
      currentLocation.value?.name = geocodeData.name;
      // update();
    } catch (e) {
      Lo.g('searchWeatherKakao e =>$e');
      isLoading.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  //어제 날씨 정보 가져오기
  Future<void> getYesterdayWeather(LatLng latLng) async {
    try {
      // 타이머
      Stopwatch stopwatch = Stopwatch()..start();

      WeatherGogoRepo repo = WeatherGogoRepo();
      yesterdayWeather.clear();
      yesterdayWeather = await repo.getYesterDayJson(latLng, isLog: true, isChache: true);

      stopwatch.stop();
      lo.g('@@@  getYesterdayWeather() =>. ${stopwatch.elapsed}');

      // list 출력
      yesterdayWeather.forEach((data) => data.category == 'T1H' ? lo.g('${data.baseDate!} ${data.baseTime!}=>${data.obsrValue!}') : null);

      //-----------------------------------------------------------------------------------
      // 어제 날씨와 오늘 날씨 비교
      //-----------------------------------------------------------------------------------

      // list 에서 맨마지막 데이터를 가져온다
      ItemSuperNct lastitem = yesterdayWeather.lastWhere((element) => element.category == 'T1H');
      ItemSuperNct firstitem = yesterdayWeather.firstWhere((element) => element.category == 'T1H');

      // 위 2개 값을 비교값
      double temp = double.parse(firstitem.obsrValue!) - double.parse(lastitem.obsrValue!);
      // temp 값을 소수점 1자리로 반올림 해서 변경
      temp = temp.floorToDouble();

      yesterdayDesc.value = double.parse(firstitem.obsrValue!) > double.parse(lastitem.obsrValue!) ? '어제보다 $temp° 높아요' : '어제보다 $temp° 낮아요';
      yesterdayDesc.value = temp == 0.0 ? '어제와 같아요' : yesterdayDesc.value;

      // HourlyWeather 변환
      yesterdayHourlyWeather.clear();

      //  yesterdayWeather.removeAt(0);
      for (ItemSuperNct item in yesterdayWeather) {
        if (item.category == 'T1H') {
          HourlyWeather hourlyWeather = HourlyWeather(
            temp: double.parse(item.obsrValue!),
            weatherCategory: '',
            date: DateTime.parse('${item.baseDate!} ${item.baseTime!}'),
          );

          yesterdayHourlyWeather.add(hourlyWeather);
        }
      }

      // yesterdayHourlyWeather 첫번째가 실제 관측한 날씨 온도
      oneCallCurrentWeather.value!.temp = yesterdayHourlyWeather[0].temp;
      //2개 리스트 비교해서 같은 시간대를 맞춘다.
      (List<HourlyWeather>, List<HourlyWeather>) resultList = twicelistCompare(hourlyWeather, yesterdayHourlyWeather);
      hourlyWeather.clear();
      yesterdayHourlyWeather.clear();
      hourlyWeather = resultList.$1.toList();
      yesterdayHourlyWeather = resultList.$2.toList();

      update();
    } catch (e) {
      Lo.g('getYesterdayWeather e =>$e');
    }
  }

  // 2개 리스트 비교해서 같은 시간대를 맞춘다. 최대한 데이터를 보존한다.
  (List<HourlyWeather>, List<HourlyWeather>) twicelistCompare(
      List<HourlyWeather> hourlyWeather, List<HourlyWeather> yesterdayHourlyWeather) {
    List<HourlyWeather> filteredHourlyWeather = [];
    List<HourlyWeather> filteredYesterdayHourlyWeather = [];

    for (var weather in hourlyWeather) {
      for (var yesterdayWeather in yesterdayHourlyWeather) {
        if (yesterdayWeather.date == weather.date.subtract(const Duration(days: 1)) && yesterdayWeather.date.hour == weather.date.hour) {
          filteredHourlyWeather.add(weather);
          filteredYesterdayHourlyWeather.add(yesterdayWeather);
        }
      }
    }

    print('Filtered Hourly Weather:');
    for (var data in filteredHourlyWeather) {
      print('${data.date} - ${data.temp}°C');
    }

    print('\nFiltered Yesterday Hourly Weather:');
    for (var data in filteredYesterdayHourlyWeather) {
      print('${data.date} - ${data.temp}°C');
    }

    filteredYesterdayHourlyWeather.reversed.toList();
    return (filteredHourlyWeather, filteredYesterdayHourlyWeather);
  }

  // Future<void> getCurrentOpenMapWeather(LatLng location) async {
  //   isLoading.value = true;
  //   update();
  //   try {
  //     OpenWheatherRepo repo = OpenWheatherRepo();
  //     ResData resData = await repo.getWeather(location);
  //     if (resData.code != '00') {
  //       Utils.alert(resData.msg.toString());
  //       return;
  //     }
  //     // currentWeather.value = CurrentWeather.fromMap(resData.data);

  //     // weather.value = Weather(
  //     //   temp: currentWeather.value!.main?.temp,
  //     //   tempMax: currentWeather.value!.main?.temp_max,
  //     //   tempMin: currentWeather.value!.main?.temp_min,
  //     //   lat: currentWeather.value!.coord!.lat,
  //     //   long: currentWeather.value!.coord!.lon,
  //     //   feelsLike: currentWeather.value!.main?.feels_like,
  //     //   pressure: currentWeather.value!.main?.pressure,
  //     //   description: currentWeather.value!.weather![0].description,
  //     //   weatherCategory: currentWeather.value!.weather![0].main,
  //     //   humidity: currentWeather.value!.main?.humidity,
  //     //   windSpeed: currentWeather.value!.wind?.speed,
  //     //   city: currentWeather.value!.name,
  //     //   countryCode: currentWeather.value!.sys?.country,
  //     // );
  //     openApiLastUpdated.value = DateTime.now();

  //     await getLocalName(LatLng(currentWeather.value!.coord!.lat!, currentWeather.value!.coord!.lon!));

  //     isLoading.value = false;
  //     update();
  //     await getOneCallWeather(currentLocation.value!.latLng);
  //     Lo.g('getCurrentWeather() 6 ');
  //   } catch (e) {
  //     Lo.g('getCurrentWeather e =>$e');
  //     isLoading.value = false;
  //     isRequestError.value = true;
  //   }
  // }
}
