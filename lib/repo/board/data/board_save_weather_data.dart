// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:project1/utils/log_utils.dart';

class BoardSaveWeatherData {
  int? boardId;
  String? lat;
  String? lon;
  String? location;
  String? weatherInfo;
  String? videoPath;
  String? videoId;
  String? thumbnailPath;
  String? thumbnailId;
  String? icon;
  String? sky;
  String? rain;
  String? currentTemp;
  String? feelsTemp;
  String? tempMin;
  String? tempMax;
  String? humidity;
  String? speed;
  String? country;
  String? city;
  String? mist10;
  String? mist25;
  BoardSaveWeatherData({
    this.boardId,
    this.lat,
    this.lon,
    this.location,
    this.weatherInfo,
    this.videoPath,
    this.videoId,
    this.thumbnailPath,
    this.thumbnailId,
    this.icon,
    this.sky,
    this.rain,
    this.currentTemp,
    this.feelsTemp,
    this.tempMin,
    this.tempMax,
    this.humidity,
    this.speed,
    this.country,
    this.city,
    this.mist10,
    this.mist25,
  });

  BoardSaveWeatherData copyWith({
    int? boardId,
    String? lat,
    String? lon,
    String? location,
    String? weatherInfo,
    String? videoPath,
    String? videoId,
    String? thumbnailPath,
    String? thumbnailId,
    String? icon,
    String? sky,
    String? rain,
    String? currentTemp,
    String? feelsTemp,
    String? tempMin,
    String? tempMax,
    String? humidity,
    String? speed,
    String? country,
    String? city,
    String? mist10,
    String? mist25,
  }) {
    return BoardSaveWeatherData(
      boardId: boardId ?? this.boardId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      location: location ?? this.location,
      weatherInfo: weatherInfo ?? this.weatherInfo,
      videoPath: videoPath ?? this.videoPath,
      videoId: videoId ?? this.videoId,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      thumbnailId: thumbnailId ?? this.thumbnailId,
      icon: icon ?? this.icon,
      sky: sky ?? this.sky,
      rain: rain ?? this.rain,
      currentTemp: currentTemp ?? this.currentTemp,
      feelsTemp: feelsTemp ?? this.feelsTemp,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      humidity: humidity ?? this.humidity,
      speed: speed ?? this.speed,
      country: country ?? this.country,
      city: city ?? this.city,
      mist10: mist10 ?? this.mist10,
      mist25: mist25 ?? this.mist25,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'boardId': boardId,
      'lat': lat,
      'lon': lon,
      'location': location,
      'weatherInfo': weatherInfo,
      'videoPath': videoPath,
      'videoId': videoId,
      'thumbnailPath': thumbnailPath,
      'thumbnailId': thumbnailId,
      'icon': icon,
      'sky': sky,
      'rain': rain,
      'currentTemp': currentTemp,
      'feelsTemp': feelsTemp,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'humidity': humidity,
      'speed': speed,
      'country': country,
      'city': city,
      'mist10': mist10,
      'mist25': mist25,
    };
  }

  factory BoardSaveWeatherData.fromMap(Map<String, dynamic> map) {
    return BoardSaveWeatherData(
      boardId: map['boardId'] != null ? map['boardId'] as int : null,
      lat: map['lat'] != null ? map['lat'] as String : null,
      lon: map['lon'] != null ? map['lon'] as String : null,
      location: map['location'] != null ? map['location'] as String : null,
      weatherInfo: map['weatherInfo'] != null ? map['weatherInfo'] as String : null,
      videoPath: map['videoPath'] != null ? map['videoPath'] as String : null,
      videoId: map['videoId'] != null ? map['videoId'] as String : null,
      thumbnailPath: map['thumbnailPath'] != null ? map['thumbnailPath'] as String : null,
      thumbnailId: map['thumbnailId'] != null ? map['thumbnailId'] as String : null,
      icon: map['icon'] != null ? map['icon'] as String : null,
      sky: map['sky'] != null ? map['sky'] as String : null,
      rain: map['rain'] != null ? map['rain'] as String : null,
      currentTemp: map['currentTemp'] != null ? map['currentTemp'] as String : null,
      feelsTemp: map['feelsTemp'] != null ? map['feelsTemp'] as String : null,
      tempMin: map['tempMin'] != null ? map['tempMin'] as String : null,
      tempMax: map['tempMax'] != null ? map['tempMax'] as String : null,
      humidity: map['humidity'] != null ? map['humidity'] as String : null,
      speed: map['speed'] != null ? map['speed'] as String : null,
      country: map['country'] != null ? map['country'] as String : null,
      city: map['city'] != null ? map['city'] as String : null,
      mist10: map['mist10'] != null ? map['mist10'] as String : null,
      mist25: map['mist25'] != null ? map['mist25'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardSaveWeatherData.fromJson(String source) => BoardSaveWeatherData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardSaveWeatherData(boardId: $boardId, lat: $lat, lon: $lon, location: $location, weatherInfo: $weatherInfo, videoPath: $videoPath, videoId: $videoId, thumbnailPath: $thumbnailPath, thumbnailId: $thumbnailId, icon: $icon, sky: $sky, rain: $rain, currentTemp: $currentTemp, feelsTemp: $feelsTemp, tempMin: $tempMin, tempMax: $tempMax, humidity: $humidity, speed: $speed, country: $country, city: $city, mist10: $mist10, mist25: $mist25)';
  }

  @override
  bool operator ==(covariant BoardSaveWeatherData other) {
    if (identical(this, other)) return true;

    return other.boardId == boardId &&
        other.lat == lat &&
        other.lon == lon &&
        other.location == location &&
        other.weatherInfo == weatherInfo &&
        other.videoPath == videoPath &&
        other.videoId == videoId &&
        other.thumbnailPath == thumbnailPath &&
        other.thumbnailId == thumbnailId &&
        other.icon == icon &&
        other.sky == sky &&
        other.rain == rain &&
        other.currentTemp == currentTemp &&
        other.feelsTemp == feelsTemp &&
        other.tempMin == tempMin &&
        other.tempMax == tempMax &&
        other.humidity == humidity &&
        other.speed == speed &&
        other.country == country &&
        other.city == city &&
        other.mist10 == mist10 &&
        other.mist25 == mist25;
  }

  @override
  int get hashCode {
    return boardId.hashCode ^
        lat.hashCode ^
        lon.hashCode ^
        location.hashCode ^
        weatherInfo.hashCode ^
        videoPath.hashCode ^
        videoId.hashCode ^
        thumbnailPath.hashCode ^
        thumbnailId.hashCode ^
        icon.hashCode ^
        sky.hashCode ^
        rain.hashCode ^
        currentTemp.hashCode ^
        feelsTemp.hashCode ^
        tempMin.hashCode ^
        tempMax.hashCode ^
        humidity.hashCode ^
        speed.hashCode ^
        country.hashCode ^
        city.hashCode ^
        mist10.hashCode ^
        mist25.hashCode;
  }
}
