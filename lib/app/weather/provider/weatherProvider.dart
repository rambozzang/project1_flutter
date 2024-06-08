import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weather/models/additionalWeatherData.dart';
import 'package:project1/app/weather/models/geocode.dart';

import '../models/dailyWeather.dart';
import '../models/hourlyWeather.dart';
import '../models/weather.dart';

class WeatherProvider with ChangeNotifier {
  String apiKey = 'c8bcc177b07a3bbcc9a75d0282c19164';
  late Weather weather;
  late AdditionalWeatherData additionalWeatherData;
  LatLng? currentLocation;
  List<HourlyWeather> hourlyWeather = [];
  List<DailyWeather> dailyWeather = [];
  bool isLoading = false;
  bool isRequestError = false;
  bool isSearchError = false;
  bool isLocationserviceEnabled = false;
  LocationPermission? locationPermission;
  bool isCelsius = true;

  //7일 기준에서 가장 낮은 온도 / 가장 높은 온도
  double sevenDayMinTemp = 0.0;
  double sevenDayMaxTemp = 0.0;

  // 24시간 기준에서 가장 낮은 온도 / 가장 높은 온도
  // double get twentyFourHourMinTemp => hourlyWeather.map((e) => e.temp).reduce((value, element) => value < element ? value : element);
  // double get twentyFourHourMaxTemp => hourlyWeather.map((e) => e.temp).reduce((value, element) => value > element ? value : element);

  String get measurementUnit => isCelsius ? '°C' : '°F';

  Future<Position?> requestLocation(BuildContext context) async {
    isLocationserviceEnabled = await Geolocator.isLocationServiceEnabled();
    notifyListeners();

    if (!isLocationserviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location service disabled')),
      );
      return Future.error('Location services are disabled.');
    }

    locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      isLoading = false;
      notifyListeners();
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Permission denied'),
        ));
        return Future.error('Location permissions are denied');
      }
    }

    if (locationPermission == LocationPermission.deniedForever) {
      isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Location permissions are permanently denied, Please enable manually from app settings',
        ),
      ));
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> getWeatherData(
    BuildContext context, {
    bool notify = false,
  }) async {
    isLoading = true;
    isRequestError = false;
    isSearchError = false;
    if (notify) notifyListeners();

    Position? locData = await requestLocation(context);

    if (locData == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      currentLocation = LatLng(locData.latitude, locData.longitude);
      await getCurrentWeather(currentLocation!);
      await getDailyWeather(currentLocation!);
    } catch (e) {
      print(e);
      isRequestError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCurrentWeather(LatLng location) async {
    Uri url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lang=kr&lat=${location.latitude}&lon=${location.longitude}&units=metric&appid=$apiKey',
    );
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      weather = Weather.fromJson(extractedData);
      print('Fetched Weather for: ${weather.city}/${weather.countryCode}');
    } catch (error) {
      print(error);
      isLoading = false;
      this.isRequestError = true;
    }
  }

  Future<void> getDailyWeather(LatLng location) async {
    isLoading = true;
    notifyListeners();

    Uri dailyUrl = Uri.parse(
      'https://api.openweathermap.org/data/3.0/onecall?lang=kr&lat=${location.latitude}&lon=${location.longitude}&units=metric&exclude=minutely,current&appid=$apiKey',
    );
    try {
      final response = await http.get(dailyUrl);
      final dailyData = json.decode(response.body) as Map<String, dynamic>;
      additionalWeatherData = AdditionalWeatherData.fromJson(dailyData);
      List dailyList = dailyData['daily'];
      List hourlyList = dailyData['hourly'];
      hourlyWeather = hourlyList.map((item) => HourlyWeather.fromJson(item)).toList().take(24).toList();
      dailyWeather = dailyList.map((item) => DailyWeather.fromDailyJson(item)).toList();

      sevenDayMinTemp = dailyWeather.map((e) => e.tempMin).reduce((value, element) => value < element ? value : element);
      sevenDayMaxTemp = dailyWeather.map((e) => e.tempMax).reduce((value, element) => value > element ? value : element);
    } catch (error) {
      print(error);
      isLoading = false;
      this.isRequestError = true;
    }
  }

  // 한글 검색으로 변경이 필요함.
  Future<GeocodeData?> locationToLatLng(String location) async {
    try {
      Uri url = Uri.parse(
        'http://api.openweathermap.org/geo/1.0/direct?lang=kr&q=$location&limit=5&appid=$apiKey',
      );
      final http.Response response = await http.get(url);
      if (response.statusCode != 200) return null;

      // 카카오맵 API로 변경
      // https://dapi.kakao.com/v2/local/search/keyword.${FORMAT}
      // https://dapi.kakao.com/v2/local/search/address.${FORMAT}

      return GeocodeData.fromJson(
        jsonDecode(response.body)[0] as Map<String, dynamic>,
      );
    } catch (e) {
      print(e);
      return null;
    }
  }

  // 기존 영문으로검색시 사용하던 함수
  Future<void> searchWeather(String location) async {
    isLoading = true;
    notifyListeners();
    isRequestError = false;
    print('search');
    try {
      GeocodeData? geocodeData;
      geocodeData = await locationToLatLng(location);
      if (geocodeData == null) throw Exception('Unable to Find Location');
      await getCurrentWeather(geocodeData.latLng);
      await getDailyWeather(geocodeData.latLng);
      // replace location name with data from geocode
      // because data from certain lat long might return local area name
      weather.city = geocodeData.name;
    } catch (e) {
      print(e);
      isSearchError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // searchWeather 대체 카카오로 검색후 호출한다.
  Future<void> searchWeatherKakao(GeocodeData geocodeData) async {
    isLoading = true;
    notifyListeners();
    isRequestError = false;
    print('search');
    try {
      if (geocodeData == null) throw Exception('Unable to Find Location');
      await getCurrentWeather(geocodeData.latLng);
      await getDailyWeather(geocodeData.latLng);
      // replace location name with data from geocode
      // because data from certain lat long might return local area name
      weather.city = geocodeData.name;
    } catch (e) {
      print(e);
      isSearchError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void switchTempUnit() {
    isCelsius = !isCelsius;
    notifyListeners();
  }
}
