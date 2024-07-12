// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/*

  "DateTime": "2024-07-08T13:00:00+09:00",
    "EpochDateTime": 1720411200,
    "WeatherIcon": 15,
    "IconPhrase": "뇌우",
    "HasPrecipitation": true,
    "PrecipitationType": "Rain",
    "PrecipitationIntensity": "Moderate",
    "IsDaylight": true,
    "Temperature": {
      "Value": 24.4,
      "Unit": "C",
      "UnitType": 17
    },
    "PrecipitationProbability": 64,
    "MobileLink": "http://www.accuweather.com/ko/kr/seodaemun-gu/226002/hourly-weather-forecast/226002?day=1&hbhhour=13&unit=c",
    "Link": "http://www.accuweather.com/ko/kr/seodaemun-gu/226002/hourly-weather-forecast/226002?day=1&hbhhour=13&unit=c"
*/
class AccuResData {
  String? DateTime;
  int? EpochDateTime;
  int? WeatherIcon;
  String? IconPhrase;
  bool? HasPrecipitation;
  String? PrecipitationType;
  String? PrecipitationIntensity;
  bool? IsDaylight;
  TemperatureData? Temperature;
  int? PrecipitationProbability;
  String? MobileLink;
  String? Link;
  AccuResData({
    this.DateTime,
    this.EpochDateTime,
    this.WeatherIcon,
    this.IconPhrase,
    this.HasPrecipitation,
    this.PrecipitationType,
    this.PrecipitationIntensity,
    this.IsDaylight,
    this.Temperature,
    this.PrecipitationProbability,
    this.MobileLink,
    this.Link,
  });

  AccuResData copyWith({
    String? DateTime,
    int? EpochDateTime,
    int? WeatherIcon,
    String? IconPhrase,
    bool? HasPrecipitation,
    String? PrecipitationType,
    String? PrecipitationIntensity,
    bool? IsDaylight,
    TemperatureData? Temperature,
    int? PrecipitationProbability,
    String? MobileLink,
    String? Link,
  }) {
    return AccuResData(
      DateTime: DateTime ?? this.DateTime,
      EpochDateTime: EpochDateTime ?? this.EpochDateTime,
      WeatherIcon: WeatherIcon ?? this.WeatherIcon,
      IconPhrase: IconPhrase ?? this.IconPhrase,
      HasPrecipitation: HasPrecipitation ?? this.HasPrecipitation,
      PrecipitationType: PrecipitationType ?? this.PrecipitationType,
      PrecipitationIntensity: PrecipitationIntensity ?? this.PrecipitationIntensity,
      IsDaylight: IsDaylight ?? this.IsDaylight,
      Temperature: Temperature ?? this.Temperature,
      PrecipitationProbability: PrecipitationProbability ?? this.PrecipitationProbability,
      MobileLink: MobileLink ?? this.MobileLink,
      Link: Link ?? this.Link,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'DateTime': DateTime,
      'EpochDateTime': EpochDateTime,
      'WeatherIcon': WeatherIcon,
      'IconPhrase': IconPhrase,
      'HasPrecipitation': HasPrecipitation,
      'PrecipitationType': PrecipitationType,
      'PrecipitationIntensity': PrecipitationIntensity,
      'IsDaylight': IsDaylight,
      'Temperature': Temperature?.toMap(),
      'PrecipitationProbability': PrecipitationProbability,
      'MobileLink': MobileLink,
      'Link': Link,
    };
  }

  factory AccuResData.fromMap(Map<String, dynamic> map) {
    return AccuResData(
      DateTime: map['DateTime'] != null ? map['DateTime'] as String : null,
      EpochDateTime: map['EpochDateTime'] != null ? map['EpochDateTime'] as int : null,
      WeatherIcon: map['WeatherIcon'] != null ? map['WeatherIcon'] as int : null,
      IconPhrase: map['IconPhrase'] != null ? map['IconPhrase'] as String : null,
      HasPrecipitation: map['HasPrecipitation'] != null ? map['HasPrecipitation'] as bool : null,
      PrecipitationType: map['PrecipitationType'] != null ? map['PrecipitationType'] as String : null,
      PrecipitationIntensity: map['PrecipitationIntensity'] != null ? map['PrecipitationIntensity'] as String : null,
      IsDaylight: map['IsDaylight'] != null ? map['IsDaylight'] as bool : null,
      Temperature: map['Temperature'] != null ? TemperatureData.fromMap(map['Temperature'] as Map<String, dynamic>) : null,
      PrecipitationProbability: map['PrecipitationProbability'] != null ? map['PrecipitationProbability'] as int : null,
      MobileLink: map['MobileLink'] != null ? map['MobileLink'] as String : null,
      Link: map['Link'] != null ? map['Link'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AccuResData.fromJson(String source) => AccuResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AccuResData(DateTime: $DateTime, EpochDateTime: $EpochDateTime, WeatherIcon: $WeatherIcon, IconPhrase: $IconPhrase, HasPrecipitation: $HasPrecipitation, PrecipitationType: $PrecipitationType, PrecipitationIntensity: $PrecipitationIntensity, IsDaylight: $IsDaylight, Temperature: $Temperature, PrecipitationProbability: $PrecipitationProbability, MobileLink: $MobileLink, Link: $Link)';
  }

  @override
  bool operator ==(covariant AccuResData other) {
    if (identical(this, other)) return true;

    return other.DateTime == DateTime &&
        other.EpochDateTime == EpochDateTime &&
        other.WeatherIcon == WeatherIcon &&
        other.IconPhrase == IconPhrase &&
        other.HasPrecipitation == HasPrecipitation &&
        other.PrecipitationType == PrecipitationType &&
        other.PrecipitationIntensity == PrecipitationIntensity &&
        other.IsDaylight == IsDaylight &&
        other.Temperature == Temperature &&
        other.PrecipitationProbability == PrecipitationProbability &&
        other.MobileLink == MobileLink &&
        other.Link == Link;
  }

  @override
  int get hashCode {
    return DateTime.hashCode ^
        EpochDateTime.hashCode ^
        WeatherIcon.hashCode ^
        IconPhrase.hashCode ^
        HasPrecipitation.hashCode ^
        PrecipitationType.hashCode ^
        PrecipitationIntensity.hashCode ^
        IsDaylight.hashCode ^
        Temperature.hashCode ^
        PrecipitationProbability.hashCode ^
        MobileLink.hashCode ^
        Link.hashCode;
  }
}

class TemperatureData {
  double? Value;
  String? Unit;
  int? UnitType;
  TemperatureData({
    this.Value,
    this.Unit,
    this.UnitType,
  });

  TemperatureData copyWith({
    double? Value,
    String? Unit,
    int? UnitType,
  }) {
    return TemperatureData(
      Value: Value ?? this.Value,
      Unit: Unit ?? this.Unit,
      UnitType: UnitType ?? this.UnitType,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Value': Value,
      'Unit': Unit,
      'UnitType': UnitType,
    };
  }

  factory TemperatureData.fromMap(Map<String, dynamic> map) {
    return TemperatureData(
      Value: map['Value'] != null ? map['Value'] as double : null,
      Unit: map['Unit'] != null ? map['Unit'] as String : null,
      UnitType: map['UnitType'] != null ? map['UnitType'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TemperatureData.fromJson(String source) => TemperatureData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'TemperatureData(Value: $Value, Unit: $Unit, UnitType: $UnitType)';

  @override
  bool operator ==(covariant TemperatureData other) {
    if (identical(this, other)) return true;

    return other.Value == Value && other.Unit == Unit && other.UnitType == UnitType;
  }

  @override
  int get hashCode => Value.hashCode ^ Unit.hashCode ^ UnitType.hashCode;
}
