// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Main {
  double? temp;
  double? feels_like;
  double? temp_min;
  double? temp_max;
  int? pressure;
  int? humidity;
  int? sea_level;
  int? grnd_level;
  Main({
    this.temp,
    this.feels_like,
    this.temp_min,
    this.temp_max,
    this.pressure,
    this.humidity,
    this.sea_level,
    this.grnd_level,
  });

  Main copyWith({
    double? temp,
    double? feels_like,
    double? temp_min,
    double? temp_max,
    int? pressure,
    int? humidity,
    int? sea_level,
    int? grnd_level,
  }) {
    return Main(
      temp: temp ?? this.temp,
      feels_like: feels_like ?? this.feels_like,
      temp_min: temp_min ?? this.temp_min,
      temp_max: temp_max ?? this.temp_max,
      pressure: pressure ?? this.pressure,
      humidity: humidity ?? this.humidity,
      sea_level: sea_level ?? this.sea_level,
      grnd_level: grnd_level ?? this.grnd_level,
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
      'sea_level': sea_level,
      'grnd_level': grnd_level,
    };
  }

  factory Main.fromMap(Map<String, dynamic> map) {
    return Main(
      temp: map['temp'] != null ? map['temp'] as double : null,
      feels_like: map['feels_like'] != null ? map['feels_like'] as double : null,
      temp_min: map['temp_min'] != null ? map['temp_min'] as double : null,
      temp_max: map['temp_max'] != null ? map['temp_max'] as double : null,
      pressure: map['pressure'] != null ? map['pressure'] as int : null,
      humidity: map['humidity'] != null ? map['humidity'] as int : null,
      sea_level: map['sea_level'] != null ? map['sea_level'] as int : null,
      grnd_level: map['grnd_level'] != null ? map['grnd_level'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Main.fromJson(String source) => Main.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Main(temp: $temp, feels_like: $feels_like, temp_min: $temp_min, temp_max: $temp_max, pressure: $pressure, humidity: $humidity, sea_level: $sea_level, grnd_level: $grnd_level)';
  }

  @override
  bool operator ==(covariant Main other) {
    if (identical(this, other)) return true;

    return other.temp == temp &&
        other.feels_like == feels_like &&
        other.temp_min == temp_min &&
        other.temp_max == temp_max &&
        other.pressure == pressure &&
        other.humidity == humidity &&
        other.sea_level == sea_level &&
        other.grnd_level == grnd_level;
  }

  @override
  int get hashCode {
    return temp.hashCode ^
        feels_like.hashCode ^
        temp_min.hashCode ^
        temp_max.hashCode ^
        pressure.hashCode ^
        humidity.hashCode ^
        sea_level.hashCode ^
        grnd_level.hashCode;
  }
}
