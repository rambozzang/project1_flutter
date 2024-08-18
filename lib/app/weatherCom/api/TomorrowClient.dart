import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weatherCom/models/weather_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
https://app.tomorrow.io/development/keys
*/
class TomorrowIoWeatherService {
  final String baseUrl = 'https://api.tomorrow.io/v4/timelines';
  final String apiKey = 'ORCeSA0uGGlDWuJn0sww7gCkVrt3ylqX'; // Tomorrow.io에서 받은 API 키를 입력하세요
  final http.Client _httpClient = http.Client();
  List<int> get updateHours => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
  List<int> get updateMinutes => [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  Future<List<WeatherData>> getHourlyForecast(LatLng latLng) async {
    final String cacheKey = 'tomorrow_forecast_hourly_${latLng.latitude}_${latLng.longitude}';
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
      Uri.parse(
          '$baseUrl?apikey=$apiKey&location=${latLng.latitude},${latLng.longitude}&fields=temperature,humidity,precipitationProbability,weatherCode&timesteps=1h&units=metric&timezone=auto'),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );
    lo.g(
        'fetchTomorrowIoWeatherService()  : $baseUrl?apikey=$apiKey&location=${latLng.latitude},${latLng.longitude}&fields=temperature,humidity,precipitationProbability,weatherCode&timesteps=1h&units=metric&timezone=auto');
    lo.g('fetchTomorrowIoWeatherService() response: ${response.body.toString()}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final DateTime now = DateTime.now().toUtc(); // 현
      final List<WeatherData> forecasts = data['data']['timelines'][0]['intervals']
          .where((item) => DateTime.parse(item['startTime']).isAfter(now))
          .take(24)
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
    final String cacheKey = 'tomorrow_forecast_daily_${latLng.latitude}_${latLng.longitude}';
    final String lastCallTimeKey = '${cacheKey}_last_call_time';

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? lastCallTimeStr = prefs.getString(lastCallTimeKey);

    bool shouldFetchNewData = true;

    if (lastCallTimeStr != null) {
      final DateTime lastCallTime = DateTime.parse(lastCallTimeStr);
      shouldFetchNewData = hasUpdateOccurred(lastCallTime, DateTime.now());
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
      Uri.parse(
          '$baseUrl?apikey=$apiKey&location=${latLng.latitude},${latLng.longitude}&fields=temperature,humidity,precipitationProbability,weatherCode&timesteps=1d&units=metric&timezone=auto'),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );

    lo.e('fetchTomorrowIoWeatherService() : ${response.body.toString()}');
    final DateTime now = DateTime.now().toLocal();
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<WeatherData> forecasts = [];

      for (var interval in data['data']['timelines'][0]['intervals']) {
        DateTime date = DateTime.parse(interval['startTime']).toLocal();

        if (date.isAfter(now)) {
          // Create morning (AM) forecast
          forecasts.add(WeatherData(
            time: DateTime(date.year, date.month, date.day, 9), // 9 AM
            temperature: interval['values']['temperature'].toDouble(),
            humidity: interval['values']['humidity'].toDouble(),
            rainProbability: interval['values']['precipitationProbability'].toDouble() / 100,
            source: getWeatherImage(interval['values']['weatherCode']),
          ));

          // Create afternoon (PM) forecast
          forecasts.add(WeatherData(
            time: DateTime(date.year, date.month, date.day, 15), // 3 PM
            temperature: interval['values']['temperature'].toDouble() + 2, // Assuming slightly warmer in the afternoon
            humidity: interval['values']['humidity'].toDouble() - 5, // Assuming slightly less humid in the afternoon
            rainProbability: interval['values']['precipitationProbability'].toDouble() / 100,
            source: getWeatherImage(interval['values']['weatherCode']),
          ));
        }
      }

      // Cache the data
      prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));

      return forecasts;
    } else {
      throw Exception('Failed to load daily forecast');
    }
  }

  WeatherData _parseWeatherData(Map<String, dynamic> item) {
    return WeatherData(
      time: DateTime.parse(item['startTime']).toLocal(),
      temperature: item['values']['temperature'].toDouble(),
      humidity: item['values']['humidity'].toDouble(),
      rainProbability: item['values']['precipitationProbability'].toDouble() / 100,
      source: getWeatherImage(item['values']['weatherCode']),
    );
  }

  String getWeatherImage(int weatherCode) {
    String assetPath = 'assets/lottie/';

    // Tomorrow.io weather codes to weather categories
    switch (weatherCode) {
      case 1000: // Clear, Sunny
      case 1100: // Mostly Clear
        return assetPath + 'sun.json';
      case 1101: // Partly Cloudy
      case 1102: // Mostly Cloudy
      case 1001: // Cloudy
        return assetPath + 'day_cloudy.json';
      case 4000: // Drizzle
      case 4001: // Rain
      case 4200: // Light Rain
      case 4201: // Heavy Rain
        return assetPath + 'day_rain.json';
      case 5000: // Snow
      case 5001: // Flurries
      case 5100: // Light Snow
      case 5101: // Heavy Snow
        return assetPath + 'day_snow.json';
      case 8000: // Thunderstorm
        return assetPath + 'storm.json';
      default:
        return assetPath + 'day_cloudy.json';
    }
  }
}
