// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CctvReqData {
  String? apiKey;
  String? type;
  String? cctvType;
  double? minX;
  double? minY;
  double? maxX;
  double? maxY;
  String? getType;
  CctvReqData({
    this.apiKey,
    this.type,
    this.cctvType,
    this.minX,
    this.minY,
    this.maxX,
    this.maxY,
    this.getType,
  });

  CctvReqData copyWith({
    String? apiKey,
    String? type,
    String? cctvType,
    double? minX,
    double? minY,
    double? maxX,
    double? maxY,
    String? getType,
  }) {
    return CctvReqData(
      apiKey: apiKey ?? this.apiKey,
      type: type ?? this.type,
      cctvType: cctvType ?? this.cctvType,
      minX: minX ?? this.minX,
      minY: minY ?? this.minY,
      maxX: maxX ?? this.maxX,
      maxY: maxY ?? this.maxY,
      getType: getType ?? this.getType,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'apiKey': apiKey,
      'type': type,
      'cctvType': cctvType,
      'minX': minX,
      'minY': minY,
      'maxX': maxX,
      'maxY': maxY,
      'getType': getType,
    };
  }

  factory CctvReqData.fromMap(Map<String, dynamic> map) {
    return CctvReqData(
      apiKey: map['apiKey'] != null ? map['apiKey'] as String : null,
      type: map['type'] != null ? map['type'] as String : null,
      cctvType: map['cctvType'] != null ? map['cctvType'] as String : null,
      minX: map['minX'] != null ? map['minX'] as double : null,
      minY: map['minY'] != null ? map['minY'] as double : null,
      maxX: map['maxX'] != null ? map['maxX'] as double : null,
      maxY: map['maxY'] != null ? map['maxY'] as double : null,
      getType: map['getType'] != null ? map['getType'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CctvReqData.fromJson(String source) => CctvReqData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CctvReqData(apiKey: $apiKey, type: $type, cctvType: $cctvType, minX: $minX, minY: $minY, maxX: $maxX, maxY: $maxY, getType: $getType)';
  }

  @override
  bool operator ==(covariant CctvReqData other) {
    if (identical(this, other)) return true;

    return other.apiKey == apiKey &&
        other.type == type &&
        other.cctvType == cctvType &&
        other.minX == minX &&
        other.minY == minY &&
        other.maxX == maxX &&
        other.maxY == maxY &&
        other.getType == getType;
  }

  @override
  int get hashCode {
    return apiKey.hashCode ^
        type.hashCode ^
        cctvType.hashCode ^
        minX.hashCode ^
        minY.hashCode ^
        maxX.hashCode ^
        maxY.hashCode ^
        getType.hashCode;
  }
}
