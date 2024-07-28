import 'package:project1/app/weathergogo/cntr/data/current_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/data/daily_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/data/hourly_weather_data.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/midland_fct/midlan_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/midta_fct/midta_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';

class WeatherDataProcessor {
  // 프라이빗 생성자
  WeatherDataProcessor._();

  // 정적 인스턴스
  static final WeatherDataProcessor instance = WeatherDataProcessor._();

  List<SevenDayWeather> processShortTermForecastToDaily(List<ItemFct> forecastItems, {double? lat, double? lon, String? cityName}) {
    Map<String, SevenDayWeather> dailyMap = {};

    for (var item in forecastItems) {
      String? forecastDate = item.fcstDate;
      String? forecastTime = item.fcstTime;
      if (forecastDate == null) continue;

      if (!dailyMap.containsKey(forecastDate)) {
        dailyMap[forecastDate] = SevenDayWeather(
          lat: lat,
          lon: lon,
          cityName: cityName,
          fcstDate: forecastDate,
          fcstTime: forecastTime,
          morning: DayWeatherData(),
          afternoon: DayWeatherData(),
        );
      }

      bool isMorning = int.parse(item.fcstTime!) < 1200;
      DayWeatherData timeData = isMorning ? dailyMap[forecastDate]!.morning : dailyMap[forecastDate]!.afternoon;

      switch (item.category) {
        case 'TMP':
          timeData.temp = item.fcstValue;
          break;
        case 'TMN':
          dailyMap[forecastDate]!.morning.minTemp = item.fcstValue;
          break;
        case 'TMX':
          dailyMap[forecastDate]!.afternoon.maxTemp = item.fcstValue;
          break;
        case 'SKY':
          timeData.sky = item.fcstValue;
          timeData.skyDesc = parseSkyState(item.fcstValue ?? '');
          break;
        case 'PTY':
          timeData.rain = item.fcstValue;
          timeData.rainDesc = parseRainType(item.fcstValue ?? '');
          break;
        case 'WSD':
          timeData.speed = item.fcstValue;
          break;
        case 'VEC':
          timeData.deg = item.fcstValue;
          break;
        case 'REH':
          timeData.humidity = item.fcstValue;
          break;
        case 'POP':
          timeData.rainPo = item.fcstValue;
          break;
      }
    }

    List<SevenDayWeather> dailyList = dailyMap.values.toList();
    dailyList.sort((a, b) => a.fcstDate!.compareTo(b.fcstDate!));

    return dailyList.take(3).toList();
  }

  //24시가지 날씨 정보 파싱처리
  List<HourlyWeatherData> processShortTermForecast(List<ItemFct> forecastItems) {
    Map<DateTime, HourlyWeatherData> hourlyMap = {};

    for (var item in forecastItems) {
      DateTime forecastDate = DateTime.parse('${item.fcstDate} ${item.fcstTime}');

      // ???? 무슨의미지?
      if (!hourlyMap.containsKey(forecastDate)) {
        hourlyMap[forecastDate] = HourlyWeatherData(
          temp: 0,
          sky: '',
          date: forecastDate,
        );
      }

      switch (item.category) {
        case 'TMP':
          hourlyMap[forecastDate]!.temp = double.parse(item.fcstValue!);
          break;
        case 'SKY':
          hourlyMap[forecastDate]!.sky = item.fcstValue!;
          break;
        case 'PTY':
          hourlyMap[forecastDate]!.rain = item.fcstValue!;
        case 'POP':
          hourlyMap[forecastDate]!.rainPo = item.fcstValue!;
          break;
      }
    }

    List<HourlyWeatherData> hourlyList = hourlyMap.values.toList();
    hourlyList.sort((a, b) => a.date.compareTo(b.date));

    // 최대 24개의 항목만 반환
    return hourlyList.take(24).toList();
  }

  // 중기 예보 조합 최종 sevendayWeather에 적재
  List<SevenDayWeather> processMidTermForecast(MidLandFcstResponse landForecast, MidTaResponse taForecast,
      {double? lat, double? lon, String? cityName}) {
    List<SevenDayWeather> midTermList = [];

    // 시작 날짜 계산 (오늘로부터 3일 후)
    DateTime startDate = DateTime.now().add(Duration(days: 3));

    for (int i = 0; i < 5; i++) {
      // 중기 예보는 5일치 데이터를 제공 (3일 후부터 7일 후까지)
      String fcstDate = startDate.add(Duration(days: i)).toString().substring(0, 10).replaceAll('-', '');

      SevenDayWeather weatherData = SevenDayWeather(
        lat: lat,
        lon: lon,
        cityName: cityName,
        fcstDate: fcstDate,
        morning: DayWeatherData(),
        afternoon: DayWeatherData(),
      );

      // 아침 데이터 설정
      weatherData.morning.skyDesc = _getSkyState(landForecast, i + 3, isAm: true);
      weatherData.morning.rainPo = _getRainProbability(landForecast, i + 3, isAm: true).toString();
      weatherData.morning.minTemp = _getTemperature(taForecast, 'taMin${i + 3}');

      // 오후 데이터 설정
      weatherData.afternoon.skyDesc = _getSkyState(landForecast, i + 3, isAm: false);
      weatherData.afternoon.rainPo = _getRainProbability(landForecast, i + 3, isAm: false).toString();
      weatherData.afternoon.maxTemp = _getTemperature(taForecast, 'taMax${i + 3}');

      // 공통 데이터 설정
      weatherData.morning.temp = weatherData.morning.minTemp;
      weatherData.afternoon.temp = weatherData.afternoon.maxTemp;

      midTermList.add(weatherData);
    }

    return midTermList;
  }

  // 초단기 실황조회 파싱처리
  CurrentWeatherData parsingSuperNct(List<ItemSuperNct> list) {
    CurrentWeatherData currentWeather = CurrentWeatherData();
    list.forEach((e) {
      // 현재 날씨 정보
      if (e.category == 'T1H') {
        currentWeather.temp = e.obsrValue;
        currentWeather.fcsTime = e.baseTime;
        currentWeather.fcstDate = e.baseDate;
      }

      // 습도
      if (e.category == 'REH') {
        currentWeather.humidity = e.obsrValue;
      }
      // 풍속
      if (e.category == 'WSD') {
        currentWeather.speed = e.obsrValue;
      }
      // 풍향
      if (e.category == 'VEC') {
        currentWeather.deg = e.obsrValue;
      }
      // 강수형태
      if (e.category == 'PTY') {
        currentWeather.rain = e.obsrValue;
        currentWeather.rainDesc = parseRainType(e.obsrValue.toString());
      }
      // 강수량
      if (e.category == 'RN1') {
        currentWeather.rain1h = e.obsrValue;
      }
    });
    return currentWeather;
  }

// 헬퍼 함수들
  String _getSkyState(MidLandFcstResponse landForecast, int day, {bool isAm = true}) {
    switch (day) {
      case 3:
        return isAm ? landForecast.wf3Am : landForecast.wf3Pm;
      case 4:
        return isAm ? landForecast.wf4Am : landForecast.wf4Pm;
      case 5:
        return isAm ? landForecast.wf5Am : landForecast.wf5Pm;
      case 6:
        return isAm ? landForecast.wf6Am : landForecast.wf6Pm;
      case 7:
        return isAm ? landForecast.wf7Am : landForecast.wf7Pm;
      default:
        return '';
    }
  }

  int _getRainProbability(MidLandFcstResponse landForecast, int day, {bool isAm = true}) {
    switch (day) {
      case 3:
        return isAm ? landForecast.rnSt3Am : landForecast.rnSt3Pm;
      case 4:
        return isAm ? landForecast.rnSt4Am : landForecast.rnSt4Pm;
      case 5:
        return isAm ? landForecast.rnSt5Am : landForecast.rnSt5Pm;
      case 6:
        return isAm ? landForecast.rnSt6Am : landForecast.rnSt6Pm;
      case 7:
        return isAm ? landForecast.rnSt7Am : landForecast.rnSt7Pm;
      default:
        return 0;
    }
  }

  String _getTemperature(MidTaResponse taForecast, String key) {
    // MidTaResponse 클래스의 구조에 따라 이 함수를 구현해야 합니다.
    switch (key) {
      case 'taMin3':
        return taForecast.taMin3.toString();
      case 'taMax3':
        return taForecast.taMax3.toString();
      case 'taMin4':
        return taForecast.taMin4.toString();
      case 'taMax4':
        return taForecast.taMax4.toString();
      case 'taMin5':
        return taForecast.taMin5.toString();
      case 'taMax5':
        return taForecast.taMax5.toString();
      case 'taMin6':
        return taForecast.taMin6.toString();
      case 'taMax6':
        return taForecast.taMax6.toString();
      case 'taMin7':
        return taForecast.taMin7.toString();
      case 'taMax7':
        return taForecast.taMax7.toString();
      // ... 나머지 케이스들
      default:
        return '';
    }
  }

  // // 강수형태
  String parseRainType(String code) {
    switch (code) {
      case '0':
        return '없음';
      case '1':
        return '비';
      case '2':
        return '비/눈';
      case '3':
        return '눈';
      case '4':
        return '소나기';
      case '5':
        return '빗방울';
      case '6':
        return '빗방울/눈날림';
      case '7':
        return '눈날림';
      default:
        return '알 수 없음';
    }
  }

  // 하늘상태
  String parseSkyState(String code) {
    switch (code) {
      case '1': // 0 ~ 5
        return '맑음';
      case '3': // 6 ~ 8
        return '구름많음';
      case '4': // 9~ 10
        return '흐림';
      default:
        return '알 수 없음';
    }
  }

  String combineWeatherCondition(String skyState, String rainType) {
    // 강수형태가 '없음'이 아닐 경우, 강수형태를 우선적으로 표시
    if (rainType != '0') {
      switch (rainType) {
        case '0':
          return '없음';
        case '1':
          return '비';
        case '2':
          return '비/눈';
        case '3':
          return '눈';
        case '4':
          return '소나기';
        case '5':
          return '빗방울';
        case '6':
          return '빗방울/눈날림';
        case '7':
          return '눈날림';
        default:
          return rainType;
      }
    }

    // 강수형태가 '없음'일 경우, 하늘상태를 표시
    switch (skyState) {
      case '1': // 0 ~ 5
        return '맑음';
      case '3': // 6 ~ 8
        return '구름많음';
      case '4': // 9~ 10
        return '흐림';
      default:
        return skyState;
    }
  }

  String getWeatherGogoImage(String skyCode, String ptyCode) {
    int sky = int.tryParse(skyCode) ?? 0;
    int pty = int.tryParse(ptyCode) ?? 0;

    String assetPath = 'assets/lottie/';

    // 강수 형태
    switch (pty) {
      case 1: // 비
      case 2: // 비/눈
        return assetPath + 'day_rain.json';
      case 3: // 눈
        return assetPath + 'day_snow.json';
      case 4: // 소나기
        return assetPath + 'day_rain.json';
    }

    // 하늘 상태
    switch (sky) {
      case 1: // 맑음
        return assetPath + 'sun.json';
      case 3: // 구름많음
        return assetPath + 'day_cloudy.json';
      case 4: // 흐림
        return assetPath + 'day_cloudy.json';
      default: // 기본값 (알 수 없는 상태)
        return assetPath + 'day_cloudy.json';
    }
  }

//초단기예보, 단기예보 모두 수용 가능한 함수
  String getFinalWeatherIcon(String skyCode, String ptyCode) {
    String ptyIcon = getWeatherIcon('PTY', ptyCode);
    if (ptyCode != '0') {
      return ptyIcon; // 강수가 있으면 PTY 아이콘 사용
    } else {
      return getWeatherIcon('SKY', skyCode); // 강수가 없으면 SKY 아이콘 사용
    }
  }

  //초단기예보, 단기예보 모두 수용 가능한 함수
  String getWeatherIcon(String category, String code) {
    int value = int.tryParse(code) ?? 0;
    String assetPath = 'assets/lottie/';

    switch (category) {
      case 'SKY': // 하늘상태 (Sky condition)
        switch (value) {
          case 1:
            return assetPath + 'sun.json'; // 맑음 (Clear)
          case 3:
            return assetPath + 'day_cloudy.json'; // 구름많음 (Mostly Cloudy)
          case 4:
            return assetPath + 'day_cloudy.json'; // 흐림 (Cloudy)
          default:
            return assetPath + 'day_cloudy.json'; // 기본값 (Default)
        }

      case 'PTY': // 강수형태 (Precipitation type)
        switch (value) {
          case 0:
            return assetPath + 'sun.json'; // 없음 (None)
          case 1:
            return assetPath + 'day_rain.json'; // 비 (Rain)
          case 2:
            return assetPath + 'day_snow.json'; // 비/눈 (Rain/Snow)
          case 3:
            return assetPath + 'day_snow.json'; // 눈 (Snow)
          case 4:
            return assetPath + 'day_rain.json'; // 소나기 (Shower)
          case 5:
            return assetPath + 'day_rain.json'; // 빗방울 (Drizzle)
          case 6:
            return assetPath + 'day_snow.json'; // 빗방울눈날림 (Drizzle/Flurry)
          case 7:
            return assetPath + 'day_snow.json'; // 눈날림 (Flurry)
          default:
            return assetPath + 'day_cloudy.json'; // 기본값 (Default)
        }

      default:
        return assetPath + 'day_cloudy.json'; // 알 수 없는 카테고리 (Unknown category)
    }
  }

  // 중기 예보에서만 사용가능한 아이콘 가져오기
  String getWeatherIconForMidtermForecast(String forecastState) {
    // 아이콘 파일들이 저장된 기본 경로
    const String assetPath = 'assets/lottie/';

    // 예보 상태에 따른 아이콘 매핑
    switch (forecastState.toLowerCase()) {
      case '맑음':
        return assetPath + 'sun.json';
      case '구름많음':
        return assetPath + 'day_cloudy.json';
      case '구름많고 비':
      case '구름많고 비/눈':
      case '구름많고 소나기':
        return assetPath + 'day_rain.json';
      case '구름많고 눈':
      case '구름많고 진눈깨비':
        return assetPath + 'day_snow.json';
      case '흐림':
        return assetPath + 'day_cloudy.json';
      case '흐리고 비':
      case '흐리고 비/눈':
      case '흐리고 소나기':
        return assetPath + 'day_rain.json';
      case '흐리고 눈':
      case '흐리고 진눈깨비':
        return assetPath + 'day_snow.json';
      default:
        return assetPath + 'failiure.json';
    }
  }
}
