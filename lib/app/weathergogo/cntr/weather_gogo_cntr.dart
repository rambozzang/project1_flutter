import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
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
  // 현재 위치 : 동네이름 , 위도 경도
  late Rx<GeocodeData?> currentLocation = GeocodeData(name: '', latLng: const LatLng(0.0, 0.0)).obs;
  late Position positionData;

  // 미세먼지 정보
  Rx<MistViewData?> mistData = MistViewData().obs;

  // 24시간별 날씨 정보
  List<HourlyWeatherData> hourlyWeather = <HourlyWeatherData>[].obs;
  // 7 일별 날씨 정보
  // List<DailyWeather> dailyWeather = <DailyWeather>[].obs;

  // 기상청 날씨 업데이트 시간
  Rx<DateTime?> lastUpdated = DateTime.now().obs;

  // 현재 날씨 정보 - 초단기실황조회 한시간전 정보로 구성
  Rx<CurrentWeatherData?> currentWeather = CurrentWeatherData().obs;
  List<SevenDayWeather> sevenDayWeather = <SevenDayWeather>[].obs;

  //어제 날씨 정보
  late List<ItemSuperNct> yesterdayWeather = <ItemSuperNct>[].obs;
  List<HourlyWeatherData> yesterdayHourlyWeather = <HourlyWeatherData>[].obs;

  // 날씨 가져오는 상태
  Rx<bool> isLoading = true.obs;

  // 어제 날씨 높아요/낮아요 한글
  var yesterdayDesc = ''.obs;

  // WeatherDataProcessor weatherDataProcessor = WeatherDataProcessor();

  // 주간이 최저 최고 온도
  Rx<double> sevenDayMinTemp = 0.0.obs;
  Rx<double> sevenDayMaxTemp = 0.0.obs;

  Rx<bool> isLocationserviceEnabled = false.obs;

  late LocationPermission locationPermission;

  WeatherService weatherService = WeatherService();

  @override
  void onInit() {
    super.onInit();
    // getInitWeatherData(true);
  }

  // 최초 호출 , 영상 등록시 호출
  Future<void> getInitWeatherData(bool isAllSearch) async {
    isLoading.value = true;
    update();
    // 날씨 가져오기
    positionData = await Geolocator.getCurrentPosition();
    currentLocation.value!.latLng = LatLng(positionData.latitude, positionData.longitude);
    await getWeatherDataByLatLng(currentLocation.value!.latLng, isAllSearch);
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

  // 검색후 호출
  Future<void> searchWeatherKakao(GeocodeData geocodeData) async {
    isLoading.value = true;
    update();

    print('searchWeatherKakao :  ${geocodeData.latLng.latitude} ${geocodeData.latLng.longitude} ');
    try {
      LatLng location = LatLng(geocodeData.latLng.latitude, geocodeData.latLng.longitude);

      await getWeatherDataByLatLng(location, true);
      currentLocation.value!.latLng = location;
      currentLocation.value?.name = geocodeData.name;
      update();
    } catch (e) {
      Lo.g('searchWeatherKakao e =>$e');
      //   isLoading.value = false;
    } finally {
      //    isLoading.value = false;
    }
  }

  // video_list_cntr.dart 에서 데이터를 가져온후 호출한다.
  Future<void> getWeatherDataByLatLng(LatLng location, bool isAllSearch) async {
    // 타이머
    Stopwatch stopwatch = Stopwatch()..start();
    isLoading.value = true;

    try {
      // 1.초단기 실황 조회
      // List<ItemSuperNct> itemSuperNctList = await weatherGogoRepo.getSuperNctListJson(location);
      List<ItemSuperNct> itemSuperNctList = await weatherService.getWeatherData<List<ItemSuperNct>>(location, ForecastType.superNct);

      // 1.초단기 실황 파싱처리
      CurrentWeatherData currentWeatherData = WeatherDataProcessor.instance.parsingSuperNct(itemSuperNctList);
      currentWeather.value = currentWeatherData;
      update();
    } catch (e) {
      Lo.e('1.초단기 실황 조회 실패  =>$e');
      Utils.alert('네트웍이 불안정합니다. 다시시도해주세요!');
    }

    // 동네 이름, 미세먼지 정보 가져오기
    await fetchLocalNameAndMistinfo(location);

    // 초단기 예보 조회 - 추시 6시간의 데이터를 이걸로 대체하는것이 좋을듯
    //  List<ItemSuperFct> itemSuperFctList = await weatherGogoRepo.getSuperFctListJson(location);

    // 단기 예보 가져오기
    await fetchFct(location);

    if (!isAllSearch) {
      return;
    }

    // 중기 날씨 가져오기
    await fetchMidlandWeather(location);

    // 어제 날씨 가져오기
    await fetchYesterDayWeather(location);
  }

  // 동네 이름, 미세 먼지 정보 가져오기
  Future<void> fetchLocalNameAndMistinfo(LatLng location) async {
    try {
      // ==========================================================
      // 동네이름, 미세먼지 가져오기
      // ==========================================================
      LocationService locationService = LocationService();
      final (onValue1, onValue2) = await locationService.getLocalName(location);
      currentLocation.value!.name = onValue2!;
      mistData.value = await locationService.getMistData(onValue1!);
      // ==========================================================
      isLoading.value = false;
      update();
    } catch (e) {
      Lo.e('2. 동네이름, 미세먼지 조회 실패 => $e');
    }
  }

  // 단기 날씨 가져오기
  Future<void> fetchFct(LatLng location) async {
    try {
      // 2.단기 예보 예제 +3일
      // List<ItemFct> itemFctList = await weatherGogoRepo.getFctListJson(location);
      List<ItemFct> itemFctList = await weatherService.getWeatherData<List<ItemFct>>(location, ForecastType.fct);

      // 24시간 및 주간예보 셋팅이 필요함
      hourlyWeather.clear();
      hourlyWeather = WeatherDataProcessor.instance.processShortTermForecast(itemFctList);
      currentWeather.value!.sky = hourlyWeather[0].sky;
      currentWeather.value!.rain = hourlyWeather[0].rain;
      // 강수확률
      currentWeather.value!.rainPo = hourlyWeather[0].rainPo;
      currentWeather.value!.description =
          WeatherDataProcessor.instance.combineWeatherCondition(hourlyWeather[0].sky.toString(), hourlyWeather[0].rain.toString());

      // 주간예보에서 3일치까지만 셋팅

      sevenDayWeather = WeatherDataProcessor.instance.processShortTermForecastToDaily(itemFctList,
          lat: location.latitude, lon: location.longitude, cityName: currentLocation.value!.name);
      // 첫번째는 당일로 데이터가 없음으로 제거
      sevenDayWeather.removeAt(0);
      lo.g('==========================================================');
      lo.g('현재 날씨');
      lo.g('==========================================================');
      lo.g('현재기온 : ${currentWeather.value!.toString()}');
      lo.g('==========================================================');
      lo.g('24시간별 날씨');
      lo.g('==========================================================');
      hourlyWeather.forEach((element) {
        Lo.e('hourlyWeather : ${element.date}, ${element.temp}, ${element.sky}, ${element.rain}');
        // lo.g('시간 : ${element.date} , 기온 : ${element.temp} , 날씨 : ${element.weatherCategory} , 강수형태 : ${element.condition}');
      });

      update();
    } catch (e) {
      Lo.e('3. 단기 예보 조회 실패 => $e');
    }
  }

  // 중기 날씨 가져오기
  Future<void> fetchMidlandWeather(LatLng location) async {
    try {
      // 중기육상상태 날씨 가져오기
      // MidLandFcstResponse? midLandFcstResponse = await weatherGogoRepo.getMidFctJson(location);
      MidLandFcstResponse midLandFcstResponse = await weatherService.getWeatherData<MidLandFcstResponse>(location, ForecastType.midFctLand);

      // 중기기온 날씨 가져오기
      // MidTaResponse? midTaResponse = await weatherGogoRepo.getMidTaJson(location);
      MidTaResponse midTaResponse = await weatherService.getWeatherData<MidTaResponse>(location, ForecastType.midTa);

      // lo.g('midTaResponse : ${midTaResponse.toString()}');

      List<SevenDayWeather> tmpList = WeatherDataProcessor.instance.processMidTermForecast(midLandFcstResponse!, midTaResponse!,
          lat: location.latitude, lon: location.longitude, cityName: currentLocation.value!.name);
      sevenDayWeather.addAll(tmpList);

      // 다시 호출한다.
      if (sevenDayWeather.length < 6) {
        fetchMidlandWeather(location);
        return;
      }
      lo.g('==========================================================');
      lo.g('7일간 날씨');
      lo.g('==========================================================');
      sevenDayWeather.forEach((element) {
        lo.g(
            '7일간 : ${element.fcstDate}, 전하늘상태: ${element?.morning.skyDesc}, 전강수활률: ${element?.morning.rainPo}, 전최소온도 ${element?.morning.minTemp}');
        lo.g(
            '7일간 : ${element.fcstDate}, 후하늘상태: ${element?.afternoon.skyDesc}, 후강수활률: ${element?.afternoon.rainPo}, 후최소온도 ${element?.afternoon.maxTemp}');
      });

      sevenDayMinTemp.value = sevenDayWeather.fold<double?>(null, (minTemp, weather) {
            if (weather?.morning?.minTemp == null) return minTemp;
            double? currentTemp = double.tryParse(weather!.morning!.minTemp!);
            if (currentTemp == null) return minTemp;
            return minTemp == null || currentTemp < minTemp ? currentTemp : minTemp;
          }) ??
          0.0;

      sevenDayMaxTemp.value = sevenDayWeather
              .where((e) => e?.afternoon?.maxTemp != null)
              .map((e) => double.tryParse(e!.afternoon!.maxTemp!))
              .where((temp) => temp != null)
              .reduce((value, element) => value! > element! ? value : element) ??
          40.0;

      update();
    } catch (e) {
      lo.e('3. 중기 예보 조회 실패 => $e');
    }
  }

  // 어제 날씨 가져오기
  Future<void> fetchYesterDayWeather(LatLng location) async {
    try {
      // ==========================================================
      // 어제 날씨 가져오기 - 초단기실황조회 한시간전 정보로 구성
      // ==========================================================
      YesterdayHourlyWeatherService yesterdayHourlyWeatherService = YesterdayHourlyWeatherService();
      List<HourlyWeatherData> ylist = await yesterdayHourlyWeatherService.getYesterdayWeather(location);
      // 다시 호출한다.
      if (ylist.length < 20) {
        fetchYesterDayWeather(location);
        return;
      }

      yesterdayHourlyWeather.clear();
      yesterdayHourlyWeather.addAll(ylist);

      double compareTemp = yesterdayHourlyWeatherService.compareTempData(ylist);
      yesterdayDesc.value = compareTemp > 0.0 ? '어제보다 $compareTemp 높아요' : '어제보다 $compareTemp 낮아요';
      yesterdayDesc.value = compareTemp == 0.0 ? '어제와 같아요' : yesterdayDesc.value;

      var (List<HourlyWeatherData> list1, List<HourlyWeatherData> list2) =
          yesterdayHourlyWeatherService.twicelistCompare(hourlyWeather, yesterdayHourlyWeather);
      hourlyWeather.clear();
      yesterdayHourlyWeather.clear();
      hourlyWeather = list1.toList();
      yesterdayHourlyWeather = list2.toList();
      isLoading.value = false;
      // ==========================================================
      update();
    } catch (e) {
      Lo.e('어제 날씨 가져오기 조회 실패 =>$e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
