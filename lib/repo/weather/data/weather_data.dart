// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Weather {
  double? temp;
  double? tempMax;
  double? tempMin;
  String? condition;
  int? conditionId;
  int? humidity;
  Weather({
    this.temp,
    this.tempMax,
    this.tempMin,
    this.condition,
    this.conditionId,
    this.humidity,
  });

  Weather copyWith({
    double? temp,
    double? tempMax,
    double? tempMin,
    String? condition,
    int? conditionId,
    int? humidity,
  }) {
    return Weather(
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

  factory Weather.fromMap(Map<String, dynamic> map) {
    return Weather(
      temp: map['temp'] != null ? map['temp'] as double : null,
      tempMax: map['tempMax'] != null ? map['tempMax'] as double : null,
      tempMin: map['tempMin'] != null ? map['tempMin'] as double : null,
      condition: map['condition'] != null ? map['condition'] as String : null,
      conditionId: map['conditionId'] != null ? map['conditionId'] as int : null,
      humidity: map['humidity'] != null ? map['humidity'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Weather.fromJson(String source) => Weather.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Weather(temp: $temp, tempMax: $tempMax, tempMin: $tempMin, condition: $condition, conditionId: $conditionId, humidity: $humidity)';
  }

  @override
  bool operator ==(covariant Weather other) {
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
