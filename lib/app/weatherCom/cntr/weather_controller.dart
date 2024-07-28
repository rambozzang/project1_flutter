import 'package:get/get.dart';
import 'package:project1/app/weatherCom/api/AccuWeatherClient.dart';
import 'package:project1/app/weatherCom/api/KmaClient.dart';
import 'package:project1/app/weatherCom/services/openweathermap_client.dart';
import 'package:project1/utils/log_utils.dart';
import '../models/weather_data.dart';
import '../services/weather_api_client.dart';

class WeatherControllerBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeatherController>(() => WeatherController([
          OpenWeatherMapClient(apiKey: 'c8bcc177b07a3bbcc9a75d0282c19164'),
          // AccuWeatherClient(apiKey: '9Dpql374txlRZGgiECCDS2gGcvuqdmeT'),
          // WeatherChannelClient(apiKey: 'YOUR_WEATHERCHANNEL_API_KEY'),
          // WeatherNewsClient(apiKey: 'YOUR_WEATHERNEWS_API_KEY'),
          //   KmaClient(apiKey: 'CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg=='),
        ]));
  }
}

class WeatherController extends GetxController {
  final List<WeatherApiClient> _clients;
  final _forecasts = <String, List<WeatherData>>{}.obs;
  final _isLoading = false.obs;

  WeatherController(this._clients);

  Map<String, List<WeatherData>> get forecasts => _forecasts;
  bool get isLoading => _isLoading.value;

  Future<void> fetchAllForecasts() async {
    _isLoading.value = true;
    try {
      for (var client in _clients) {
        final forecast = await client.getForecast();
        _forecasts[client.sourceName] = forecast;
      }
      // _forecasts 출력
      _forecasts.forEach((key, value) => Lo.g('$key: $value'));
    } catch (e) {
      print('Error fetching forecasts: $e');
      Get.snackbar('Error', 'Failed to fetch weather data');
    }
    _isLoading.value = false;
  }
}
