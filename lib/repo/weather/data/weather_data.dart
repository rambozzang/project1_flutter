// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/*
{
  "base": "stations",
  "clouds": {
    "all": 75
  },
  "cod": 200,
  "coord": {
    "lat": 37.3323,
    "lon": -122.0312
  },
  "dt": 1711350357,
  "id": 5341145,
  "main": {
    "feels_like": 9.45,
    "humidity": 85,
    "pressure": 1013,
    "temp": 9.45,
    "temp_max": 11.83,
    "temp_min": 7.21
  },
  "name": "Cupertino",
  "sys": {
    "country": "US",
    "id": 2001717,
    "sunrise": 1711375390,
    "sunset": 1711419867,
    "type": 2
  },
  "timezone": -25200,
  "visibility": 10000,
  "weather": [
    {
      "description": "broken clouds",
      "icon": "04n",
      "id": 803,
      "main": "Clouds"
    }
  ],
  "wind": {
    "deg": 294,
    "gust": 0.89,
    "speed": 0.45
  }
}
*/
class WeatherData {
  double? temp; // 현재 온드
  double? tempMax; // 최저 온도
  double? tempMin; // 최고 온도
  String? condition; // 흐림 정도
  int? conditionId;
  int? humidity;
  WeatherData({
    this.temp,
    this.tempMax,
    this.tempMin,
    this.condition,
    this.conditionId,
    this.humidity,
  });

  WeatherData copyWith({
    double? temp,
    double? tempMax,
    double? tempMin,
    String? condition,
    int? conditionId,
    int? humidity,
  }) {
    return WeatherData(
      temp: temp ?? this.temp,
      tempMax: tempMax ?? this.tempMax,
      tempMin: tempMin ?? this.tempMin,
      condition: condition ?? this.condition,
      conditionId: conditionId ?? this.conditionId,
      humidity: humidity ?? this.humidity,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'temp': temp,
      'tempMax': tempMax,
      'tempMin': tempMin,
      'condition': condition,
      'conditionId': conditionId,
      'humidity': humidity,
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      temp: map['temp'] != null ? map['temp'] as double : null,
      tempMax: map['tempMax'] != null ? map['tempMax'] as double : null,
      tempMin: map['tempMin'] != null ? map['tempMin'] as double : null,
      condition: map['condition'] != null ? map['condition'] as String : null,
      conditionId: map['conditionId'] != null ? map['conditionId'] as int : null,
      humidity: map['humidity'] != null ? map['humidity'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WeatherData.fromJson(String source) => WeatherData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WeatherData(temp: $temp, tempMax: $tempMax, tempMin: $tempMin, condition: $condition, conditionId: $conditionId, humidity: $humidity)';
  }

  @override
  bool operator ==(covariant WeatherData other) {
    if (identical(this, other)) return true;

    return other.temp == temp &&
        other.tempMax == tempMax &&
        other.tempMin == tempMin &&
        other.condition == condition &&
        other.conditionId == conditionId &&
        other.humidity == humidity;
  }

  @override
  int get hashCode {
    return temp.hashCode ^ tempMax.hashCode ^ tempMin.hashCode ^ condition.hashCode ^ conditionId.hashCode ^ humidity.hashCode;
  }
}
