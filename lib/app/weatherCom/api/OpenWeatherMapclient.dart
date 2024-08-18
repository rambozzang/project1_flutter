// import 'dart:convert';

// import 'package:latlong2/latlong.dart';
// import 'package:project1/repo/common/res_data.dart';
// import 'package:project1/utils/log_utils.dart';
// import 'package:project1/utils/utils.dart';

// import 'package:shared_preferences/shared_preferences.dart';


// class Openweathermapclient {
//   List<int> get updateHours => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
//   List<int> get updateMinutes => [0];


//   Future<Map<String, dynamic>> getForecast(LatLng latLng) async {
//     final String cacheKey = 'openweather_forecast_hourly_${latLng.latitude}_${latLng.longitude}';
//     final String lastCallTimeKey = '${cacheKey}_last_call_time';
//     final SharedPreferences prefs = await SharedPreferences.getInstance();

//     final String? lastCallTimeStr = prefs.getString(lastCallTimeKey);
//     final DateTime now = DateTime.now();

//     bool shouldFetchNewData = true;

//     if (lastCallTimeStr != null) {
//       final DateTime lastCallTime = DateTime.parse(lastCallTimeStr);
//       shouldFetchNewData = hasUpdateOccurred(lastCallTime, now);
//     }

//     if (!shouldFetchNewData) {
//       final String? cachedData = prefs.getString(cacheKey);
//       if (cachedData != null) {
//         lo.g('Using cached weather data');
//         final List<dynamic> decodedData = json.decode(cachedData);
//         // return decodedData.map((item) => WeatherData.fromJson(item)).toList();
//         return decodedData.map((item) => WeatherData.fromJson(item)).toList();
//       }
//     }
//        ResData resData = await repo.getOneCallWeather(location);
//       if (resData.code != '00') {
//         Utils.alert(resData.msg.toString());
//         Exception('Failed to load daily forecast');
//       }
//       final dailyData = resData.data as Map<String, dynamic>;

//           // Cache the data
//       prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));
//       prefs.setString('${cacheKey}_time', DateTime.now().toIso8601String());


//       // Cache the data
//       prefs.setString(cacheKey, json.encode(forecasts.map((f) => f.toJson()).toList()));

//       return forecasts;
//     } else {
//       throw Exception('Failed to load hourly forecast');
//     }
//   }

//     bool hasUpdateOccurred(DateTime lastCallTime, DateTime now) {
//     for (int hour in updateHours) {
//       for (int minute in updateMinutes) {
//         DateTime updateTime = DateTime(now.year, now.month, now.day, hour, minute);
//         if (updateTime.isAfter(lastCallTime) && updateTime.isBefore(now)) {
//           return true;
//         }
//       }
//     }
//     return false;
//   }
// }