// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

// temp, feels_like, temp_min, temp_max, 온드값들은 double이지만
// int로 넘어오는 경우가 있어 .toDouble()로 처리
class Main {
  double? temp;
  double? feels_like;
  double? temp_min;
  double? temp_max;
  int? pressure;
  int? humidity;
  Main({
    this.temp,
    this.feels_like,
    this.temp_min,
    this.temp_max,
    this.pressure,
    this.humidity,
  });

  Main copyWith({
    double? temp,
    double? feels_like,
    double? temp_min,
    double? temp_max,
    int? pressure,
    int? humidity,
  }) {
    return Main(
      temp: temp ?? this.temp,
      feels_like: feels_like ?? this.feels_like,
      temp_min: temp_min ?? this.temp_min,
      temp_max: temp_max ?? this.temp_max,
      pressure: pressure ?? this.pressure,
      humidity: humidity ?? this.humidity,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'temp': temp,
      'feels_like': feels_like,
      'temp_min': temp_min,
      'temp_max': temp_max,
      'pressure': pressure,
      'humidity': humidity,
    };
  }

  factory Main.fromMap(Map<String, dynamic> map) {
    return Main(
      temp: map['temp'] != null ? map['temp'].toDouble() as double : null,
      feels_like: map['feels_like'] != null ? map['feels_like'].toDouble() as double : null,
      temp_min: map['temp_min'] != null ? map['temp_min'].toDouble() as double : null,
      temp_max: map['temp_max'] != null ? map['temp_max'].toDouble() as double : null,
      pressure: map['pressure'] != null ? map['pressure'] as int : null,
      humidity: map['humidity'] != null ? map['humidity'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Main.fromJson(String source) => Main.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Main(temp: $temp, feels_like: $feels_like, temp_min: $temp_min, temp_max: $temp_max, pressure: $pressure, humidity: $humidity)';
  }

  @override
  bool operator ==(covariant Main other) {
    if (identical(this, other)) return true;

    return other.temp == temp &&
        other.feels_like == feels_like &&
        other.temp_min == temp_min &&
        other.temp_max == temp_max &&
        other.pressure == pressure &&
        other.humidity == humidity;
  }

  @override
  int get hashCode {
    return temp.hashCode ^ feels_like.hashCode ^ temp_min.hashCode ^ temp_max.hashCode ^ pressure.hashCode ^ humidity.hashCode;
  }
}
