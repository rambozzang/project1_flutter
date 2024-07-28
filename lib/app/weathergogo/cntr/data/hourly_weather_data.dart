// ignore_for_file: public_member_api_docs, sort_constructors_first
class HourlyWeatherData {
  double temp;

  String? sky;
  String? rain;
  String? rainPo;
  DateTime date;

  HourlyWeatherData({
    required this.temp,
    this.sky,
    this.rain,
    this.rainPo,
    required this.date,
  });
}
