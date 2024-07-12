import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class AdditionalWeatherData {
  String? precipitation;
  double? uvi;
  int? clouds;
  AdditionalWeatherData({
    this.precipitation,
    this.uvi,
    this.clouds,
  });
  // AdditionalWeatherData({
  //   required this.precipitation,
  //   required this.uvi,
  //   required this.clouds,
  // });

  // factory AdditionalWeatherData.fromJson(Map<String, dynamic> json) {
  //   final precipData = json['daily'][0]['pop'];
  //   final precip = (precipData * 100).toStringAsFixed(0);
  //   return AdditionalWeatherData(
  //     precipitation: precip,
  //     uvi: (json['daily'][0]['uvi']).toDouble(),
  //     clouds: json['daily'][0]['clouds'] ?? 0,
  //   );
  // }

  AdditionalWeatherData copyWith({
    String? precipitation,
    double? uvi,
    int? clouds,
  }) {
    return AdditionalWeatherData(
      precipitation: precipitation ?? this.precipitation,
      uvi: uvi ?? this.uvi,
      clouds: clouds ?? this.clouds,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'precipitation': precipitation,
      'uvi': uvi,
      'clouds': clouds,
    };
  }

  factory AdditionalWeatherData.fromMap(Map<String, dynamic> map) {
    return AdditionalWeatherData(
      precipitation: map['precipitation'] as String,
      uvi: map['uvi'].toDouble() as double,
      clouds: map['clouds'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory AdditionalWeatherData.fromJson(String source) => AdditionalWeatherData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'AdditionalWeatherData(precipitation: $precipitation, uvi: $uvi, clouds: $clouds)';

  @override
  bool operator ==(covariant AdditionalWeatherData other) {
    if (identical(this, other)) return true;

    return other.precipitation == precipitation && other.uvi == uvi && other.clouds == clouds;
  }

  @override
  int get hashCode => precipitation.hashCode ^ uvi.hashCode ^ clouds.hashCode;
}
