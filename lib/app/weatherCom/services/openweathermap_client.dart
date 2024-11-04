import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import 'weather_api_client.dart';

class OpenWeatherMapClient implements WeatherApiClient {
  final String apiKey;
  final String city;

  OpenWeatherMapClient({required this.apiKey, this.city = 'Seoul'});

  @override
  String get sourceName => 'OpenWeatherMap';

  @override
  Future<List<WeatherData>> getForecast() async {
    final url = 'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<WeatherData> forecast = [];

      for (var item in data['list']) {
        forecast.add(WeatherData(
          time: DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
          temperature: item['main']['temp'].toDouble(),
          humidity: item['main']['humidity'].toDouble(),
          rainProbability: item['pop'].toDouble() * 100,
          source: sourceName,
        ));
      }

      forecast.map((e) => print(e));

      return forecast.take(24).toList(); // 24시간 예보만 반환
    } else {
      throw Exception('Failed to load forecast from OpenWeatherMap');
    }
  }
}
