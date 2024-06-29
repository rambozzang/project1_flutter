// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

/*
/// coord : {"lon":9.19,"lat":45.4642}
/// weather : [{"id":802,"main":"Clouds","description":"구름조금","icon":"03d"}]
/// base : "stations"
/// main : {"temp":18.73,"feels_like":17.94,"temp_min":17.67,"temp_max":20.4,"pressure":1023,"humidity":49}
/// visibility : 10000
/// wind : {"speed":3.09,"deg":90}
/// clouds : {"all":40}
/// dt : 1651140421
/// sys : {"type":2,"id":2012644,"country":"IT","sunrise":1651119376,"sunset":1651170299}
/// timezone : 7200
/// id : 3173435
/// name : "Milan"
/// cod : 200
*/
import 'package:project1/repo/weather/data/Clouds.dart';
import 'package:project1/repo/weather/data/Coord.dart';
import 'package:project1/repo/weather/data/Main.dart';
import 'package:project1/repo/weather/data/Sys.dart';
import 'package:project1/repo/weather/data/Weather.dart';
import 'package:project1/repo/weather/data/Wind.dart';

// 아래 형식으로 데이터가 들어옴 오류가 나오는 형싱
//  getCurrentWeather e =>type 'int' is not a subtype of type 'String?'
//  {
//      coord: {lon: 126.9443, lat: 37.5887},
//      weather: [{id: 800, main: Clear, description: 맑음, icon: 01d}]
//      base: "stations",
//      main: {temp: 31.1, feels_like: 31.85, temp_min: 26.73, temp_max: 33.69, pressure: 1002, humidity: 45},
//      visibility: 10000,
//      wind: {speed: 5.14, deg: 270},
//      clouds: {all: 0},
//      dt: 1718949477,
//      sys: {type: 1, id: 8105, country: KR, sunrise: 1718914267, sunset: 1718967409},
//      timezone: 32400,
//      id: 1835848,
//      name: "Seoul",
//      cod: 20

// 아래는 정상
// {
//        coord: {lon: 126.9845, lat: 37.5793},
//        weather: [{id: 800, main: Clear, description: 맑음, icon: 01d}]
//        base: "stations",
//        main: {temp: 29.17, feels_like: 30.86, temp_min: 25.75, temp_max: 33.71, pressure: 1002, humidity: 57},
//        visibility: 10000,
//        wind: {speed: 4.12, deg: 280},
//        clouds: {all: 0},
//        dt: 1718954826,
//        sys: {type: 1, id: 8105, country: KR, sunrise: 1718914259, sunset: 1718967398},
//        timezone: 32400,
//        id: 1835848,
//        name: "Seoul",
//        cod: 200
//   }

class CurrentWeather {
  Coord? coord;
  List<Weather>? weather;
  String? base;
  Main? main;
  int? visibility;
  Wind? wind;
  Clouds? clouds;
  int? dt;
  Sys? sys;
  int? timezone;
  int? id;
  String? name;
  int? cod;
  CurrentWeather({
    this.coord,
    this.weather,
    this.base,
    this.main,
    this.visibility,
    this.wind,
    this.clouds,
    this.dt,
    this.sys,
    this.timezone,
    this.id,
    this.name,
    this.cod,
  });

  CurrentWeather copyWith({
    Coord? coord,
    List<Weather>? weather,
    String? base,
    Main? main,
    int? visibility,
    Wind? wind,
    Clouds? clouds,
    int? dt,
    Sys? sys,
    int? timezone,
    int? id,
    String? name,
    int? cod,
  }) {
    return CurrentWeather(
      coord: coord ?? this.coord,
      weather: weather ?? this.weather,
      base: base ?? this.base,
      main: main ?? this.main,
      visibility: visibility ?? this.visibility,
      wind: wind ?? this.wind,
      clouds: clouds ?? this.clouds,
      dt: dt ?? this.dt,
      sys: sys ?? this.sys,
      timezone: timezone ?? this.timezone,
      id: id ?? this.id,
      name: name ?? this.name,
      cod: cod ?? this.cod,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'coord': coord?.toMap(),
      'weather': weather!.map((x) => x?.toMap()).toList(),
      'base': base,
      'main': main?.toMap(),
      'visibility': visibility,
      'wind': wind?.toMap(),
      'clouds': clouds?.toMap(),
      'dt': dt,
      'sys': sys?.toMap(),
      'timezone': timezone,
      'id': id,
      'name': name,
      'cod': cod,
    };
  }

  factory CurrentWeather.fromMap(Map<String, dynamic> map) {
    return CurrentWeather(
      coord: map['coord'] != null ? Coord.fromMap(map['coord'] as Map<String, dynamic>) : null,
      weather: map['weather'] != null
          ? List<Weather>.from(
              (map['weather'] as List).map<Weather?>(
                (x) => Weather.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      base: map['base'] != null ? map['base'] as String : null,
      main: map['main'] != null ? Main.fromMap(map['main'] as Map<String, dynamic>) : null,
      visibility: map['visibility'] != null ? map['visibility'] as int : null,
      wind: map['wind'] != null ? Wind.fromMap(map['wind'] as Map<String, dynamic>) : null,
      clouds: map['clouds'] != null ? Clouds.fromMap(map['clouds'] as Map<String, dynamic>) : null,
      dt: map['dt'] != null ? map['dt'] as int : null,
      sys: map['sys'] != null ? Sys.fromMap(map['sys'] as Map<String, dynamic>) : null,
      timezone: map['timezone'] != null ? map['timezone'] as int : null,
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] != null ? map['name'] as String : null,
      cod: map['cod'] != null ? map['cod'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CurrentWeather.fromJson(String source) => CurrentWeather.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CurrentWeather(coord: $coord, weather: $weather, base: $base, main: $main, visibility: $visibility, wind: $wind, clouds: $clouds, dt: $dt, sys: $sys, timezone: $timezone, id: $id, name: $name, cod: $cod)';
  }

  @override
  bool operator ==(covariant CurrentWeather other) {
    if (identical(this, other)) return true;

    return other.coord == coord &&
        listEquals(other.weather, weather) &&
        other.base == base &&
        other.main == main &&
        other.visibility == visibility &&
        other.wind == wind &&
        other.clouds == clouds &&
        other.dt == dt &&
        other.sys == sys &&
        other.timezone == timezone &&
        other.id == id &&
        other.name == name &&
        other.cod == cod;
  }

  @override
  int get hashCode {
    return coord.hashCode ^
        weather.hashCode ^
        base.hashCode ^
        main.hashCode ^
        visibility.hashCode ^
        wind.hashCode ^
        clouds.hashCode ^
        dt.hashCode ^
        sys.hashCode ^
        timezone.hashCode ^
        id.hashCode ^
        name.hashCode ^
        cod.hashCode;
  }
}
