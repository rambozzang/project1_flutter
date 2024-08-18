import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weatherCom/services/weather_api_client.dart';
import 'package:project1/utils/log_utils.dart';
import '../models/weather_data.dart';
// import 'weather_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherNewsService {
  final String baseUrl = 'https://api.weathernews.jp/v1';
  final String apiKey = 'YOUR_API_KEY'; // 웨더뉴스에서 받은 API 키를 입력하세요
  final http.Client _httpClient = http.Client();
  static const int CACHE_DURATION_MINUTES = 30;

  Future<List<WeatherData>> getHourlyForecast(LatLng latLng) async {
    final String cacheKey = 'weathernews_hourly_${latLng.latitude}_${latLng.longitude}';
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check cache
    final String? cachedData = prefs.getString(cacheKey);
    final String? cachedTime = prefs.getString('${cacheKey}_time');

    if (cachedData != null && cachedTime != null) {
      final DateTime cacheDateTime = DateTime.parse(cachedTime);
      if (DateTime.now().difference(cacheDateTime).inMinutes < CACHE_DURATION_MINUTES) {
        lo.g('Using cached WeatherNews hourly data');
        final List<dynamic> decodedData = json.decode(cachedData);
        return decodedData.map((item) => WeatherData.fromJson(item)).toList();
      }
    }

    // Fetch new data
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/forecast?lat=${latLng.latitude}&lon=${latLng.longitude}&apikey=$apiKey'),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );
    lo.g('fetchWeatherNewsService hourly: $baseUrl/forecast?lat=${latLng.latitude}&lon=${latLng.longitude}&apikey=$apiKey');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<WeatherData> forecasts = _parseHourlyData(data);

      // Cache the data
      prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));
      prefs.setString('${cacheKey}_time', DateTime.now().toIso8601String());

      return forecasts;
    } else {
      throw Exception('Failed to load hourly forecast from WeatherNews');
    }
  }

  Future<List<WeatherData>> getDailyForecast(LatLng latLng) async {
    final String cacheKey = 'weathernews_daily_${latLng.latitude}_${latLng.longitude}';
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check cache
    final String? cachedData = prefs.getString(cacheKey);
    final String? cachedTime = prefs.getString('${cacheKey}_time');

    if (cachedData != null && cachedTime != null) {
      final DateTime cacheDateTime = DateTime.parse(cachedTime);
      if (DateTime.now().difference(cacheDateTime).inMinutes < CACHE_DURATION_MINUTES) {
        lo.g('Using cached WeatherNews daily data');
        final List<dynamic> decodedData = json.decode(cachedData);
        return decodedData.map((item) => WeatherData.fromJson(item)).toList();
      }
    }

    // Fetch new data
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/forecast?lat=${latLng.latitude}&lon=${latLng.longitude}&apikey=$apiKey'),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<WeatherData> forecasts = _parseDailyData(data);

      // Cache the data
      prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));
      prefs.setString('${cacheKey}_time', DateTime.now().toIso8601String());

      return forecasts;
    } else {
      throw Exception('Failed to load daily forecast from WeatherNews');
    }
  }

  List<WeatherData> _parseHourlyData(Map<String, dynamic> data) {
    List<WeatherData> hourlyData = [];
    for (var item in data['hourly']) {
      hourlyData.add(WeatherData(
        time: DateTime.parse(item['time']),
        temperature: item['temperature'].toDouble(),
        humidity: item['humidity'].toDouble(),
        rainProbability: item['precipitation_probability'].toDouble(),
        source: _getWeatherImage(item['weather_code']),
      ));
    }
    return hourlyData.take(24).toList();
  }

  List<WeatherData> _parseDailyData(Map<String, dynamic> data) {
    List<WeatherData> dailyData = [];
    for (var item in data['daily']) {
      // Morning forecast
      dailyData.add(WeatherData(
        time: DateTime.parse(item['time']),
        temperature: item['temperature_morning'].toDouble(),
        humidity: item['humidity_morning'].toDouble(),
        rainProbability: item['precipitation_probability_morning'].toDouble(),
        source: _getWeatherImage(item['weather_code_morning']),
      ));
      // Afternoon forecast
      dailyData.add(WeatherData(
        time: DateTime.parse(item['time']).add(Duration(hours: 12)),
        temperature: item['temperature_afternoon'].toDouble(),
        humidity: item['humidity_afternoon'].toDouble(),
        rainProbability: item['precipitation_probability_afternoon'].toDouble(),
        source: _getWeatherImage(item['weather_code_afternoon']),
      ));
    }
    return dailyData.take(14).toList(); // 7 days * 2 (morning and afternoon)
  }

  String _getWeatherImage(int weatherCode) {
    String assetPath = 'assets/lottie/';

    // WeatherNews weather codes to weather categories
    switch (weatherCode) {
      case 100: // Clear
      case 200: // Fair
        return assetPath + 'sun.json';
      case 300: // Cloudy
      case 400: // Mostly Cloudy
        return assetPath + 'day_cloudy.json';
      case 500: // Rain
      case 600: // Heavy Rain
        return assetPath + 'day_rain.json';
      case 700: // Snow
      case 800: // Heavy Snow
        return assetPath + 'day_snow.json';
      case 900: // Thunder
        return assetPath + 'storm.json';
      default:
        return assetPath + 'day_cloudy.json';
    }
  }
}
