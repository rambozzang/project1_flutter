// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Wind {
  double? speed;
  int? deg;
  Wind({
    this.speed,
    this.deg,
  });

  Wind copyWith({
    double? speed,
    int? deg,
  }) {
    return Wind(
      speed: speed ?? this.speed,
      deg: deg ?? this.deg,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'speed': speed,
      'deg': deg,
    };
  }

  factory Wind.fromMap(Map<String, dynamic> map) {
    return Wind(
      speed: map['speed'] != null ? map['speed'] as double : null,
      deg: map['deg'] != null ? map['deg'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Wind.fromJson(String source) => Wind.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Wind(speed: $speed, deg: $deg)';

  @override
  bool operator ==(covariant Wind other) {
    if (identical(this, other)) return true;

    return other.speed == speed && other.deg == deg;
  }

  @override
  int get hashCode => speed.hashCode ^ deg.hashCode;
}
