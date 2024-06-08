// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CctvSeoulReqData {
  double? southWestLat;
  double? southWestLng;
  double? northEastLat;
  double? northEastLng;
  double? lat;
  double? lng;
  CctvSeoulReqData({
    this.southWestLat,
    this.southWestLng,
    this.northEastLat,
    this.northEastLng,
    this.lat,
    this.lng,
  });

  CctvSeoulReqData copyWith({
    double? southWestLat,
    double? southWestLng,
    double? northEastLat,
    double? northEastLng,
    double? lat,
    double? lng,
  }) {
    return CctvSeoulReqData(
      southWestLat: southWestLat ?? this.southWestLat,
      southWestLng: southWestLng ?? this.southWestLng,
      northEastLat: northEastLat ?? this.northEastLat,
      northEastLng: northEastLng ?? this.northEastLng,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'southWestLat': southWestLat,
      'southWestLng': southWestLng,
      'northEastLat': northEastLat,
      'northEastLng': northEastLng,
      'lat': lat,
      'lng': lng,
    };
  }

  factory CctvSeoulReqData.fromMap(Map<String, dynamic> map) {
    return CctvSeoulReqData(
      southWestLat: map['southWestLat'] != null ? map['southWestLat'] as double : null,
      southWestLng: map['southWestLng'] != null ? map['southWestLng'] as double : null,
      northEastLat: map['northEastLat'] != null ? map['northEastLat'] as double : null,
      northEastLng: map['northEastLng'] != null ? map['northEastLng'] as double : null,
      lat: map['lat'] != null ? map['lat'] as double : null,
      lng: map['lng'] != null ? map['lng'] as double : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CctvSeoulReqData.fromJson(String source) => CctvSeoulReqData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CctvSeoulReqData(southWestLat: $southWestLat, southWestLng: $southWestLng, northEastLat: $northEastLat, northEastLng: $northEastLng, lat: $lat, lng: $lng)';
  }

  @override
  bool operator ==(covariant CctvSeoulReqData other) {
    if (identical(this, other)) return true;

    return other.southWestLat == southWestLat &&
        other.southWestLng == southWestLng &&
        other.northEastLat == northEastLat &&
        other.northEastLng == northEastLng &&
        other.lat == lat &&
        other.lng == lng;
  }

  @override
  int get hashCode {
    return southWestLat.hashCode ^ southWestLng.hashCode ^ northEastLat.hashCode ^ northEastLng.hashCode ^ lat.hashCode ^ lng.hashCode;
  }
}
