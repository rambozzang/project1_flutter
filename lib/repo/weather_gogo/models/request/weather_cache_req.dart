// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class WeatherCacheReq {
  String? cacheKey;
  String? forecastType;
  String? baseDate;
  String? baseTime;
  String? cacheData;
  String? contentType;
  String? loX;
  String? loY;
  DateTime? expiresAt;
  WeatherCacheReq({
    this.cacheKey,
    this.forecastType,
    this.baseDate,
    this.baseTime,
    this.cacheData,
    this.contentType,
    this.loX,
    this.loY,
    this.expiresAt,
  });

  WeatherCacheReq copyWith({
    String? cacheKey,
    String? forecastType,
    String? baseDate,
    String? baseTime,
    String? cacheData,
    String? contentType,
    String? loX,
    String? loY,
    DateTime? expiresAt,
  }) {
    return WeatherCacheReq(
      cacheKey: cacheKey ?? this.cacheKey,
      forecastType: forecastType ?? this.forecastType,
      baseDate: baseDate ?? this.baseDate,
      baseTime: baseTime ?? this.baseTime,
      cacheData: cacheData ?? this.cacheData,
      contentType: contentType ?? this.contentType,
      loX: loX ?? this.loX,
      loY: loY ?? this.loY,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cacheKey': cacheKey,
      'forecastType': forecastType,
      'baseDate': baseDate,
      'baseTime': baseTime,
      'cacheData': cacheData,
      'contentType': contentType,
      'loX': loX,
      'loY': loY,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
    };
  }

  factory WeatherCacheReq.fromMap(Map<String, dynamic> map) {
    return WeatherCacheReq(
      cacheKey: map['cacheKey'] != null ? map['cacheKey'] as String : null,
      forecastType: map['forecastType'] != null ? map['forecastType'] as String : null,
      baseDate: map['baseDate'] != null ? map['baseDate'] as String : null,
      baseTime: map['baseTime'] != null ? map['baseTime'] as String : null,
      cacheData: map['cacheData'] != null ? map['cacheData'] as String : null,
      contentType: map['contentType'] != null ? map['contentType'] as String : null,
      loX: map['loX'] != null ? map['loX'] as String : null,
      loY: map['loY'] != null ? map['loY'] as String : null,
      expiresAt: map['expiresAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WeatherCacheReq.fromJson(String source) => WeatherCacheReq.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WeatherCacheReq(cacheKey: $cacheKey, forecastType: $forecastType, baseDate: $baseDate, baseTime: $baseTime, cacheData: $cacheData, contentType: $contentType, loX: $loX, loY: $loY, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(covariant WeatherCacheReq other) {
    if (identical(this, other)) return true;

    return other.cacheKey == cacheKey &&
        other.forecastType == forecastType &&
        other.baseDate == baseDate &&
        other.baseTime == baseTime &&
        other.cacheData == cacheData &&
        other.contentType == contentType &&
        other.loX == loX &&
        other.loY == loY &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return cacheKey.hashCode ^
        forecastType.hashCode ^
        baseDate.hashCode ^
        baseTime.hashCode ^
        cacheData.hashCode ^
        contentType.hashCode ^
        loX.hashCode ^
        loY.hashCode ^
        expiresAt.hashCode;
  }
}
