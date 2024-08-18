import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:project1/app/weatherCom/models/weather_data.dart';
import 'package:project1/utils/log_utils.dart';

/*
개인 기상관측소를 사야한다.
*/

class WeatherChannelService {
  final String baseUrl = 'https://api.weather.com/v3/wx/forecast/hourly/15day';
  final String apiKey = 'YOUR_API_KEY'; // 웨더채널에서 받은 API 키를 입력하세요
  final http.Client _httpClient = http.Client();
  static const int CACHE_DURATION_MINUTES = 30;

  Future<List<WeatherData>> getHourlyForecast(LatLng latLng) async {
    final String cacheKey = 'weatherchannel_hourly_${latLng.latitude}_${latLng.longitude}';
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check cache
    final String? cachedData = prefs.getString(cacheKey);
    final String? cachedTime = prefs.getString('${cacheKey}_time');

    if (cachedData != null && cachedTime != null) {
      final DateTime cacheDateTime = DateTime.parse(cachedTime);
      if (DateTime.now().difference(cacheDateTime).inMinutes < CACHE_DURATION_MINUTES) {
        lo.g('Using cached Weather Channel hourly data');
        final List<dynamic> decodedData = json.decode(cachedData);
        return decodedData.map((item) => WeatherData.fromJson(item)).toList();
      }
    }

    // Fetch new data
    final response = await _httpClient.get(
      Uri.parse('$baseUrl?apiKey=$apiKey&format=json&units=m&language=en-US&latitude=${latLng.latitude}&longitude=${latLng.longitude}'),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );
    lo.g(
        'fetchWeatherChannelService hourly: $baseUrl?apiKey=$apiKey&format=json&units=m&language=en-US&latitude=${latLng.latitude}&longitude=${latLng.longitude}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<WeatherData> forecasts = _parseHourlyData(data);

      // Cache the data
      prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));
      prefs.setString('${cacheKey}_time', DateTime.now().toIso8601String());

      return forecasts;
    } else {
      throw Exception('Failed to load hourly forecast from Weather Channel');
    }
  }

  Future<List<WeatherData>> getDailyForecast(LatLng latLng) async {
    final String cacheKey = 'weatherchannel_daily_${latLng.latitude}_${latLng.longitude}';
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check cache
    final String? cachedData = prefs.getString(cacheKey);
    final String? cachedTime = prefs.getString('${cacheKey}_time');

    if (cachedData != null && cachedTime != null) {
      final DateTime cacheDateTime = DateTime.parse(cachedTime);
      if (DateTime.now().difference(cacheDateTime).inMinutes < CACHE_DURATION_MINUTES) {
        lo.g('Using cached Weather Channel daily data');
        final List<dynamic> decodedData = json.decode(cachedData);
        return decodedData.map((item) => WeatherData.fromJson(item)).toList();
      }
    }

    // Fetch new data
    final response = await _httpClient.get(
      Uri.parse('$baseUrl?apiKey=$apiKey&format=json&units=m&language=ko-Kr&latitude=${latLng.latitude}&longitude=${latLng.longitude}'),
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
      throw Exception('Failed to load daily forecast from Weather Channel');
    }
  }

  List<WeatherData> _parseHourlyData(Map<String, dynamic> data) {
    List<WeatherData> hourlyData = [];
    for (int i = 0; i < 24; i++) {
      hourlyData.add(WeatherData(
        time: DateTime.fromMillisecondsSinceEpoch(data['validTimeUtc'][i] * 1000),
        temperature: data['temperature'][i].toDouble(),
        humidity: data['relativeHumidity'][i].toDouble(),
        rainProbability: data['precipChance'][i].toDouble() / 100,
        source: _getWeatherImage(data['iconCode'][i]),
      ));
    }
    return hourlyData;
  }

  List<WeatherData> _parseDailyData(Map<String, dynamic> data) {
    List<WeatherData> dailyData = [];
    for (int i = 0; i < 7; i++) {
      // Morning forecast (6 AM)
      int morningIndex = i * 24 + 6;
      dailyData.add(WeatherData(
        time: DateTime.fromMillisecondsSinceEpoch(data['validTimeUtc'][morningIndex] * 1000),
        temperature: data['temperature'][morningIndex].toDouble(),
        humidity: data['relativeHumidity'][morningIndex].toDouble(),
        rainProbability: data['precipChance'][morningIndex].toDouble() / 100,
        source: _getWeatherImage(data['iconCode'][morningIndex]),
      ));

      // Afternoon forecast (2 PM)
      int afternoonIndex = i * 24 + 14;
      dailyData.add(WeatherData(
        time: DateTime.fromMillisecondsSinceEpoch(data['validTimeUtc'][afternoonIndex] * 1000),
        temperature: data['temperature'][afternoonIndex].toDouble(),
        humidity: data['relativeHumidity'][afternoonIndex].toDouble(),
        rainProbability: data['precipChance'][afternoonIndex].toDouble() / 100,
        source: _getWeatherImage(data['iconCode'][afternoonIndex]),
      ));
    }
    return dailyData;
  }

  String _getWeatherImage(int iconCode) {
    String assetPath = 'assets/lottie/';

    // Weather Channel icon codes to weather categories
    switch (iconCode) {
      case 1: // Sunny
      case 2: // Mostly Sunny
      case 3: // Partly Sunny
        return assetPath + 'sun.json';
      case 4: // Intermittent Clouds
      case 5: // Hazy Sunshine
      case 6: // Mostly Cloudy
      case 7: // Cloudy
      case 8: // Dreary (Overcast)
        return assetPath + 'day_cloudy.json';
      case 11: // Light Rain
      case 12: // Rain
      case 13: // Flurries
      case 14: // Light Snow
      case 18: // Rain and Snow
        return assetPath + 'day_rain.json';
      case 15: // Snow
      case 16: // Heavy Snow
      case 17: // Sleet
        return assetPath + 'day_snow.json';
      case 19: // Hot
      case 20: // Cold
      case 21: // Windy
        return assetPath + 'wind.json';
      case 22: // T-Storms
      case 23: // Thunderstorms
        return assetPath + 'storm.json';
      default:
        return assetPath + 'day_cloudy.json';
    }
  }

  Color getColorForSource(String source) {
    return Colors.blue; // Weather Channel의 대표 색상
  }
}
