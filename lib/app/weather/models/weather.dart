// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/cupertino.dart';

class Weather {
  double? temp;
  final double? tempMax;
  final double? tempMin;
  final double? lat;
  final double? long;
  final double? feelsLike;
  final int? pressure;
  final String? description;
  final String? weatherCategory;
  final int? humidity;
  final double? windSpeed;
  String? city;
  final String? countryCode;
  Weather({
    this.temp,
    this.tempMax,
    this.tempMin,
    this.lat,
    this.long,
    this.feelsLike,
    this.pressure,
    this.description,
    this.weatherCategory,
    this.humidity,
    this.windSpeed,
    this.city,
    this.countryCode,
  });

  // Weather({
  //   required this.temp,
  //   required this.tempMax,
  //   required this.tempMin,
  //   required this.lat,
  //   required this.long,
  //   required this.feelsLike,
  //   required this.pressure,
  //   required this.description,
  //   required this.weatherCategory,
  //   required this.humidity,
  //   required this.windSpeed,
  //   required this.city,
  //   required this.countryCode,
  // });

  // factory Weather.fromJson(Map<String, dynamic> json) {
  //   return Weather(
  //     temp: (json['main']['temp']).toDouble(),
  //     tempMax: (json['main']['temp_max']).toDouble(),
  //     tempMin: (json['main']['temp_min']).toDouble(),
  //     lat: json['coord']['lat'],
  //     long: json['coord']['lon'],
  //     feelsLike: (json['main']['feels_like']).toDouble(),
  //     pressure: json['main']['pressure'],
  //     weatherCategory: json['weather'][0]['main'],
  //     description: json['weather'][0]['description'],
  //     humidity: json['main']['humidity'],
  //     windSpeed: (json['wind']['speed']).toDouble(),
  //     city: json['name'],
  //     countryCode: json['sys']['country'],
  //   );
  // }

  Weather copyWith({
    double? temp,
    double? tempMax,
    double? tempMin,
    double? lat,
    double? long,
    double? feelsLike,
    int? pressure,
    String? description,
    String? weatherCategory,
    int? humidity,
    double? windSpeed,
    String? city,
    String? countryCode,
  }) {
    return Weather(
      temp: temp ?? this.temp,
      tempMax: tempMax ?? this.tempMax,
      tempMin: tempMin ?? this.tempMin,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      feelsLike: feelsLike ?? this.feelsLike,
      pressure: pressure ?? this.pressure,
      description: description ?? this.description,
      weatherCategory: weatherCategory ?? this.weatherCategory,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      city: city ?? this.city,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'temp': temp,
      'tempMax': tempMax,
      'tempMin': tempMin,
      'lat': lat,
      'long': long,
      'feelsLike': feelsLike,
      'pressure': pressure,
      'description': description,
      'weatherCategory': weatherCategory,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'city': city,
      'countryCode': countryCode,
    };
  }

  factory Weather.fromMap(Map<String, dynamic> map) {
    return Weather(
      temp: map['temp'].toDouble() as double,
      tempMax: map['tempMax'].toDouble() as double,
      tempMin: map['tempMin'].toDouble() as double,
      lat: map['lat'].toDouble() as double,
      long: map['long'].toDouble() as double,
      feelsLike: map['feelsLike'].toDouble() as double,
      pressure: map['pressure'] as int,
      description: map['description'] as String,
      weatherCategory: map['weatherCategory'] as String,
      humidity: map['humidity'] as int,
      windSpeed: map['windSpeed'].toDouble() as double,
      city: map['city'] as String,
      countryCode: map['countryCode'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Weather.fromJson(String source) => Weather.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Weather(temp: $temp, tempMax: $tempMax, tempMin: $tempMin, lat: $lat, long: $long, feelsLike: $feelsLike, pressure: $pressure, description: $description, weatherCategory: $weatherCategory, humidity: $humidity, windSpeed: $windSpeed, city: $city, countryCode: $countryCode)';
  }

  @override
  bool operator ==(covariant Weather other) {
    if (identical(this, other)) return true;

    return other.temp == temp &&
        other.tempMax == tempMax &&
        other.tempMin == tempMin &&
        other.lat == lat &&
        other.long == long &&
        other.feelsLike == feelsLike &&
        other.pressure == pressure &&
        other.description == description &&
        other.weatherCategory == weatherCategory &&
        other.humidity == humidity &&
        other.windSpeed == windSpeed &&
        other.city == city &&
        other.countryCode == countryCode;
  }

  @override
  int get hashCode {
    return temp.hashCode ^
        tempMax.hashCode ^
        tempMin.hashCode ^
        lat.hashCode ^
        long.hashCode ^
        feelsLike.hashCode ^
        pressure.hashCode ^
        description.hashCode ^
        weatherCategory.hashCode ^
        humidity.hashCode ^
        windSpeed.hashCode ^
        city.hashCode ^
        countryCode.hashCode;
  }
}
