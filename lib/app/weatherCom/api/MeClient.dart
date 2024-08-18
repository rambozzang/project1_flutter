import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weatherCom/models/weather_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetNorwayWeatherService {
  final String baseUrl = 'https://api.met.no/weatherapi/locationforecast/2.0/compact';
  final http.Client _httpClient = http.Client();

  List<int> get updateHours => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
  List<int> get updateMinutes => [0];

  Future<List<WeatherData>> getHourlyForecast(LatLng latLng) async {
    final String cacheKey = 'met_forecast_hourly_${latLng.latitude}_${latLng.longitude}';
    final String lastCallTimeKey = '${cacheKey}_last_call_time';
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? lastCallTimeStr = prefs.getString(lastCallTimeKey);
    final DateTime now = DateTime.now();

    bool shouldFetchNewData = true;

    if (lastCallTimeStr != null) {
      final DateTime lastCallTime = DateTime.parse(lastCallTimeStr);
      shouldFetchNewData = hasUpdateOccurred(lastCallTime, now);
    }

    if (!shouldFetchNewData) {
      final String? cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        lo.g('Using cached weather data');
        final List<dynamic> decodedData = json.decode(cachedData);
        return decodedData.map((item) => WeatherData.fromJson(item)).toList();
      }
    }

    // Fetch new data
    final response = await _httpClient.get(
      Uri.parse('$baseUrl?lat=${latLng.latitude}&lon=${latLng.longitude}'),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final DateTime now = DateTime.now().toUtc(); // 현
      final List<WeatherData> forecasts = data['properties']['timeseries']
          .where((item) => DateTime.parse(item['time']).isAfter(now)) // 현재 시간 이후의 데이터만 필터링
          .take(24) // 24시간 분량의 데이터만 선택
          .map<WeatherData>((item) => _parseWeatherData(item))
          .toList();

      // Cache the data
      prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));

      return forecasts;
    } else {
      throw Exception('Failed to load hourly forecast');
    }
  }

  bool hasUpdateOccurred(DateTime lastCallTime, DateTime now) {
    for (int hour in updateHours) {
      for (int minute in updateMinutes) {
        DateTime updateTime = DateTime(now.year, now.month, now.day, hour, minute);
        if (updateTime.isAfter(lastCallTime) && updateTime.isBefore(now)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<List<WeatherData>> getDailyForecast(LatLng latLng) async {
    final String cacheKey = 'met_forecast_daily_${latLng.latitude}_${latLng.longitude}';
    final String lastCallTimeKey = '${cacheKey}_last_call_time';
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime now = DateTime.now();

    final String? lastCallTimeStr = prefs.getString(lastCallTimeKey);

    bool shouldFetchNewData = true;

    if (lastCallTimeStr != null) {
      final DateTime lastCallTime = DateTime.parse(lastCallTimeStr);
      shouldFetchNewData = hasUpdateOccurred(lastCallTime, now);
    }

    // Check cache
    if (!shouldFetchNewData) {
      final String? cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        lo.g('Using cached weather data');
        final List<dynamic> decodedData = json.decode(cachedData);
        return decodedData.map((item) => WeatherData.fromJson(item)).toList();
      }
    }

    // Fetch new data
    final response = await _httpClient.get(
      Uri.parse('$baseUrl?lat=${latLng.latitude}&lon=${latLng.longitude}'),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<WeatherData> forecasts = [];

      DateTime currentDate = DateTime.now();
      DateTime forecastDate = currentDate.add(Duration(days: 1));
      int daysAdded = 0;

      for (var item in data['properties']['timeseries']) {
        final DateTime forecastTime = DateTime.parse(item['time']).toLocal();

        if (forecastTime.day == forecastDate.day) {
          if (forecastTime.hour == 6 || (forecasts.length % 2 == 0 && forecastTime.hour > 6)) {
            // Morning forecast (closest to 6 AM)
            forecasts.add(_parseWeatherData(item));
          } else if (forecastTime.hour == 14 || (forecasts.length % 2 == 1 && forecastTime.hour > 14)) {
            // Afternoon forecast (closest to 2 PM)
            forecasts.add(_parseWeatherData(item));
            daysAdded++;
            forecastDate = currentDate.add(Duration(days: daysAdded + 1));
          }
        }

        if (daysAdded >= 7) break; // 7 days of forecast
      }

      lo.g('Daily Forecast count: ${forecasts.length}');

      // Cache the data
      prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));

      return forecasts;
    } else {
      throw Exception('Failed to load daily forecast');
    }
  }

  String getWeatherImage(String symbolCode) {
    String assetPath = 'assets/lottie/';

    // MET Norway symbol codes to weather categories
    switch (symbolCode) {
      case 'clearsky_day':
      case 'clearsky_night':
      case 'fair_day':
      case 'fair_night':
        return assetPath + 'sun.json';

      case 'cloudy':
      case 'partlycloudy_day':
      case 'partlycloudy_night':
        return assetPath + 'day_cloudy.json';

      case 'rainshowers_day':
      case 'rainshowers_night':
      case 'rain':
      case 'heavyrain':
      case 'heavyrainshowers_day':
      case 'heavyrainshowers_night':
        return assetPath + 'day_rain.json';

      case 'snow':
      case 'snowshowers_day':
      case 'snowshowers_night':
      case 'heavysnow':
      case 'heavysnowshowers_day':
      case 'heavysnowshowers_night':
        return assetPath + 'day_snow.json';

      case 'thunderstorm':
      case 'lightthreatening_thunder':
      case 'heavythreatening_thunder':
        return assetPath + 'storm.json';

      case 'fog':
        return assetPath + 'day_cloudy.json';

      case 'sleet':
      case 'sleetshowers_day':
      case 'sleetshowers_night':
        return assetPath + 'day_rain.json'; // 우비와 눈이 섞인 날씨, 비 아이콘으로 대체

      default:
        return assetPath + 'day_cloudy.json';
    }
  }

  WeatherData _parseWeatherData(Map<String, dynamic> item) {
    String symbolCode = item['data']['next_1_hours']?['summary']?['symbol_code'] ??
        item['data']['next_6_hours']?['summary']?['symbol_code'] ??
        'cloudy'; // 기본값 설정

    double precipitationAmount = item['data']['next_1_hours']?['details']?['precipitation_amount']?.toDouble() ??
        item['data']['next_6_hours']?['details']?['precipitation_amount']?.toDouble() ??
        0.0;

    // 강수량을 확률로 변환 (추정치)
    double estimatedProbability = _estimatePrecipitationProbability(precipitationAmount);

    return WeatherData(
      time: DateTime.parse(item['time']).toLocal(),
      temperature: item['data']['instant']['details']['air_temperature'].toDouble(),
      humidity: item['data']['instant']['details']['relative_humidity'].toDouble(),
      rainProbability: estimatedProbability, // 추정된 확률 사용
      source: getWeatherImage(symbolCode),
    );
  }

  double _estimatePrecipitationProbability(double precipitationAmount) {
    // 간단한 확률 추정 로직
    // 0.1mm 이상: 20% 확률
    // 0.5mm 이상: 40% 확률
    // 1mm 이상: 60% 확률
    // 2mm 이상: 80% 확률
    // 5mm 이상: 100% 확률
    if (precipitationAmount >= 5.0) return 1.0;
    if (precipitationAmount >= 2.0) return 0.8;
    if (precipitationAmount >= 1.0) return 0.6;
    if (precipitationAmount >= 0.5) return 0.4;
    if (precipitationAmount >= 0.1) return 0.2;
    return 0.0;
  }
}
