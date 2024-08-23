import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Openweathermapclient {
  Future<ResData> getForecast(LatLng latLng) async {
    try {
      final String cacheKey = 'openweather_forecast_hourly_${latLng.latitude}_${latLng.longitude}';
      final String lastCallTimeKey = '${cacheKey}_last_call_time';
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? lastCallTimeStr = prefs.getString(lastCallTimeKey);
      final DateTime now = DateTime.now();

      if (lastCallTimeStr != null) {
        final DateTime lastCallTime = DateTime.parse(lastCallTimeStr);
        if (shouldUseCache(lastCallTime, now)) {
          final String? cachedData = prefs.getString(cacheKey);
          if (cachedData != null) {
            lo.g('[OpenWeatherMap] Attempting to use cached data');
            try {
              return processWeatherData(cachedData, true);
            } catch (e) {
              lo.e('[OpenWeatherMap] Error processing cached data: $e');
              lo.g('[OpenWeatherMap] Falling back to fetching new data');
            }
          }
        }
      }

      lo.g('[OpenWeatherMap] Fetching new data');
      OpenWheatherRepo repo = OpenWheatherRepo();
      ResData resData = await repo.getOneCallWeather(latLng);
      if (resData.code != '00') {
        throw Exception(resData.msg.toString());
      }

      dynamic newData = resData.data;
      lo.g('[API] New data type: ${newData.runtimeType}');
      lo.g('[API] New data content: $newData');

      // Process and cache the new data
      ResData processedData = processWeatherData(newData, false);

      // Cache the processed data
      await prefs.setString(cacheKey, json.encode(processedData.data));
      await prefs.setString(lastCallTimeKey, now.toIso8601String());

      return processedData;
    } catch (e) {
      lo.e('[OpenWeatherMap] API Error: $e');
      throw Exception('[OpenWeatherMap] API Error: $e');
    }
  }

  ResData processWeatherData(dynamic data, bool isCached) {
    try {
      lo.g('[OpenWeatherMap] Processing ${isCached ? "cached" : "new"} data');
      lo.g('[OpenWeatherMap] Data type: ${data.runtimeType}');

      Map<String, dynamic> formattedData;
      if (data is String) {
        lo.g('[OpenWeatherMap] Parsing JSON string');
        formattedData = json.decode(data);
      } else if (data is Map<String, dynamic>) {
        lo.g('[OpenWeatherMap] Using Map directly');
        formattedData = data;
      } else {
        throw FormatException('Unexpected data format: ${data.runtimeType}');
      }

      // Validate the data structure
      if (!formattedData.containsKey('lat') || !formattedData.containsKey('lon')) {
        throw FormatException('Invalid data structure: missing required fields');
      }

      lo.g('[OpenWeatherMap] Formatted data: $formattedData');
      return ResData(code: '00', data: formattedData);
    } catch (e) {
      lo.e('[OpenWeatherMap] Data processing error: $e');
      lo.e('[OpenWeatherMap] Problematic data: $data');
      throw Exception('[OpenWeatherMap] Data processing error: $e');
    }
  }

  bool shouldUseCache(DateTime lastCallTime, DateTime now) {
    // 같은 시간대인지 확인
    if (lastCallTime.hour == now.hour) {
      // 5분 이내라면 캐시 사용
      return now.difference(lastCallTime).inMinutes < 5;
    }
    // 다른 시간대라면 캐시 사용하지 않음
    return false;
  }
}
