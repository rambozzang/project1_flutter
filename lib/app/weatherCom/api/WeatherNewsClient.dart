import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project1/app/weatherCom/services/weather_api_client.dart';
import '../models/weather_data.dart';
// import 'weather_api_client.dart';

class WeatherNewsClient implements WeatherApiClient {
  final String apiKey;
  final String city;

  WeatherNewsClient({required this.apiKey, this.city = 'Seoul'});

  @override
  String get sourceName => 'Weather News';

  @override
  Future<List<WeatherData>> getForecast() async {
    final url = 'https://api.weathernews.jp/v1/forecast?city=$city&apikey=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<WeatherData> forecast = [];

      for (var item in data['hourly']) {
        forecast.add(WeatherData(
          time: DateTime.parse(item['time']),
          temperature: item['temperature'].toDouble(),
          humidity: item['humidity'].toDouble(),
          rainProbability: item['precipitation']['probability'].toDouble(),
          source: sourceName,
        ));
      }

      return forecast.take(24).toList(); // 24시간 예보만 반환
    } else {
      throw Exception('Failed to load forecast from Weather News');
    }
  }
}
