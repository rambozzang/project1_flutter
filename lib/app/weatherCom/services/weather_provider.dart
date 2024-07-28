import 'package:flutter/foundation.dart';
import '../models/weather_data.dart';
import '../services/weather_api_client.dart';

class WeatherProvider with ChangeNotifier {
  final List<WeatherApiClient> _clients;
  Map<String, List<WeatherData>> _forecasts = {};
  bool _isLoading = false;

  WeatherProvider(this._clients);

  Map<String, List<WeatherData>> get forecasts => _forecasts;
  bool get isLoading => _isLoading;

  Future<void> fetchAllForecasts() async {
    _isLoading = true;
    notifyListeners();

    try {
      for (var client in _clients) {
        final forecast = await client.getForecast();
        _forecasts[client.sourceName] = forecast;
      }
    } catch (e) {
      print('Error fetching forecasts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
