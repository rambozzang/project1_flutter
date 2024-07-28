import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project1/app/weatherCom/services/weather_api_client.dart';
import '../models/weather_data.dart';
// import 'weather_api_client.dart';

class AccuWeatherClient implements WeatherApiClient {
  final String apiKey;
  final String locationKey;

  AccuWeatherClient({required this.apiKey, this.locationKey = '226081'}); // 226081 is Seoul

  @override
  String get sourceName => 'AccuWeather';

  @override
  Future<List<WeatherData>> getForecast() async {
    final url = 'http://dataservice.accuweather.com/forecasts/v1/hourly/24hour/$locationKey?apikey=$apiKey&metric=true';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => WeatherData(
                time: DateTime.parse(item['DateTime']),
                temperature: item['Temperature']['Value'].toDouble(),
                humidity: item['RelativeHumidity'].toDouble(),
                rainProbability: item['PrecipitationProbability'].toDouble(),
                source: sourceName,
              ))
          .toList();
    } else {
      throw Exception('Failed to load forecast from AccuWeather');
    }
  }
}
