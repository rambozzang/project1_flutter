import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project1/app/weatherCom/services/weather_api_client.dart';
import '../models/weather_data.dart';
// import 'weather_api_client.dart';

class KmaClient implements WeatherApiClient {
  final String apiKey;
  final String nx;
  final String ny;

  KmaClient({required this.apiKey, this.nx = '60', this.ny = '127'}); // Seoul coordinates

  @override
  String get sourceName => 'KMA';

  @override
  Future<List<WeatherData>> getForecast() async {
    final baseDate = DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    final baseTime = '0500'; // Assuming 05:00 KST as the base time
    final url = 'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst'
        '?serviceKey=$apiKey&numOfRows=1000&pageNo=1&base_date=$baseDate&base_time=$baseTime&nx=$nx&ny=$ny&dataType=JSON';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['response']['body']['items']['item'];

      Map<String, WeatherData> forecastMap = {};

      for (var item in items) {
        final datetime = DateTime.parse('${item['fcstDate']} ${item['fcstTime']}');
        final key = datetime.toString();

        if (!forecastMap.containsKey(key)) {
          forecastMap[key] = WeatherData(
            time: datetime,
            temperature: 0,
            humidity: 0,
            rainProbability: 0,
            source: sourceName,
          );
        }

        switch (item['category']) {
          case 'TMP':
            forecastMap[key] = forecastMap[key]!.copyWith(temperature: double.parse(item['fcstValue']));
            break;
          case 'REH':
            forecastMap[key] = forecastMap[key]!.copyWith(humidity: double.parse(item['fcstValue']));
            break;
          case 'POP':
            forecastMap[key] = forecastMap[key]!.copyWith(rainProbability: double.parse(item['fcstValue']));
            break;
        }
      }

      return forecastMap.values.toList()..sort((a, b) => a.time.compareTo(b.time));
    } else {
      throw Exception('Failed to load forecast from KMA');
    }
  }
}

// WeatherData 클래스에 copyWith 메서드 추가
extension WeatherDataExtension on WeatherData {
  WeatherData copyWith({
    DateTime? time,
    double? temperature,
    double? humidity,
    double? rainProbability,
    String? source,
  }) {
    return WeatherData(
      time: time ?? this.time,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      rainProbability: rainProbability ?? this.rainProbability,
      source: source ?? this.source,
    );
  }
}
