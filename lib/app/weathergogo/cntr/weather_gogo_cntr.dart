import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/repo/weather/data/weather_view_data.dart';
import 'package:project1/app/weathergogo/cntr/data/current_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/data/daily_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/data/hourly_weather_data.dart';
import 'package:project1/app/weathergogo/services/location_service.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/services/yesterday_weather_service.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/midland_fct/midlan_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/midta_fct/midta_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_caching.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class WeatherGogoCntrBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeatherGogoCntr>(() => WeatherGogoCntr());
  }
}

class WeatherGogoCntr extends GetxController {
  var isLoading = true.obs;
  var isYestdayLoading = true.obs;

  // 현재 위치 : 동네이름 , 위도 경도
  Rx<GeocodeData> currentLocation = GeocodeData(name: '현재 위치', latLng: const LatLng(0.0, 0.0)).obs;
  final Rx<Position?> positionData = Rx<Position?>(null);
  final Rx<MistViewData> mistData = MistViewData().obs;
  final RxList<HourlyWeatherData> hourlyWeather = <HourlyWeatherData>[].obs;
  final RxList<SevenDayWeather> sevenDayWeather = <SevenDayWeather>[].obs;
  final Rx<DateTime> lastUpdated = DateTime.now().obs;
  final Rx<CurrentWeatherData> currentWeather = CurrentWeatherData().obs;
  final RxList<ItemSuperNct> yesterdayWeather = <ItemSuperNct>[].obs;
  final RxList<HourlyWeatherData> yesterdayHourlyWeather = <HourlyWeatherData>[].obs;

  final RxString yesterdayDesc = ''.obs;
  final Rx<double> sevenDayMinTemp = 0.0.obs;
  final Rx<double> sevenDayMaxTemp = 0.0.obs;
  final RxBool isLocationserviceEnabled = false.obs;
  var webViewUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=127.20,36.33,2780/loc='.obs;
  int reCallCnt = 0;

  late LocationPermission locationPermission;
  final WeatherService weatherService = WeatherService();
  final LocationService locationService = LocationService();

  @override
  void onInit() {
    super.onInit();
  }

  // 최초 호출 , 영상 등록시 호출
  Future<void> getInitWeatherData(bool isAllSearch) async {
    await getWeatherDataByLatLng(currentLocation.value!.latLng, isAllSearch);
  }

  // app bar 에서 호출
  Future<void> getCurrentWeatherData(bool isAllSearch) async {
    if (loadingCheck()) {
      return;
    }

    isLoading.value = true;

    // 날씨 가져오기
    positionData.value = await Geolocator.getCurrentPosition();
    currentLocation.value!.latLng = LatLng(positionData.value!.latitude, positionData.value!.longitude);
    await getWeatherDataByLatLng(currentLocation.value!.latLng, isAllSearch);
  }

  bool loadingCheck() {
    // 하나라도 로딩중이면 제어한다.
    if (isLoading.value == true || isYestdayLoading.value == true) {
      String msg = isYestdayLoading.value == true ? '어제 ' : '';
      Utils.alert('${msg}데이터 수집중입니다. 잠시만요..', align: 'TOP');
      return true;
    }
    return false;
  }

  Future<void> getRefreshWeatherData(bool isAllSearch) async {
    if (loadingCheck()) {
      return;
    }
    isLoading.value = true;
    await getWeatherDataByLatLng(currentLocation.value!.latLng, isAllSearch);
  }

  // Auth_page.dart 에서 호출한다.
  // 1 위치 권한 확인 및 요청
  Future<Position> requestLocation() async {
    isLocationserviceEnabled.value = await Geolocator.isLocationServiceEnabled();
    if (!isLocationserviceEnabled.value) {
      Utils.alert('Location services are disabled.');
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
        // Utils.alert('Location permissions are denied');

        Utils.showConfirmDialog('위치 권한이 거부되었습니다.', '위치 설정을 변경 하시겠습니까?', BackButtonBehavior.none, cancel: () {}, confirm: () async {
          await openAppSettings();
        }, backgroundReturn: () async {
          locationPermission = await Geolocator.checkPermission();
        });
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

    positionData.value = position;
    currentLocation.value.latLng = LatLng(position.latitude, position.longitude);

    return position;
  }

  // 검색후 호출
  Future<void> searchWeatherKakao(GeocodeData geocodeData) async {
    if (loadingCheck()) {
      return;
    }
    isLoading.value = true;
    try {
      LatLng location = LatLng(geocodeData.latLng.latitude, geocodeData.latLng.longitude);

      currentLocation.update((val) {
        val?.latLng = location;
        val?.name = geocodeData.name;
      });
      await getWeatherDataByLatLng(location, true);
      // update();
    } catch (e) {
      handleError('searchWeatherKakao 실패', e);
    }
  }

  late var stopwatch;
  Future<void> getWeatherDataByLatLng(LatLng location, bool isAllSearch) async {
    try {
      stopwatch = Stopwatch()..start();
      webViewUrl.value = '${webViewUrl.value} + ${location.longitude},${location.latitude},2780/loc=';
      // 5분후 해제

      hourlyWeather.clear();
      sevenDayWeather.clear();
      yesterdayHourlyWeather.clear();
      yesterdayDesc.value = '';

      await Future.wait([
        fetchSuperNct(location),
        fetchSuperFct(location),
        fetchFct(location),
        fetchMidlandWeather(location),
      ]);
      lo.g("=========================================================");
      lo.g("========================================================");
      lo.g("=========================================================");

      // isYestdayLoading.value = true;
      await Future.wait([
        fetchLocalNameAndMistinfo(location),
        fetchYesterDayWeather(location),
      ]);
      isYestdayLoading.value = false;
      isLoading.value = false;

      lo.g('getWeatherDataByLatLng initialization time: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      handleError('getWeatherDataByLatLng() 오류', e);
      isLoading.value = false;
      isYestdayLoading.value = false;
    } finally {
      stopwatch.stop();
    }
  }

  // 동네 이름, 미세 먼지 정보 가져오기
  Future<void> fetchLocalNameAndMistinfo(LatLng location) async {
    try {
      // ==========================================================
      // 동네이름, 미세먼지 가져오기
      // ==========================================================
      LocationService locationService = LocationService();
      final (onValue1, onValue2) = await locationService.getLocalName(location);
      if (onValue1 == null || onValue2 == null) {
        return;
      }

      // currentLocation.value!.name = onValue2!;
      currentLocation.update((val) {
        val?.name = onValue2;
      });
      mistData.value = (await locationService.getMistData(onValue1))!;
      // ==========================================================
      lo.g('완료!! => fetchLocalNameAndMistinfo() time : ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      // handleError('동네 이름, 미세 먼지 정보 오류', e);
    }
  }

  int fetchSuperNctreCallCnt = 0;
  // 초단기 실황 가져오기
  Future<void> fetchSuperNct(LatLng location) async {
    try {
      List<ItemSuperNct> itemSuperNctList = await weatherService.getWeatherData<List<ItemSuperNct>>(location, ForecastType.superNct);
      // 1.초단기 실황 파싱처리
      CurrentWeatherData value = WeatherDataProcessor.instance.parsingSuperNct(itemSuperNctList);
      currentWeather.update((val) {
        val?.temp = value.temp;
        val?.rain = value.rain;
        val?.fcsTime = value.fcsTime; // 발표시간
        val?.fcstDate = value.fcstDate; // 예보시간
        val?.humidity = value.humidity;
        val?.speed = value.speed;
        val?.deg = value.deg;
        val?.rainDesc = value.rainDesc;
        val?.rain1h = value.rain1h;
      });

      lo.g('완료!! => fetchSuperNct() time : ${stopwatch.elapsedMilliseconds}ms');

      fetchSuperNctreCallCnt = 0;
    } catch (e) {
      handleError('1. 초단기 실황 조회 오류', e);
      if (fetchSuperNctreCallCnt < 3) {
        Future.delayed(const Duration(milliseconds: 150), () {
          fetchSuperNct(location);
          fetchSuperNctreCallCnt++;
        });
      }
    }
  }

  int fetchSuperFctreCallCnt = 0;

  // 초단기 예보 가져오기
  // 1시간 단위 6시간 정보를 셋팅한다.
  Future<void> fetchSuperFct(LatLng location) async {
    try {
      // 2.초단기 예보 가져오기
      List<ItemSuperFct> itemFctList = await weatherService.getWeatherData<List<ItemSuperFct>>(location, ForecastType.superFct);
      // 2.초단기 예보 파싱처리
      List<HourlyWeatherData> data = WeatherDataProcessor.instance.processSuperShortTermForecast(itemFctList);
      // data.forEach((element) {
      //   lo.g('fetchSuperFct  data  : ${element.toString()}');
      // });

      currentWeather.update((val) {
        val?.description = WeatherDataProcessor.instance.combineWeatherCondition(data[0].sky.toString(), data[0].rain.toString());
        val?.sky = data[0].sky;
        // val?.rain = data[0].rain;
        val?.fcsTime = itemFctList[0].baseTime; // 발표시간
      });

      hourlyWeather.addAll(data);
      // hourlyWeather.sort((a, b) => a.date.compareTo(b.date));
      // 중복 제거 date 기준으로
      hourlyWeather.removeWhere((a) => a != hourlyWeather.firstWhere((b) => b.date == a.date));
      // hourlyWeather 가 20개 이상이면 어제 날씨 가져오기 호출
      processingYesterDay(hourlyWeather, yesterdayHourlyWeather);

      // hourlyWeather.forEach((element) {
      //   lo.g('fetchSuperFct  hourlyWeather  : ${element.toString()}');
      // });

      // fetchFct(hourlyWeather, location);
      lo.g('완료!! => fetchSuperFct() time : ${stopwatch.elapsedMilliseconds}ms');

      fetchSuperFctreCallCnt = 0;
    } catch (e) {
      handleError('2. 초단기 예보 조회 오류', e);
      if (fetchSuperFctreCallCnt < 3) {
        Future.delayed(const Duration(milliseconds: 150), () {
          fetchSuperFct(location);
          fetchSuperFctreCallCnt++;
        });
      }
    }
  }

  void processingYesterDay(List<HourlyWeatherData> hWeather, List<HourlyWeatherData> yHWeather) {
    // lo.g("hourlyWeather.length : ${hourlyWeather.length} , yHWeather.length : ${yHWeather.length}");
    // hWeather.forEach((element) {
    //   lo.g('processingYesterDay 1 hWeather  : ${element.toString()}');
    // });
    // yHWeather.forEach((element) {
    //   lo.g('processingYesterDay 1 yHWeather  : ${element.toString()}');
    // });

    if (hWeather.length > 20 && yHWeather.length > 22) {
      hWeather.sort((a, b) => a.date.compareTo(b.date));
      yHWeather.sort((a, b) => a.date.compareTo(b.date));
      var (syncedToday, syncedYesterday) = WeatherDataProcessor.instance.synchronizeWeatherData(hWeather, yHWeather);
      hourlyWeather.value = syncedToday.toList();
      yesterdayHourlyWeather.value = syncedYesterday.toList();
      // hourlyWeather.forEach((element) {
      //   lo.g('processingYesterDay 2 hourlyWeather  : ${element.toString()}');
      // });
      // yesterdayHourlyWeather.forEach((element) {
      //   lo.g('processingYesterDay 2 yesterdayHourlyWeather  : ${element.toString()}');
      // });
    }
  }

  int fetchFctreCallCnt = 0;

  // 단기 날씨 가져오기
  // 24시간 및 주간예보 3일치 셋팅
  Future<void> fetchFct(LatLng location) async {
    try {
      // 2.단기 예보 예제 +3일
      List<ItemFct> itemFctList = await weatherService.getWeatherData<List<ItemFct>>(location, ForecastType.fct);

      // 24시간 및 주간예보 셋팅이 필요함
      List<HourlyWeatherData> data = WeatherDataProcessor.instance.processShortTermForecast(itemFctList);

      // 5시간~ 24시간 데이터만 셋팅
      hourlyWeather.addAll(data);
      hourlyWeather.sort((a, b) => a.date.compareTo(b.date));
      // 중복 제거 date 기준으로
      hourlyWeather.removeWhere((a) => a != hourlyWeather.firstWhere((b) => b.date == a.date));
      hourlyWeather.value = hourlyWeather.toSet().toList();

      // hourlyWeather 가 20개 이상이면 어제 날씨 가져오기 호출
      processingYesterDay(hourlyWeather, yesterdayHourlyWeather);

      // 주간예보에서 3일치까지만 셋팅
      sevenDayWeather.addAll(WeatherDataProcessor.instance.processShortTermForecastToDaily(itemFctList,
          lat: location.latitude, lon: location.longitude, cityName: currentLocation.value!.name));

      // update();
      lo.g('완료!! => fetchFct() time : ${stopwatch.elapsedMilliseconds}ms');

      // 최소 온도 계산 / 최대 온도 계산
      sevenDayMinTemp.value = getMinTemp(sevenDayWeather);
      sevenDayMaxTemp.value = getMaxTemp(sevenDayWeather);
      sevenDayWeather.sort((a, b) => a.fcstDate!.compareTo(b.fcstDate!));

      // 첫번째는 당일로 데이터가 없음으로 제거
      sevenDayWeather.removeAt(0);

      fetchFctreCallCnt = 0;

      // fetchYesterDayWeather(location);
    } catch (e) {
      handleError('3. 단기 예보 조회 오류', e);
      if (fetchFctreCallCnt < 3) {
        Future.delayed(const Duration(milliseconds: 150), () {
          fetchFct(location);
          fetchFctreCallCnt++;
        });
      }
    }
  }

  int fetchMidlanreCallCnt = 0;

  // 중기 날씨 가져오기
  // 3일치 이후 데이터 셋팅
  Future<void> fetchMidlandWeather(LatLng location) async {
    try {
      // 중기육상상태 날씨와 중기기온 날씨를 병렬로 가져오기
      final results = await Future.wait([
        weatherService.getWeatherData<MidLandFcstResponse>(location, ForecastType.midFctLand),
        weatherService.getWeatherData<MidTaResponse>(location, ForecastType.midTa),
      ]);

      // results[0]는 MidLandFcstResponse, results[1]는 MidTaResponse로 캐스팅
      final midLandFcstResponse = results[0] as MidLandFcstResponse;
      final midTaResponse = results[1] as MidTaResponse;

      // 날씨 데이터 처리
      List<SevenDayWeather> tmpList = WeatherDataProcessor.instance.processMidTermForecast(
        midLandFcstResponse,
        midTaResponse,
        lat: location.latitude,
        lon: location.longitude,
        cityName: currentLocation.value!.name,
      );

      // 데이터가 충분하지 않으면 재시도
      if (tmpList.length < 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          fetchMidlandWeather(location);
        });
        return;
      }

      sevenDayWeather.addAll(tmpList);

      // 최소 온도 및 최대 온도 계산
      sevenDayMinTemp.value = getMinTemp(sevenDayWeather);
      sevenDayMaxTemp.value = getMaxTemp(sevenDayWeather);

      lo.g('완료!! => fetchMidlandWeather() time : ${stopwatch.elapsedMilliseconds}ms , sevenDayWeather : ${sevenDayWeather.length}');

      sevenDayWeather.sort((a, b) => a.fcstDate!.compareTo(b.fcstDate!));

      fetchMidlanreCallCnt = 0;
    } catch (e) {
      handleError('4. 중기 예보 조회 오류', e);
      if (fetchMidlanreCallCnt < 3) {
        Future.delayed(const Duration(milliseconds: 150), () {
          fetchMidlandWeather(location);
          fetchMidlanreCallCnt++;
        });
      }
    }
  }

  void test() {
    List<HourlyWeatherData> todayData = [
      HourlyWeatherData(temp: 24.8, sky: '', rain: '', rainPo: null, date: DateTime.parse('2024-08-15 23:00:00.000')),
      HourlyWeatherData(temp: 24.8, sky: '', rain: '', rainPo: null, date: DateTime.parse('2024-08-15 00:00:00.000')),
      HourlyWeatherData(temp: 24.8, sky: '', rain: '', rainPo: null, date: DateTime.parse('2024-08-15 01:00:00.000')),
    ];
    List<HourlyWeatherData> yesterdayData = [
      HourlyWeatherData(temp: 24.8, sky: '', rain: '', rainPo: null, date: DateTime.parse('2024-08-14 00:00:00.000')),
      HourlyWeatherData(temp: 24.8, sky: '', rain: '', rainPo: null, date: DateTime.parse('2024-08-14 01:00:00.000')),
      HourlyWeatherData(temp: 24.8, sky: '', rain: '', rainPo: null, date: DateTime.parse('2024-08-14 02:00:00.000')),
    ];

    var (syncedToday, syncedYesterday) = WeatherDataProcessor.instance.synchronizeWeatherData(todayData, yesterdayData);
    syncedToday.forEach((element) {
      lo.g('processingYesterDay  Today  : ${element.toString()}');
    });
    syncedYesterday.forEach((element) {
      lo.g('processingYesterDay  Yesterday  : ${element.toString()}');
    });
  }

  int fetchYesterDayreCallCnt = 0;

  // 어제 날씨 가져오기
  Future<void> fetchYesterDayWeather(LatLng location) async {
    try {
      // ==========================================================
      // 어제 날씨 가져오기 - 초단기실황조회 한시간전 정보로 구성
      // ==========================================================
      yesterdayHourlyWeather.clear();
      YesterdayHourlyWeatherService yesterdayHourlyWeatherService = YesterdayHourlyWeatherService();
      List<HourlyWeatherData> ylist = await yesterdayHourlyWeatherService.getYesterdayWeather(location);
      // ylist.forEach((element) {
      //   lo.g('processingYesterDay  ylist  : ${element.toString()}');
      // });
      // lo.g('processingYesterDay  ylist  : ${ylist.length}');

      ylist.sort((a, b) => a.date.compareTo(b.date));
      // 다시 호출한다.
      if (ylist.length < 22) {
        handleError('5.어제 날씨 가져오기 조회 오류', '갯수 : ${ylist.length}');
        if (reCallCnt == 2) {
          return;
        }
        reCallCnt++;

        fetchYesterDayWeather(location);
        return;
      }
      reCallCnt = 0;

      double compareTemp = yesterdayHourlyWeatherService.compareTempData(ylist);
      yesterdayDesc.value = compareTemp > 0.0 ? '어제보다 $compareTemp 높아요' : '어제보다 $compareTemp 낮아요';
      yesterdayDesc.value = compareTemp == 0.0 ? '어제와 같아요' : yesterdayDesc.value;

      processingYesterDay(hourlyWeather, ylist);
      lo.g('완료!! => fetchYesterDayWeather() time : ${stopwatch.elapsedMilliseconds}ms , sevenDayWeather : ${sevenDayWeather.length}');

      fetchYesterDayreCallCnt = 0;
      // ==========================================================
    } catch (e) {
      handleError('5.어제 날씨 가져오기 조회 오류', e);
      if (fetchYesterDayreCallCnt < 3) {
        Future.delayed(const Duration(milliseconds: 150), () {
          fetchYesterDayWeather(location);
          fetchYesterDayreCallCnt++;
        });
      }
    }
  }

  double getMinTemp(RxList<SevenDayWeather> list) {
    return list.fold<double?>(null, (minTemp, weather) {
          if (weather.morning.minTemp == null) return minTemp;
          double? currentTemp = double.tryParse(weather.morning!.minTemp!);
          if (currentTemp == null) return minTemp;
          return minTemp == null || currentTemp < minTemp ? currentTemp : minTemp;
        }) ??
        0.0;
  }

  double getMaxTemp(RxList<SevenDayWeather> list) {
    return list
            .where((e) => e.afternoon.maxTemp != null)
            .map((e) => double.tryParse(e!.afternoon!.maxTemp!))
            .where((temp) => temp != null)
            .reduce((value, element) => value! > element! ? value : element) ??
        40.0;
  }

  void handleError(String message, dynamic error) {
    lo.e('$message: $error');
    Utils.alert('$message\n자세한 내용: $error');
  }
}
