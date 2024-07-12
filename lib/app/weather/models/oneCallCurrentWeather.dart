// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

// 현재 온도는 pop 가 안넘오고있음
// https://openweathermap.org/api/one-call-3
class OneCallCurrentWeather {
  int? dt;
  int? sunrise;
  int? sunset;
  double? temp;
  double? feels_like;
  int? pressure;
  int? humidity;
  double? dew_point;
  double? uvi;
  int? clouds;
  int? visibility;
  double? wind_speed;
  int? wind_deg;
  double? windGust;
  List<OneWeather>? weather;
  double? pop;
  OneCallCurrentWeather({
    this.dt,
    this.sunrise,
    this.sunset,
    this.temp,
    this.feels_like,
    this.pressure,
    this.humidity,
    this.dew_point,
    this.uvi,
    this.clouds,
    this.visibility,
    this.wind_speed,
    this.wind_deg,
    this.windGust,
    this.weather,
    this.pop,
  });

  OneCallCurrentWeather copyWith({
    int? dt,
    int? sunrise,
    int? sunset,
    double? temp,
    double? feels_like,
    int? pressure,
    int? humidity,
    double? dew_point,
    double? uvi,
    int? clouds,
    int? visibility,
    double? wind_speed,
    int? wind_deg,
    double? windGust,
    List<OneWeather>? weather,
    double? pop,
  }) {
    return OneCallCurrentWeather(
      dt: dt ?? this.dt,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      temp: temp ?? this.temp,
      feels_like: feels_like ?? this.feels_like,
      pressure: pressure ?? this.pressure,
      humidity: humidity ?? this.humidity,
      dew_point: dew_point ?? this.dew_point,
      uvi: uvi ?? this.uvi,
      clouds: clouds ?? this.clouds,
      visibility: visibility ?? this.visibility,
      wind_speed: wind_speed ?? this.wind_speed,
      wind_deg: wind_deg ?? this.wind_deg,
      windGust: windGust ?? this.windGust,
      weather: weather ?? this.weather,
      pop: pop ?? this.pop,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dt': dt,
      'sunrise': sunrise,
      'sunset': sunset,
      'temp': temp,
      'feels_like': feels_like,
      'pressure': pressure,
      'humidity': humidity,
      'dew_point': dew_point,
      'uvi': uvi,
      'clouds': clouds,
      'visibility': visibility,
      'wind_speed': wind_speed,
      'wind_deg': wind_deg,
      'windGust': windGust,
      'weather': weather!.map((x) => x.toMap()).toList(),
      'pop': pop,
    };
  }

  factory OneCallCurrentWeather.fromMap(Map<String, dynamic> map) {
    return OneCallCurrentWeather(
      dt: map['dt'] != null ? map['dt'] as int : null,
      sunrise: map['sunrise'] != null ? map['sunrise'] as int : null,
      sunset: map['sunset'] != null ? map['sunset'] as int : null,
      temp: map['temp'] != null ? map['temp'].toDouble() as double : null,
      feels_like: map['feels_like'] != null ? map['feels_like'].toDouble() as double : null,
      pressure: map['pressure'] != null ? map['pressure'] as int : null,
      humidity: map['humidity'] != null ? map['humidity'] as int : null,
      dew_point: map['dew_point'] != null ? map['dew_point'].toDouble() as double : null,
      uvi: map['uvi'] != null ? map['uvi'].toDouble() as double : null,
      clouds: map['clouds'] != null ? map['clouds'] as int : null,
      visibility: map['visibility'] != null ? map['visibility'] as int : null,
      wind_speed: map['wind_speed'] != null ? map['wind_speed'].toDouble() as double : null,
      wind_deg: map['wind_deg'] != null ? map['wind_deg'] as int : null,
      windGust: map['windGust'] != null ? map['windGust'].toDouble() as double : null,
      weather: map['weather'] != null
          ? List<OneWeather>.from(
              (map['weather'] as List).map<OneWeather?>(
                (x) => OneWeather.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      pop: map['pop'] != null ? map['pop'] as double : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory OneCallCurrentWeather.fromJson(String source) => OneCallCurrentWeather.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OneCallCurrentWeather(dt: $dt, sunrise: $sunrise, sunset: $sunset, temp: $temp, feels_like: $feels_like, pressure: $pressure, humidity: $humidity, dew_point: $dew_point, uvi: $uvi, clouds: $clouds, visibility: $visibility, wind_speed: $wind_speed, wind_deg: $wind_deg, windGust: $windGust, weather: $weather, pop: $pop)';
  }

  @override
  bool operator ==(covariant OneCallCurrentWeather other) {
    if (identical(this, other)) return true;

    return other.dt == dt &&
        other.sunrise == sunrise &&
        other.sunset == sunset &&
        other.temp == temp &&
        other.feels_like == feels_like &&
        other.pressure == pressure &&
        other.humidity == humidity &&
        other.dew_point == dew_point &&
        other.uvi == uvi &&
        other.clouds == clouds &&
        other.visibility == visibility &&
        other.wind_speed == wind_speed &&
        other.wind_deg == wind_deg &&
        other.windGust == windGust &&
        listEquals(other.weather, weather) &&
        other.pop == pop;
  }

  @override
  int get hashCode {
    return dt.hashCode ^
        sunrise.hashCode ^
        sunset.hashCode ^
        temp.hashCode ^
        feels_like.hashCode ^
        pressure.hashCode ^
        humidity.hashCode ^
        dew_point.hashCode ^
        uvi.hashCode ^
        clouds.hashCode ^
        visibility.hashCode ^
        wind_speed.hashCode ^
        wind_deg.hashCode ^
        windGust.hashCode ^
        weather.hashCode ^
        pop.hashCode;
  }
}

class OneWeather {
  int? id;
  String? main;
  String? description;
  String? icon;
  OneWeather({
    this.id,
    this.main,
    this.description,
    this.icon,
  });

  OneWeather copyWith({
    int? id,
    String? main,
    String? description,
    String? icon,
  }) {
    return OneWeather(
      id: id ?? this.id,
      main: main ?? this.main,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'main': main,
      'description': description,
      'icon': icon,
    };
  }

  factory OneWeather.fromMap(Map<String, dynamic> map) {
    return OneWeather(
      id: map['id'] != null ? map['id'] as int : null,
      main: map['main'] != null ? map['main'] as String : null,
      description: map['description'] != null ? map['description'] as String : null,
      icon: map['icon'] != null ? map['icon'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory OneWeather.fromJson(String source) => OneWeather.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OneWeather(id: $id, main: $main, description: $description, icon: $icon)';
  }

  @override
  bool operator ==(covariant OneWeather other) {
    if (identical(this, other)) return true;

    return other.id == id && other.main == main && other.description == description && other.icon == icon;
  }

  @override
  int get hashCode {
    return id.hashCode ^ main.hashCode ^ description.hashCode ^ icon.hashCode;
  }
}
