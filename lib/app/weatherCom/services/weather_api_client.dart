import '../models/weather_data.dart';

abstract class WeatherApiClient {
  Future<List<WeatherData>> getForecast();
  String get sourceName;
}
