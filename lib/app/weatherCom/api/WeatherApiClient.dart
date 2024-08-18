import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weatherCom/models/weather_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
https://www.weatherapi.com/my/
*/
class WeatherApiComService {
  final String baseUrl = 'http://api.weatherapi.com/v1';
  final String apiKey = 'efda3e577c804f21bf8143012230810'; // WeatherAPI.com에서 받은 API 키를 입력하세요
  final http.Client _httpClient = http.Client();

  List<int> get updateHours => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
  List<int> get updateMinutes => [0, 15, 30, 45];

  Future<List<WeatherData>> getHourlyForecast(LatLng latLng) async {
    final String cacheKey = 'wapi_forecast_hourly_${latLng.latitude}_${latLng.longitude}';
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

    // Get current date and time
    String todayDate = DateFormat('yyyy-MM-dd').format(now);
    String tomorrowDate = DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 1)));

    // Prepare API request URLs for current day and next day
    String urlToday = '$baseUrl/forecast.json?key=$apiKey&q=${latLng.latitude},${latLng.longitude}&dt=$todayDate&days=1&aqi=no&alerts=no';
    String urlTomorrow =
        '$baseUrl/forecast.json?key=$apiKey&q=${latLng.latitude},${latLng.longitude}&dt=$tomorrowDate&days=1&aqi=no&alerts=no';

    // Fetch data for today
    final responseToday = await _httpClient.get(
      Uri.parse(urlToday),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );
    lo.g('fetchWeatherApiComService() today: $urlToday');

    if (responseToday.statusCode != 200) {
      throw Exception('Failed to load hourly forecast for today');
    }

    // Fetch data for tomorrow
    final responseTomorrow = await _httpClient.get(
      Uri.parse(urlTomorrow),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );
    lo.g('fetchWeatherApiComService() tomorrow: $urlTomorrow');

    if (responseTomorrow.statusCode != 200) {
      throw Exception('Failed to load hourly forecast for tomorrow');
    }

    final Map<String, dynamic> dataToday = json.decode(responseToday.body);
    final Map<String, dynamic> dataTomorrow = json.decode(responseTomorrow.body);

    List<WeatherData> forecasts = _parseHourlyWeatherData(dataToday, dataTomorrow, now);

    // Cache the data
    prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));

    return forecasts;
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

  List<WeatherData> _filterAndLimitForecast(List<WeatherData> forecasts) {
    final DateTime now = DateTime.now();
    return forecasts.where((forecast) => forecast.time.isAfter(now)).take(24).toList();
  }

  Future<List<WeatherData>> getDailyForecast(LatLng latLng) async {
    final String cacheKey = 'wapi_forecast_daily_${latLng.latitude}_${latLng.longitude}';
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
      Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=${latLng.latitude},${latLng.longitude}&days=7&aqi=no&alerts=no'),
      headers: {'User-Agent': 'YourAppName/1.0'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<WeatherData> forecasts = [];

      for (var day in data['forecast']['forecastday']) {
        final DateTime forecastDate = DateTime.parse(day['date']);
        if (forecastDate.isAfter(now)) {
          forecasts.add(_parseDailyWeatherData(day, true)); // Morning forecast
          forecasts.add(_parseDailyWeatherData(day, false)); // Afternoon forecast
        }
      }

      // Cache the data
      prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));

      return forecasts;
    } else {
      throw Exception('Failed to load daily forecast');
    }
  }

  WeatherData _parseDailyWeatherData(Map<String, dynamic> day, bool isMorning) {
    final hour = isMorning ? day['hour'][6] : day['hour'][14]; // 6 AM or 2 PM
    return WeatherData(
      time: DateTime.parse(hour['time']).toLocal(),
      temperature: double.parse(hour['temp_c'].toString()),
      humidity: double.parse(hour['humidity'].toString()),
      rainProbability: double.parse(hour['chance_of_rain'].toString()) / 100, // Convert percentage to decimal
      source: getWeatherImage(hour['condition']['code']),
    );
  }

  List<WeatherData> _parseHourlyWeatherData(Map<String, dynamic> dataToday, Map<String, dynamic> dataTomorrow, DateTime now) {
    List<WeatherData> hourlyForecasts = [];

    // Process today's data
    for (var hour in dataToday['forecast']['forecastday'][0]['hour']) {
      DateTime forecastTime = DateTime.parse(hour['time']).toLocal();
      if (forecastTime.isAfter(now) || forecastTime.isAtSameMomentAs(now)) {
        hourlyForecasts.add(_createWeatherData(hour));
      }
    }

    // Process tomorrow's data
    for (var hour in dataTomorrow['forecast']['forecastday'][0]['hour']) {
      DateTime forecastTime = DateTime.parse(hour['time']).toLocal();
      hourlyForecasts.add(_createWeatherData(hour));
      if (hourlyForecasts.length == 24) break; // Stop when we have 24 hours of data
    }

    return hourlyForecasts;
  }

  WeatherData _createWeatherData(Map<String, dynamic> hour) {
    return WeatherData(
      time: DateTime.parse(hour['time']).toLocal(),
      temperature: double.parse(hour['temp_c'].toString()),
      humidity: hour['humidity'].toDouble(),
      rainProbability: hour['chance_of_rain'].toDouble() / 100,
      source: getWeatherImage(hour['condition']['code']),
    );
  }

  String getWeatherImage(int conditionCode) {
    String assetPath = 'assets/lottie/';

    // WeatherAPI.com condition codes to weather categories
    switch (conditionCode) {
      case 1000: // Clear
        return assetPath + 'sun.json';
      case 1003: // Partly cloudy
      case 1006: // Cloudy
      case 1009: // Overcast
        return assetPath + 'day_cloudy.json';
      case 1063: // Patchy rain possible
      case 1180: // Patchy light rain
      case 1183: // Light rain
      case 1186: // Moderate rain at times
      case 1189: // Moderate rain
      case 1192: // Heavy rain at times
      case 1195: // Heavy rain
        return assetPath + 'day_rain.json';
      case 1066: // Patchy snow possible
      case 1210: // Light snow
      case 1213: // Light snow
      case 1216: // Patchy moderate snow
      case 1219: // Moderate snow
      case 1222: // Patchy heavy snow
      case 1225: // Heavy snow
        return assetPath + 'day_snow.json';
      case 1087: // Thundery outbreaks possible
      case 1273: // Patchy light rain with thunder
      case 1276: // Moderate or heavy rain with thunder
        return assetPath + 'storm.json';
      default:
        return assetPath + 'day_cloudy.json';
    }
  }
}
