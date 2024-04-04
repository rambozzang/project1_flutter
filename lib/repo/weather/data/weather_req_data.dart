// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class WeatherReqData {
  String? boardId;
  String? lat;
  String? lon;
  String? location;
  String? weatherInfo;
  String? videoPath;
  String? thumbnailPath;
  String? icon;
  String? currentTemp;
  String? feelsTemp;
  String? tempMin;
  String? tempMax;
  String? humidity;
  String? speed;
  String? country;
  String? city;
  WeatherReqData({
    this.boardId,
    this.lat,
    this.lon,
    this.location,
    this.weatherInfo,
    this.videoPath,
    this.thumbnailPath,
    this.icon,
    this.currentTemp,
    this.feelsTemp,
    this.tempMin,
    this.tempMax,
    this.humidity,
    this.speed,
    this.country,
    this.city,
  });

  WeatherReqData copyWith({
    String? boardId,
    String? lat,
    String? lon,
    String? location,
    String? weatherInfo,
    String? videoPath,
    String? thumbnailPath,
    String? icon,
    String? currentTemp,
    String? feelsTemp,
    String? tempMin,
    String? tempMax,
    String? humidity,
    String? speed,
    String? country,
    String? city,
  }) {
    return WeatherReqData(
      boardId: boardId ?? this.boardId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      location: location ?? this.location,
      weatherInfo: weatherInfo ?? this.weatherInfo,
      videoPath: videoPath ?? this.videoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      icon: icon ?? this.icon,
      currentTemp: currentTemp ?? this.currentTemp,
      feelsTemp: feelsTemp ?? this.feelsTemp,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      humidity: humidity ?? this.humidity,
      speed: speed ?? this.speed,
      country: country ?? this.country,
      city: city ?? this.city,
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
      'thumbnailPath': thumbnailPath,
      'icon': icon,
      'currentTemp': currentTemp,
      'feelsTemp': feelsTemp,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'humidity': humidity,
      'speed': speed,
      'country': country,
      'city': city,
    };
  }

  factory WeatherReqData.fromMap(Map<String, dynamic> map) {
    return WeatherReqData(
      boardId: map['boardId'] != null ? map['boardId'] as String : null,
      lat: map['lat'] != null ? map['lat'] as String : null,
      lon: map['lon'] != null ? map['lon'] as String : null,
      location: map['location'] != null ? map['location'] as String : null,
      weatherInfo: map['weatherInfo'] != null ? map['weatherInfo'] as String : null,
      videoPath: map['videoPath'] != null ? map['videoPath'] as String : null,
      thumbnailPath: map['thumbnailPath'] != null ? map['thumbnailPath'] as String : null,
      icon: map['icon'] != null ? map['icon'] as String : null,
      currentTemp: map['currentTemp'] != null ? map['currentTemp'] as String : null,
      feelsTemp: map['feelsTemp'] != null ? map['feelsTemp'] as String : null,
      tempMin: map['tempMin'] != null ? map['tempMin'] as String : null,
      tempMax: map['tempMax'] != null ? map['tempMax'] as String : null,
      humidity: map['humidity'] != null ? map['humidity'] as String : null,
      speed: map['speed'] != null ? map['speed'] as String : null,
      country: map['country'] != null ? map['country'] as String : null,
      city: map['city'] != null ? map['city'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WeatherReqData.fromJson(String source) => WeatherReqData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WeatherReqData(boardId: $boardId, lat: $lat, lon: $lon, location: $location, weatherInfo: $weatherInfo, videoPath: $videoPath, thumbnailPath: $thumbnailPath, icon: $icon, currentTemp: $currentTemp, feelsTemp: $feelsTemp, tempMin: $tempMin, tempMax: $tempMax, humidity: $humidity, speed: $speed, country: $country, city: $city)';
  }

  @override
  bool operator ==(covariant WeatherReqData other) {
    if (identical(this, other)) return true;

    return other.boardId == boardId &&
        other.lat == lat &&
        other.lon == lon &&
        other.location == location &&
        other.weatherInfo == weatherInfo &&
        other.videoPath == videoPath &&
        other.thumbnailPath == thumbnailPath &&
        other.icon == icon &&
        other.currentTemp == currentTemp &&
        other.feelsTemp == feelsTemp &&
        other.tempMin == tempMin &&
        other.tempMax == tempMax &&
        other.humidity == humidity &&
        other.speed == speed &&
        other.country == country &&
        other.city == city;
  }

  @override
  int get hashCode {
    return boardId.hashCode ^
        lat.hashCode ^
        lon.hashCode ^
        location.hashCode ^
        weatherInfo.hashCode ^
        videoPath.hashCode ^
        thumbnailPath.hashCode ^
        icon.hashCode ^
        currentTemp.hashCode ^
        feelsTemp.hashCode ^
        tempMin.hashCode ^
        tempMax.hashCode ^
        humidity.hashCode ^
        speed.hashCode ^
        country.hashCode ^
        city.hashCode;
  }
}
