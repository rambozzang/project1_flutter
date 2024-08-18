import 'dart:convert';

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

  HourlyWeatherData copyWith({
    double? temp,
    String? sky,
    String? rain,
    String? rainPo,
    DateTime? date,
  }) {
    return HourlyWeatherData(
      temp: temp ?? this.temp,
      sky: sky ?? this.sky,
      rain: rain ?? this.rain,
      rainPo: rainPo ?? this.rainPo,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'temp': temp,
      'sky': sky,
      'rain': rain,
      'rainPo': rainPo,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory HourlyWeatherData.fromMap(Map<String, dynamic> map) {
    return HourlyWeatherData(
      temp: map['temp'] as double,
      sky: map['sky'] != null ? map['sky'] as String : null,
      rain: map['rain'] != null ? map['rain'] as String : null,
      rainPo: map['rainPo'] != null ? map['rainPo'] as String : null,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory HourlyWeatherData.fromJson(String source) => HourlyWeatherData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'HourlyWeatherData(temp: $temp, sky: $sky, rain: $rain, rainPo: $rainPo, date: $date)';
  }

  @override
  bool operator ==(covariant HourlyWeatherData other) {
    if (identical(this, other)) return true;

    return other.temp == temp && other.sky == sky && other.rain == rain && other.rainPo == rainPo && other.date == date;
  }

  @override
  int get hashCode {
    return temp.hashCode ^ sky.hashCode ^ rain.hashCode ^ rainPo.hashCode ^ date.hashCode;
  }
}
