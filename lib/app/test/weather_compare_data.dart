// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class WeatherCompareData {
  String? provider;
  String? hour;
  String? temp;
  String? desc;
  String? icon;
  WeatherCompareData({
    this.provider,
    this.hour,
    this.temp,
    this.desc,
    this.icon,
  });

  WeatherCompareData copyWith({
    String? provider,
    String? hour,
    String? temp,
    String? desc,
    String? icon,
  }) {
    return WeatherCompareData(
      provider: provider ?? this.provider,
      hour: hour ?? this.hour,
      temp: temp ?? this.temp,
      desc: desc ?? this.desc,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'provider': provider,
      'hour': hour,
      'temp': temp,
      'desc': desc,
      'icon': icon,
    };
  }

  factory WeatherCompareData.fromMap(Map<String, dynamic> map) {
    return WeatherCompareData(
      provider: map['provider'] != null ? map['provider'] as String : null,
      hour: map['hour'] != null ? map['hour'] as String : null,
      temp: map['temp'] != null ? map['temp'] as String : null,
      desc: map['desc'] != null ? map['desc'] as String : null,
      icon: map['icon'] != null ? map['icon'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WeatherCompareData.fromJson(String source) => WeatherCompareData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WeatherCompareData(provider: $provider, hour: $hour, temp: $temp, desc: $desc, icon: $icon)';
  }

  @override
  bool operator ==(covariant WeatherCompareData other) {
    if (identical(this, other)) return true;

    return other.provider == provider && other.hour == hour && other.temp == temp && other.desc == desc && other.icon == icon;
  }

  @override
  int get hashCode {
    return provider.hashCode ^ hour.hashCode ^ temp.hashCode ^ desc.hashCode ^ icon.hashCode;
  }
}
