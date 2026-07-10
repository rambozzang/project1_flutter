import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/app/weathergogo/theme/sky_gradient.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/repo/common/code_data.dart';
import 'package:project1/repo/common/comm_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_tag_res_data.dart';
import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/repo/mist_gogoapi/mist_repo.dart';
import 'package:project1/repo/weather/data/weather_view_data.dart';
import 'package:project1/app/weathergogo/cntr/data/current_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/data/daily_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/data/hourly_weather_data.dart';
import 'package:project1/app/weathergogo/services/location_service.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/weather_gogo/adapter/adapter_map.dart';
import 'package:project1/repo/weather_gogo/sources/backend_weather_api.dart';
import 'package:project1/app/weathergogo/services/yesterday_weather_service.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/midland_fct/midlan_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/midta_fct/midta_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/special_alert/special_alert_res.dart';
import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_caching.dart';
import 'package:project1/utils/StringUtils.dart';
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
  // AirKorea 원본 데이터(상세 모달용)
  final Rx<MistData?> mistDetailData = Rx<MistData?>(null);
  final RxList<HourlyWeatherData> hourlyWeather = <HourlyWeatherData>[].obs;
  final RxList<SevenDayWeather> sevenDayWeather = <SevenDayWeather>[].obs;
  final Rx<DateTime> lastUpdated = DateTime.now().obs;
  final Rx<CurrentWeatherData> currentWeather = CurrentWeatherData(temp: '0.0').obs;
  final RxList<ItemSuperNct> yesterdayWeather = <ItemSuperNct>[].obs;
  final RxList<HourlyWeatherData> yesterdayHourlyWeather = <HourlyWeatherData>[].obs;
  final Rx<WeatherAlertRes?> weatherAlert = Rx<WeatherAlertRes?>(null);

  final ValueNotifier<bool> isRainVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSnowVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isRainDropVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isCloudVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isHazyVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSunnyVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDarkCloudVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDaySun = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isNightSun = ValueNotifier<bool>(false);

  final RxList<CustagResData> areaList = <CustagResData>[].obs;

  final RxString yesterdayDesc = ''.obs;
  final Rx<double> sevenDayMinTemp = 0.0.obs;
  final Rx<double> sevenDayMaxTemp = 0.0.obs;
  final RxBool isLocationserviceEnabled = false.obs;

  int reCallCnt = 0;

  late LocationPermission locationPermission;
  final WeatherService weatherService = WeatherService();
  final LocationService locationService = LocationService();

  List<Color> nightColors = [
    const Color(0xFF0c1445), // 짙은 남색
    const Color(0xFF1c2951), // 미드나이트 블루
    const Color(0xFF2c3e67), // 네이비 블루
    const Color(0xFF4a5d8f), // 연한 네이비 블루/ 연한
  ];
  List<Color> dayColors = [
    const Color.fromARGB(255, 43, 69, 120),
    const Color.fromARGB(255, 43, 69, 120),
    const Color.fromARGB(255, 47, 98, 169),
    const Color.fromARGB(255, 47, 98, 169),
    const Color.fromARGB(255, 43, 69, 120),
  ];

  RxList<Color> currentColors = <Color>[].obs;

  late Color appbarColor;

  // 시간 흐름에 따라 하늘색을 서서히 갱신하는 타이머
  Timer? _skyTimer;

  /// 현재 시각에 맞는 하늘 그라데이션으로 갱신.
  void _updateSky() {
    final now = DateTime.now();
    currentColors.value = SkyGradient.colorsFor(now);
    appbarColor = currentColors.first;
    isNightSun.value = SkyGradient.nightFactor(now) > 0.5;
  }

  @override
  void onInit() {
    super.onInit();
    _updateSky();
    // 10분마다 하늘색을 다시 계산 → 새벽·노을이 실시간으로 흐르듯 변한다.
    _skyTimer = Timer.periodic(const Duration(minutes: 10), (_) => _updateSky());
  }

  @override
  void onClose() {
    _skyTimer?.cancel();
    super.onClose();
  }

  // 최초 호출 , 영상 등록시 호출
  Future<void> getInitWeatherData(bool isAllSearch) async {
    await getWeatherDataByLatLng(currentLocation.value.latLng, isAllSearch);
  }

  // app bar 에서 호출
  Future<void> getCurrentWeatherData(bool isAllSearch) async {
    if (loadingCheck()) {
      return;
    }

    isLoading.value = true;

    // 날씨 가져오기 (GPS 지연/타임아웃 시 마지막 위치→기존 좌표로 폴백 = 화면 멈춤 방지)
    try {
      positionData.value = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      lo.g('getCurrentWeatherData 위치 타임아웃/오류: $e');
      positionData.value = await Geolocator.getLastKnownPosition().catchError((_) => null) ?? positionData.value;
    }
    if (positionData.value != null) {
      currentLocation.value.latLng = LatLng(positionData.value!.latitude, positionData.value!.longitude);
    }
    await getWeatherDataByLatLng(currentLocation.value.latLng, isAllSearch);
  }

  bool loadingCheck() {
    // 하나라도 로딩중이면 제어한다.
    if (isLoading.value == true || isYestdayLoading.value == true) {
      String msg = isYestdayLoading.value == true ? '어제 ' : '';
      Utils.alert('$msg데이터 수집중입니다. 잠시만요..', align: 'TOP');
      return true;
    }
    return false;
  }

  Future<void> getRefreshWeatherData(bool isAllSearch) async {
    if (loadingCheck()) {
      return;
    }
    isLoading.value = true;
    await getWeatherDataByLatLng(currentLocation.value.latLng, isAllSearch);
  }

  // 서울시청 좌표 — 위치 권한/서비스가 없을 때의 기본 위치.
  static const LatLng _defaultLatLng = LatLng(37.5665, 126.9780);

  // Auth_page.dart 에서 호출한다.
  // 1 위치 권한 확인 및 요청
  Future<Position> requestLocation() async {
    // 위치 서비스/권한은 선택 사항이다. 사용할 수 없으면 기본 위치(서울)로 폴백하고
    // 앱은 계속 동작한다. 화면을 막거나(BackButtonBehavior.none) 설정 앱으로 유도하지 않는다.
    // (Apple 5.1.5: 위치 없이도 완전히 동작 / 5.1.1: 설정 앱 리디렉트 금지)
    isLocationserviceEnabled.value = await Geolocator.isLocationServiceEnabled();

    if (isLocationserviceEnabled.value) {
      locationPermission = await Geolocator.checkPermission();
      lo.g(locationPermission.toString());
      // 아직 결정 전(denied)일 때만 OS 권한 요청을 1회 띄운다(영구 거부면 재요청/설정유도 안 함).
      if (locationPermission == LocationPermission.denied) {
        locationPermission = await Geolocator.requestPermission();
      }
    }

    final bool granted = isLocationserviceEnabled.value &&
        (locationPermission == LocationPermission.always ||
            locationPermission == LocationPermission.whileInUse);

    if (!granted) {
      // 위치 서비스 꺼짐 또는 권한 없음 → 기본 위치(서울)로 진행.
      return _fallbackToDefaultLocation();
    }

    // ── 빠른 진입(콜드 GPS 픽스 대기 제거) ──
    // 마지막으로 알려진 위치가 있으면 즉시 사용해 홈으로 바로 진입하고,
    // 정밀 위치는 백그라운드에서 조용히 갱신한다. (GPS 의존성은 그대로 유지)
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        positionData.value = last;
        currentLocation.value.latLng = LatLng(last.latitude, last.longitude);
        _refinePositionInBackground(); // fire-and-forget
        return last;
      }
    } catch (e) {
      lo.g('getLastKnownPosition skip: $e');
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

  // 위치 권한/서비스가 없을 때 기본 위치(서울)로 폴백한다.
  // 날씨는 서울 기준으로 로드되며, 사용자는 상단 검색으로 다른 지역을 선택할 수 있다.
  Future<Position> _fallbackToDefaultLocation() async {
    currentLocation.value = GeocodeData(name: '서울', latLng: _defaultLatLng);
    final Position pos = Position(
      latitude: _defaultLatLng.latitude,
      longitude: _defaultLatLng.longitude,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    positionData.value = pos;
    return pos;
  }

  // 마지막 위치로 먼저 진입한 뒤, 정밀 위치를 백그라운드에서 갱신한다.
  // (날씨는 이미 마지막 위치로 선로딩됨 → 큰 이동이 아니면 차이 없음, 다음 새로고침에 반영)
  Future<void> _refinePositionInBackground() async {
    try {
      final precise = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      positionData.value = precise;
      currentLocation.value.latLng = LatLng(precise.latitude, precise.longitude);
    } catch (e) {
      lo.g('background precise location error: $e');
    }
  }

  // 검색후 호출
  Future<void> searchWeatherKakao(GeocodeData geocodeData) async {
    if (loadingCheck()) {
      return;
    }
    isLoading.value = true;
    try {
      LatLng location = LatLng(geocodeData.latLng.latitude, geocodeData.latLng.longitude);

      // 20241105 Getx5.0.1 버전
      // currentLocation.update((val) {
      //   val?.latLng = location;
      //   val?.name = geocodeData.name;
      // });

      currentLocation.value.latLng = location;
      currentLocation.value.name = geocodeData.name;
      currentLocation.refresh();

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
      // webViewUrl.value = '${webViewUrl.value} + ${location.longitude},${location.latitude},2780/loc=';
      // 5분후 해제
      Timer(const Duration(seconds: 15), () {
        isLoading.value = false;
        isYestdayLoading.value = false;
      });

      hourlyWeather.clear();
      sevenDayWeather.clear();
      yesterdayHourlyWeather.clear();
      yesterdayDesc.value = '';

      await Future.wait([
        fetchSuperNct(location),
        fetchSuperFct(location),
        fetchFct(location),
        fetchMidlandWeather(location),
        fetchLocalNameAndMistinfo(location),
        // fetchYesterDayWeather(location)
        // fetchWeatherAlert(location),
      ]);

      isLoading.value = false;

      // 뉴스는 날씨 렌더링과 무관하므로 크리티컬 경로에서 분리(로딩 대기시간에서 제외).
      // 실패해도 날씨엔 영향 없도록 fire-and-forget.
      unawaited(searchNaverNews());
      lo.e('최종  현재온도 : ${currentWeather.value.temp.toString()}');
      lo.g("=========================================================");
      lo.g("========================================================");
      lo.g("=========================================================");

      lo.g('getWeatherDataByLatLng initialization time: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      handleError('getWeatherDataByLatLng() 오류', e);
      isLoading.value = false;
      isYestdayLoading.value = false;
    } finally {
      stopwatch.stop();
      // searchNaverNews();
    }
  }

  // 특보 정보 가져오기
  Future<void> fetchWeatherAlert(LatLng location) async {
    try {
      // ==========================================================
      // 특보 정보 가져오기
      // ==========================================================
      WeatherAlertRes res = await weatherService.getWeatherData<WeatherAlertRes>(location, ForecastType.weatherAlert);
      lo.g('bbb=> ${res.toString()}');
      if (!StringUtils.isEmpty(res.title)) {
        String title = res.title!;
        if (title.split('/')[1].contains('특보')) {
          weatherAlert.value = res;
        } else {
          weatherAlert.value = null;
        }
        return;
      }

      // ==========================================================
      lo.g('완료!! => fetchSpecialWeather() time : ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      handleError('특보 정보 오류', e);
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
      // 20241105 Getx5.0.1 버전
      // currentLocation.update((val) {
      //   val?.name = onValue2;
      //   val?.addr = '$onValue1 $onValue2';
      // });

      currentLocation.value.name = onValue2;
      currentLocation.value.addr = '$onValue1 $onValue2';
      currentLocation.refresh();

      final MistRepo mistRepo = MistRepo();
      final MistData? rawMistData = await mistRepo.getMistData(onValue1);
      if (rawMistData == null || rawMistData.items == null || rawMistData.items!.isEmpty) {
        return;
      }
      mistDetailData.value = rawMistData;
      mistData.value = MistViewData(
        mist10: rawMistData.items![0].pm10Value!,
        mist25: rawMistData.items![0].pm25Value!,
        mist10Grade: mistRepo.getMist10Grade(rawMistData.items![0].pm10Value!),
        mist25Grade: mistRepo.getMist25Grade(rawMistData.items![0].pm25Value!),
      );
      // ==========================================================
      lo.g('완료!! => fetchLocalNameAndMistinfo() time : ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      // handleError('동네 이름, 미세 먼지 정보 오류', e);
    }
  }

  String compareFcsTime(String? time1, String? time2) {
    if (time1 == null) {
      return time2!;
    }
    if (time2 == null) {
      return time1;
    }

    time1 = time1.replaceAll(':', '');
    time2 = time2.replaceAll(':', '');
    int t1 = int.parse(time1);
    int t2 = int.parse(time2);

    // time1 이 23:00 이며 time2 가 01:00 이면 time2 를 리턴
    if (t1 >= 2300 && t2 < 100) {
      return time2;
    }
    if (t1 >= 2300 && t2 == 0) {
      return time2;
    }

    if (t1 > t2) {
      return time1;
    } else if (t1 < t2) {
      return time2;
    } else {
      return time2;
    }
  }

  int fetchSuperNctreCallCnt = 0;
  // 초단기 실황 가져오기
  Future<void> fetchSuperNct(LatLng location) async {
    try {
      // 백엔드 경유(/weather/current) - data.go.kr 직접호출 대신 백엔드 캐시 사용 (앱 키 quota 무관)
      final changeMap = MapAdapter.changeMap(location.longitude, location.latitude);
      List<ItemSuperNct> itemSuperNctList = await BackendWeatherApi().getCurrentWeather(changeMap.x, changeMap.y);
      if (itemSuperNctList.isEmpty) {
        lo.g('백엔드 현재날씨 빈응답 nx=${changeMap.x} ny=${changeMap.y}');
        return;
      }
      // 1.초단기 실황 파싱처리
      CurrentWeatherData value = WeatherDataProcessor.instance.parsingSuperNct(itemSuperNctList);
      lo.e('초단기 실황 현재온도 : ${value.temp}');

      // 20241105 Getx5.0.1 버전
      // currentWeather.update((val) {
      //   val?.temp = value.temp;
      //   // val?.rain = value.rain;
      //   val?.fcsTime = compareFcsTime(val.fcsTime, value.fcsTime!); // 발표시간 -> 날이 바뀌면?? 20240822 2300 하고 20240823 0100 하고 비교
      //   val?.fcstDate = value.fcstDate; // 예보시간
      //   val?.humidity = value.humidity;
      //   val?.speed = value.speed;
      //   val?.deg = value.deg;
      //   // val?.rainDesc = value.rainDesc;
      //   // val?.rain1h = value.rain1h;
      // });

      currentWeather.value.temp = value.temp;
      currentWeather.value.humidity = value.humidity;
      currentWeather.value.speed = value.speed;
      currentWeather.value.deg = value.deg;
      // currentWeather.value.rain = value.rain;
      // currentWeather.value.rainDesc = value.rainDesc;
      // currentWeather.value.rain1h = value.rain1h;
      currentWeather.value.fcsTime = compareFcsTime(currentWeather.value.fcsTime, value.fcsTime!);
      currentWeather.value.fcstDate = value.fcstDate;
      currentWeather.refresh();

      lo.g('완료!! => fetchSuperNct() time : ${stopwatch.elapsedMilliseconds}ms');

      fetchSuperNctreCallCnt = 0;
    } catch (e) {
      handleError('1. 초단기 실황 조회 오류', e);
      if (fetchSuperNctreCallCnt < 3) {
        Future.delayed(const Duration(milliseconds: 350), () {
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
      List<HourlyWeatherData> resultList = [];
      // 2.초단기 예보 가져오기
      final changeMap = MapAdapter.changeMap(location.longitude, location.latitude);
      List<ItemSuperFct> itemFctList = await BackendWeatherApi().getSuperFct(changeMap.x, changeMap.y);
      if (itemFctList.isEmpty) {
        lo.g('백엔드 초단기예보 빈응답 nx=${changeMap.x} ny=${changeMap.y}');
        return;
      }
      // 2.초단기 예보 파싱처리
      List<HourlyWeatherData> data = WeatherDataProcessor.instance.processSuperShortTermForecast(itemFctList);
      // data.forEach((element) {
      //   lo.g('fetchSuperFct  data  : ${element.toString()}');
      // });
      // T1H	기온	℃
      // RN1	1시간 강수량	범주 (1 mm)
      // SKY	하늘상태	맑음(1), 구름많음(3), 흐림(4)
      // UUU	동서바람성분	m/s
      // VVV	남북바람성분	m/s
      // REH	습도	%
      // PTY	강수형태	(초단기) 없음(0), 비(1), 비/눈(2), 눈(3), 빗방울(5), 빗방울눈날림(6), 눈날림(7)
      // LGT	낙뢰	kA(킬로암페어)
      // VEC	풍향	deg
      // WSD	풍속	m/s

      //  itemFctList 첫번째로 돌아는 category 가 Rn1 값을 셋팅
      String rain1h = itemFctList.firstWhere((element) => element.category == 'RN1').fcstValue.toString();
      String skyDesc = itemFctList.firstWhere((element) => element.category == 'LGT').fcstValue.toString();
      String weatherDesc = WeatherDataProcessor.instance.combineWeatherCondition(data[0].sky.toString(), data[0].rain.toString());
      initAnimation(weatherDesc);

      lo.e('초단기 예보 현재온도 : ${data[0].temp.toString()}');

      // 20241105 Getx5.0.1 버전
      // currentWeather.update((val) {
      //   val?.temp = val.temp == '0.0' ? data[0].temp.toString() : val.temp;
      //   val?.description = weatherDesc;
      //   val?.sky = data[0].sky;
      //   val?.skyDesc = skyDesc;
      //   val?.rain1h = rain1h == '강수없음' ? '0' : rain1h;
      //   val?.rain = data[0].rain;
      //   val?.rainDesc = weatherDesc;
      //   val?.fcsTime = compareFcsTime(val.fcsTime, itemFctList[0].baseTime); // 발표시간
      // });

      currentWeather.value.temp = currentWeather.value.temp == '0.0' ? data[0].temp.toString() : currentWeather.value.temp;
      currentWeather.value.description = weatherDesc;
      currentWeather.value.sky = data[0].sky;
      currentWeather.value.skyDesc = skyDesc;
      currentWeather.value.rain1h = rain1h == '강수없음' ? '0' : rain1h;
      currentWeather.value.rain = data[0].rain;
      currentWeather.value.rainDesc = weatherDesc;
      currentWeather.value.fcsTime = compareFcsTime(currentWeather.value.fcsTime, itemFctList[0].baseTime); // 발표시간
      currentWeather.refresh();

      resultList.addAll(data);
      // 중복 제거 date 기준으로
      resultList.removeWhere((a) => a != resultList.firstWhere((b) => b.date == a.date));
      // hourlyWeather.addAll(resultList);
      List<HourlyWeatherData> tempList = hourlyWeather.toList();
      tempList.addAll(resultList);
      hourlyWeather.value = tempList;

      // hourlyWeather 가 20개 이상이면 어제 날씨 가져오기 호출
      isCallyeasterDay(hourlyWeather, location);
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

  void isCallyeasterDay(List<HourlyWeatherData> hWeather, LatLng location) {
    final now = DateTime.now();
    final firstHour = hWeather.first.date.hour;
    final isWithinTwoHours = (now.hour - firstHour).abs() <= 2;
    if (isWithinTwoHours && hWeather.length > 20) {
      fetchYesterDayWeather(location);
    }
  }

  // fetchYesterDayWeather() 에서 호출
  void processingYesterDay(List<HourlyWeatherData> hWeather, List<HourlyWeatherData> yHWeather) {
    // 중복 제거 함수
    List<HourlyWeatherData> removeDuplicates(List<HourlyWeatherData> list) {
      final seen = <String>{};
      return list.where((data) {
        final key = '${data.date.day}-${data.date.hour}';
        if (seen.contains(key)) {
          return false;
        } else {
          seen.add(key);
          return true;
        }
      }).toList();
    }

    if (hWeather.length > 20 && yHWeather.length > 20) {
      hWeather.sort((a, b) => a.date.compareTo(b.date));
      yHWeather.sort((a, b) => a.date.compareTo(b.date));
      var (syncedToday, syncedYesterday) = WeatherDataProcessor.instance.synchronizeWeatherData(hWeather, yHWeather);

      // 중복 제거 적용
      syncedToday = removeDuplicates(syncedToday);
      syncedYesterday = removeDuplicates(syncedYesterday);

      hourlyWeather.value = syncedToday.toList();
      yesterdayHourlyWeather.value = syncedYesterday.toList();
    }
  }

  void logHourlyWeather() {
    for (var element in hourlyWeather) {
      lo.g('processingYesterDay  hourlyWeather  : ${element.toString()}');
    }
  }

  void logyestdayHourlyWeather() {
    for (var element in yesterdayHourlyWeather) {
      lo.g('processingYesterDay yesterdayHourlyWeather  : ${element.toString()}');
    }
  }

  int fetchFctreCallCnt = 0;

  // 단기 날씨 가져오기
  // 24시간 및 주간예보 3일치 셋팅
  Future<void> fetchFct(LatLng location) async {
    try {
      List<HourlyWeatherData> resultList = [];

      // 백엔드 경유(/weather/fct) - data.go.kr 직접호출 대신 백엔드 캐시 사용
      final changeMap = MapAdapter.changeMap(location.longitude, location.latitude);
      List<ItemFct> itemFctList = await BackendWeatherApi().getFct(changeMap.x, changeMap.y);
      if (itemFctList.isEmpty) {
        lo.g('백엔드 단기예보 빈응답 nx=${changeMap.x} ny=${changeMap.y}');
        return;
      }

      // 24시간 및 주간예보 셋팅이 필요함
      List<HourlyWeatherData> data = WeatherDataProcessor.instance.processShortTermForecast(itemFctList);

      // resultList.addAll(hourlyWeather);
      resultList.addAll(data);

      // 5시간~ 24시간 데이터만 셋팅
      // hourlyWeather.addAll(data);
      resultList.sort((a, b) => a.date.compareTo(b.date));
      // 중복 제거 date 기준으로
      resultList.removeWhere((a) => a != resultList.firstWhere((b) => b.date == a.date));

      resultList = resultList.toSet().toList();
      // hourlyWeather.addAll(resultList);
      List<HourlyWeatherData> tempList = hourlyWeather.toList();
      tempList.addAll(resultList);
      hourlyWeather.value = tempList;

      // hourlyWeather 가 20개 이상이면 어제 날씨 가져오기 호출
      isCallyeasterDay(hourlyWeather, location);

      // 주간예보에서 3일치까지만 셋팅
      sevenDayWeather.addAll(WeatherDataProcessor.instance.processShortTermForecastToDaily(itemFctList,
          lat: location.latitude, lon: location.longitude, cityName: currentLocation.value.name));

      // update();
      lo.g('완료!! => fetchFct() time : ${stopwatch.elapsedMilliseconds}ms');

      // 최소 온도 계산 / 최대 온도 계산
      sevenDayMinTemp.value = getMinTemp(sevenDayWeather);
      sevenDayMaxTemp.value = getMaxTemp(sevenDayWeather);
      sevenDayWeather.sort((a, b) => a.fcstDate!.compareTo(b.fcstDate!));

      // 첫번째는 당일로 데이터가 없음으로 제거
      sevenDayWeather.removeAt(0);

      fetchFctreCallCnt = 0;

      isLoading.value = false;
      fetchYesterDayWeather(location);
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
        cityName: currentLocation.value.name,
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

  int fetchYesterDayreCallCnt = 0;

  // 어제 날씨 가져오기
  Future<void> fetchYesterDayWeather(LatLng location, {int? reCallCnt}) async {
    reCallCnt ??= 0;
    try {
      // ==========================================================
      // 어제 날씨 가져오기 - 초단기실황조회 한시간전 정보로 구성
      // ==========================================================
      yesterdayHourlyWeather.clear();
      YesterdayHourlyWeatherService yesterdayHourlyWeatherService = YesterdayHourlyWeatherService();
      List<HourlyWeatherData> ylist = await yesterdayHourlyWeatherService.getYesterdayWeather(location);
      ylist.sort((a, b) => a.date.compareTo(b.date));
      reCallCnt = 0;
      double compareTemp = yesterdayHourlyWeatherService.compareTempData(ylist);
      yesterdayDesc.value = compareTemp > 0.0 ? '어제보다 $compareTemp 높아요' : '어제보다 $compareTemp 낮아요';
      yesterdayDesc.value = compareTemp == 0.0 ? '어제와 같아요' : yesterdayDesc.value;
      processingYesterDay(hourlyWeather, ylist);
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
    } finally {
      isYestdayLoading.value = false;
      // return true;
    }
  }

  double getMinTemp(RxList<SevenDayWeather> list) {
    return list.fold<double?>(null, (minTemp, weather) {
          if (weather.morning.minTemp == null) return minTemp;
          double? currentTemp = double.tryParse(weather.morning.minTemp!);
          if (currentTemp == null) return minTemp;
          return minTemp == null || currentTemp < minTemp ? currentTemp : minTemp;
        }) ??
        0.0;
  }

  double getMaxTemp(RxList<SevenDayWeather> list) {
    return list
            .where((e) => e.afternoon.maxTemp != null)
            .map((e) => double.tryParse(e.afternoon.maxTemp!))
            .where((temp) => temp != null)
            .reduce((value, element) => value! > element! ? value : element) ??
        40.0;
  }

  void handleError(String message, dynamic error) {
    lo.e('$message: $error');
  }

  Future<void> getLocalTag() async {
    try {
      CustRepo repo = CustRepo();
      ResData res = await repo.getTagList(AuthCntr.to.resLoginData.value.custId.toString(), 'LOCAL');
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      areaList.value = ((res.data) as List).map((data) => CustagResData.fromMap(data)).toList();
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  RxList<CodeRes> naverNewsList = RxList.empty();

  Future<void> searchNaverNews() async {
    try {
      naverNewsList.clear();
      CommRepo repo = CommRepo();
      CodeReq reqData = CodeReq();
      reqData.pageNum = 0;
      reqData.pageSize = 100;
      reqData.grpCd = 'WH_NEWS';
      reqData.code = '';
      reqData.useYn = 'Y';
      ResData res = await repo.searchCode(reqData);

      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      List<CodeRes> list = (res.data as List).map<CodeRes>((e) => CodeRes.fromMap(e)).toList();

      naverNewsList.value = list;
      lo.g('searchRecomWord : ${res.data}');
    } catch (e) {
      lo.g('error searchRecomWord : $e');
    }
  }

  void toggleRain() {
    isRainVisibleNotifier.value = !isRainVisibleNotifier.value;
  }

  void toggleSnow() {
    isSnowVisibleNotifier.value = !isSnowVisibleNotifier.value;
  }

  // 비 눈 흐름 등등 애니메이션
  void initAnimation(String weatherDesc) {
    // 초기화
    isRainVisibleNotifier.value = false;
    isRainDropVisibleNotifier.value = false;
    isSnowVisibleNotifier.value = false;
    isHazyVisibleNotifier.value = false;
    isCloudVisibleNotifier.value = false;
    isDarkCloudVisibleNotifier.value = false;
    if ((DateTime.now().hour >= 19 || DateTime.now().hour < 7)) {
      isNightSun.value = true;
    } else {
      isDaySun.value = true;
    }

    // 맑음
    if (weatherDesc.contains('맑음')) {
      isSunnyVisibleNotifier.value = true;
    }
    // 비, 소나기
    if (weatherDesc.contains('비') || weatherDesc.contains('소나기')) {
      isRainVisibleNotifier.value = true;
      isDaySun.value = false;
    }
    if (weatherDesc.contains('빗')) {
      isRainDropVisibleNotifier.value = true;
      isDarkCloudVisibleNotifier.value = false;
    }
    if (weatherDesc.contains('눈')) {
      isSnowVisibleNotifier.value = true;
      isDaySun.value = false;
    }
    if (weatherDesc.contains('흐림')) {
      isHazyVisibleNotifier.value = true;
      isDarkCloudVisibleNotifier.value = true;
      isDaySun.value = false;
    }
    if (weatherDesc.contains('구름')) {
      isCloudVisibleNotifier.value = true;
    }

    // isRainVisibleNotifier.value = true;
    // isRainDropVisibleNotifier.value = true;
    // isSnowVisibleNotifier.value = true;
    // isHazyVisibleNotifier.value = true;
    // isCloudVisibleNotifier.value = true;
    // isDarkCloudVisibleNotifier.value = true;
  }

  void changeBgColor() {
    if (currentColors == nightColors) {
      currentColors.value = dayColors;
      appbarColor = dayColors.first;
      isDaySun.value = true;
    } else {
      currentColors.value = nightColors;
      appbarColor = nightColors.first;
      isDaySun.value = false;
    }
  }
}
