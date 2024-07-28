// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

// Response Data Class
class MidTaResponse {
  final String regId;
  final int taMin3;
  final int taMax3;
  final int taMin4;
  final int taMax4;
  final int taMin5;
  final int taMax5;
  final int taMin6;
  final int taMax6;
  final int taMin7;
  final int taMax7;
  MidTaResponse({
    required this.regId,
    required this.taMin3,
    required this.taMax3,
    required this.taMin4,
    required this.taMax4,
    required this.taMin5,
    required this.taMax5,
    required this.taMin6,
    required this.taMax6,
    required this.taMin7,
    required this.taMax7,
  });

  MidTaResponse copyWith({
    String? regId,
    int? taMin3,
    int? taMax3,
    int? taMin4,
    int? taMax4,
    int? taMin5,
    int? taMax5,
    int? taMin6,
    int? taMax6,
    int? taMin7,
    int? taMax7,
  }) {
    return MidTaResponse(
      regId: regId ?? this.regId,
      taMin3: taMin3 ?? this.taMin3,
      taMax3: taMax3 ?? this.taMax3,
      taMin4: taMin4 ?? this.taMin4,
      taMax4: taMax4 ?? this.taMax4,
      taMin5: taMin5 ?? this.taMin5,
      taMax5: taMax5 ?? this.taMax5,
      taMin6: taMin6 ?? this.taMin6,
      taMax6: taMax6 ?? this.taMax6,
      taMin7: taMin7 ?? this.taMin7,
      taMax7: taMax7 ?? this.taMax7,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'regId': regId,
      'taMin3': taMin3,
      'taMax3': taMax3,
      'taMin4': taMin4,
      'taMax4': taMax4,
      'taMin5': taMin5,
      'taMax5': taMax5,
      'taMin6': taMin6,
      'taMax6': taMax6,
      'taMin7': taMin7,
      'taMax7': taMax7,
    };
  }

  factory MidTaResponse.fromMap(Map<String, dynamic> map) {
    return MidTaResponse(
      regId: map['regId'] as String,
      taMin3: map['taMin3'] as int,
      taMax3: map['taMax3'] as int,
      taMin4: map['taMin4'] as int,
      taMax4: map['taMax4'] as int,
      taMin5: map['taMin5'] as int,
      taMax5: map['taMax5'] as int,
      taMin6: map['taMin6'] as int,
      taMax6: map['taMax6'] as int,
      taMin7: map['taMin7'] as int,
      taMax7: map['taMax7'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory MidTaResponse.fromJson(String source) => MidTaResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MidTaResponse(regId: $regId, taMin3: $taMin3, taMax3: $taMax3, taMin4: $taMin4, taMax4: $taMax4, taMin5: $taMin5, taMax5: $taMax5, taMin6: $taMin6, taMax6: $taMax6, taMin7: $taMin7, taMax7: $taMax7)';
  }

  @override
  bool operator ==(covariant MidTaResponse other) {
    if (identical(this, other)) return true;

    return other.regId == regId &&
        other.taMin3 == taMin3 &&
        other.taMax3 == taMax3 &&
        other.taMin4 == taMin4 &&
        other.taMax4 == taMax4 &&
        other.taMin5 == taMin5 &&
        other.taMax5 == taMax5 &&
        other.taMin6 == taMin6 &&
        other.taMax6 == taMax6 &&
        other.taMin7 == taMin7 &&
        other.taMax7 == taMax7;
  }

  @override
  int get hashCode {
    return regId.hashCode ^
        taMin3.hashCode ^
        taMax3.hashCode ^
        taMin4.hashCode ^
        taMax4.hashCode ^
        taMin5.hashCode ^
        taMax5.hashCode ^
        taMin6.hashCode ^
        taMax6.hashCode ^
        taMin7.hashCode ^
        taMax7.hashCode;
  }
}
