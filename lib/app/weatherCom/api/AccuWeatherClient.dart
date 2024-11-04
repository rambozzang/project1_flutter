import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:project1/utils/WeatherLottie.dart';
import 'package:project1/utils/log_utils.dart';
import '../models/weather_data.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AccuWeatherClient {
  final String apiKey = '9Dpql374txlRZGgiECCDS2gGcvuqdmeT';
  static const String _cacheKeyPrefix = 'accuweather_forecast_cache_';
  static const String _lastFetchTimeKeyPrefix = 'accuweather_last_fetch_time_';

  AccuWeatherClient();

  String _getCacheKey(String locationKey) => '$_cacheKeyPrefix$locationKey';
  String _getLastFetchTimeKey(String locationKey) => '$_lastFetchTimeKeyPrefix$locationKey';

  Future<List<WeatherData>> getForecast(LatLng latLng) async {
    final locationKey = await getLocationKey(latLng.latitude, latLng.longitude);

    if (await _shouldFetchNewData(locationKey)) {
      return await _fetchAndCacheData(locationKey);
    } else {
      return await _loadCachedData(locationKey);
    }
  }

  Future<bool> _shouldFetchNewData(String locationKey) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTimeString = prefs.getString(_getLastFetchTimeKey(locationKey));
    final cachedDataString = prefs.getString(_getCacheKey(locationKey));

    if (lastFetchTimeString == null || cachedDataString == null) {
      return true;
    }

    final lastFetchTime = DateTime.parse(lastFetchTimeString);
    return DateTime.now().difference(lastFetchTime).inMinutes >= 55;
  }

  Future<List<WeatherData>> _fetchAndCacheData(String locationKey) async {
    final url = 'http://dataservice.accuweather.com/forecasts/v1/hourly/12hour/$locationKey?apikey=$apiKey&metric=true&language=ko-kr';
    final response = await http.get(Uri.parse(url));
    lo.g('response: ${response.toString()}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final DateTime now = DateTime.now().toLocal(); // 현

      lo.g('data: $data');
      final List<WeatherData> forecast = data
          .where((item) => DateTime.parse(item['DateTime']).isAfter(now))
          .map((item) => WeatherData(
                time: DateTime.parse(item['DateTime']).toLocal(),
                temperature: double.parse(item['Temperature']['Value'].toString()),
                humidity: 0.0,
                rainProbability: double.parse(item['PrecipitationProbability'].toString()) / 100,
                source: mapAccuWeatherIconToWeatherCategory(item['WeatherIcon']),
              ))
          .toList();

      await _saveCachedData(locationKey, forecast);
      return forecast;
    } else {
      throw Exception('Failed to load forecast from AccuWeather');
    }
  }

  Future<void> _saveCachedData(String locationKey, List<WeatherData> forecast) async {
    final prefs = await SharedPreferences.getInstance();
    final forecastJson = forecast.map((w) => w.toJson()).toList();
    await prefs.setString(_getCacheKey(locationKey), json.encode(forecastJson));
    await prefs.setString(_getLastFetchTimeKey(locationKey), DateTime.now().toIso8601String());
  }

  Future<List<WeatherData>> _loadCachedData(String locationKey) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDataString = prefs.getString(_getCacheKey(locationKey));
    if (cachedDataString != null) {
      final List<dynamic> cachedData = json.decode(cachedDataString);
      return cachedData.map((item) => WeatherData.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<WeatherData>> getFiveDayForecast(LatLng latLng) async {
    final locationKey = await getLocationKey(latLng.latitude, latLng.longitude);

    if (await _shouldFetchNewDailyData(locationKey)) {
      return await _fetchAndCacheDailyData(locationKey);
    } else {
      return await _loadCachedDailyData(locationKey);
    }
  }

  Future<bool> _shouldFetchNewDailyData(String locationKey) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTimeString = prefs.getString(_getDailyLastFetchTimeKey(locationKey));
    final cachedDataString = prefs.getString(_getDailyCacheKey(locationKey));

    if (lastFetchTimeString == null || cachedDataString == null) {
      return true;
    }

    final lastFetchTime = DateTime.parse(lastFetchTimeString);
    return DateTime.now().difference(lastFetchTime).inHours >= 6; // 6시간마다 갱신
  }

  Future<List<WeatherData>> _fetchAndCacheDailyData(String locationKey) async {
    final url = 'http://dataservice.accuweather.com/forecasts/v1/daily/5day/$locationKey?apikey=$apiKey&metric=true&language=ko-kr';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      lo.g('data: $data');
      final List<dynamic> dailyForecasts = data['DailyForecasts'];
      List<WeatherData> forecasts = [];

      dailyForecasts.forEach((item) {
        // 오전
        forecasts.add(WeatherData(
          time: DateTime.parse(item['Date']).toLocal(),
          temperature: item['Temperature']['Minimum']['Value'].toDouble(),
          humidity: 999.0,
          rainProbability: 999.0,
          source: mapAccuWeatherIconToWeatherCategory(item['Day']['Icon']),
        ));
        // 오후
        forecasts.add(WeatherData(
          time: DateTime.parse(item['Date']).toLocal(),
          temperature: item['Temperature']['Maximum']['Value'].toDouble(),
          humidity: 999.0,
          rainProbability: 999.0,
          source: mapAccuWeatherIconToWeatherCategory(item['nightIcon']['Icon']),
        ));
      });

      await _saveCachedDailyData(locationKey, forecasts);
      return forecasts;
    } else {
      throw Exception('Failed to load 5-day forecast from AccuWeather');
    }
  }

  Future<void> _saveCachedDailyData(String locationKey, List<WeatherData> forecasts) async {
    final prefs = await SharedPreferences.getInstance();
    final forecastJson = forecasts.map((f) => f.toJson()).toList();
    await prefs.setString(_getDailyCacheKey(locationKey), json.encode(forecastJson));
    await prefs.setString(_getDailyLastFetchTimeKey(locationKey), DateTime.now().toIso8601String());
  }

  Future<List<WeatherData>> _loadCachedDailyData(String locationKey) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDataString = prefs.getString(_getDailyCacheKey(locationKey));
    if (cachedDataString != null) {
      final List<dynamic> cachedData = json.decode(cachedDataString);
      return cachedData.map((item) => WeatherData.fromJson(item)).toList();
    }
    return [];
  }

  String _getDailyCacheKey(String locationKey) => 'accuweather_daily_forecast_cache_$locationKey';
  String _getDailyLastFetchTimeKey(String locationKey) => 'accuweather_daily_last_fetch_time_$locationKey';

  Future<String> getLocationKey(double lat, double lon) async {
    final url = 'http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=$apiKey&q=$lat,$lon';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['Key'];
    } else {
      // Utils.alert(response.body.toString());
      lo.g('getLocationKey: ${response.body}');
      throw Exception('Failed to get location key from AccuWeather');
    }
  }

  String mapAccuWeatherIconToWeatherCategory(int iconCode) {
    String assetPath = 'assets/lottie/';

    bool isDayTime = DateTime.now().hour >= 6 && DateTime.now().hour < 18;

    switch (iconCode) {
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 30:
      case 31:
      case 32:
        return '${assetPath}sun.json';
      case 6:
      case 7:
      case 8:
      case 11:
      case 20:
      case 21:
      case 22:
      case 23:
      case 24:
      case 25:
      case 26:
      case 29:
        return '${assetPath}day_cloudy.json';
      case 12:
      case 13:
      case 14:
      case 18:
        return '${assetPath}day_rain.json';

      case 15:
      case 16:
      case 17:
        return '${assetPath}storm.json';
      case 19:
        return '${assetPath}day_snow.json';
      case 9:
      case 10:
        return '${assetPath}day_cloudy.json';
      case 33:
      case 34:
      case 35:
      case 36:
      case 37:
      case 38:
        return '${assetPath}wind.json'; //squall
      default:
        return '${assetPath}day_cloudy.json'; // 기본값
    }
  }
}
