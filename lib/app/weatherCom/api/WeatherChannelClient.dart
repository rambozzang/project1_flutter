import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project1/app/weatherCom/services/weather_api_client.dart';
import '../models/weather_data.dart';
// import 'weather_api_client.dart';

class WeatherChannelClient implements WeatherApiClient {
  final String apiKey;
  final String location;

  WeatherChannelClient({required this.apiKey, this.location = '37.57,126.98'}); // Seoul coordinates

  @override
  String get sourceName => 'Weather Channel';

  @override
  Future<List<WeatherData>> getForecast() async {
    final url = 'https://api.weather.com/v3/wx/forecast/hourly/24hour?apiKey=$apiKey&geocode=$location&format=json&units=m';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<WeatherData> forecast = [];

      for (var i = 0; i < 24; i++) {
        forecast.add(WeatherData(
          time: DateTime.fromMillisecondsSinceEpoch(data['validTimeUtc'][i] * 1000),
          temperature: data['temperature'][i].toDouble(),
          humidity: data['relativeHumidity'][i].toDouble(),
          rainProbability: data['precipChance'][i].toDouble(),
          source: sourceName,
        ));
      }

      return forecast;
    } else {
      throw Exception('Failed to load forecast from Weather Channel');
    }
  }
}
