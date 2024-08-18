import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project1/utils/log_utils.dart';

/*
 final api = WeatherAlertAPI();
  try {
    final alerts = await api.getWeatherAlerts();
    for (var alert in alerts) {
      print('Type: ${alert.alertType}');
      print('Area: ${alert.areaName}');
      print('Start: ${alert.startTime}');
      print('End: ${alert.endTime}');
      print('---');
    }
  } catch (e) {
    print('Error: $e');
  }
*/
class WeatherAlertAPI {
  final String baseUrl = 'http://apis.data.go.kr/1360000/WthrWrnInfoService';
  final String serviceKey = 'CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==';

  Future<List<WeatherAlert>> getWeatherAlerts() async {
    final url = Uri.parse('$baseUrl/getWthrWrnList'
        '?serviceKey=$serviceKey'
        '&numOfRows=10'
        '&pageNo=1'
        '&dataType=JSON');

    lo.g('url : $url');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final items = jsonResponse['response']['body']['items']['item'];

      return List<WeatherAlert>.from(items.map((item) => WeatherAlert.fromJson(item)));
    } else {
      throw Exception('Failed to load weather alerts');
    }
  }
}

class WeatherAlert {
  final String alertType;
  final String areaName;
  final String startTime;
  final String endTime;

  WeatherAlert({
    required this.alertType,
    required this.areaName,
    required this.startTime,
    required this.endTime,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      alertType: json['t1'] ?? '',
      areaName: json['t2'] ?? '',
      startTime: json['t3'] ?? '',
      endTime: json['t4'] ?? '',
    );
  }
}
