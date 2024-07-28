// ignore_for_file: public_member_api_docs, sort_constructors_first
class HourlyWeather {
  double temp;
  String weatherCategory;
  String? condition;
  DateTime date;

  HourlyWeather({
    required this.temp,
    required this.weatherCategory,
    this.condition,
    required this.date,
  });

  static HourlyWeather fromJson(dynamic json) {
    return HourlyWeather(
      temp: (json['temp']).toDouble(),
      weatherCategory: json['weather'][0]['main'],
      condition: json['weather'][0]['description'],
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }
}
