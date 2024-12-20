import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WeatherData {
  final DateTime time;
  final double temperature;
  final double humidity;
  final double rainProbability;
  final String source;

  WeatherData({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
    required this.source,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      time: DateTime.parse(json['time']),
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      rainProbability: json['rainProbability'].toDouble(),
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'rainProbability': rainProbability,
      'source': source,
    };
  }
}
