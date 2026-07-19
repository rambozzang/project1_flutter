// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

// Response Data Class
class MidTaResponse {
  final String regId;

  // 4일차는 발표 시각에 따라 값이 비어 올 수 있어 nullable 로 둔다(5일차 이상은 기존처럼 필수).
  final int? taMin4;
  final int? taMin4Low;
  final int? taMin4High;
  final int? taMax4;
  final int? taMax4Low;
  final int? taMax4High;
  final int taMin5;
  final int taMin5Low;
  final int taMin5High;
  final int taMax5;
  final int taMax5Low;
  final int taMax5High;
  final int taMin6;
  final int taMin6Low;
  final int taMin6High;
  final int taMax6;
  final int taMax6Low;
  final int taMax6High;
  final int taMin7;
  final int taMin7Low;
  final int taMin7High;
  final int taMax7;
  final int taMax7Low;
  final int taMax7High;
  final int taMin8;
  final int taMin8Low;
  final int taMin8High;
  final int taMax8;
  final int taMax8Low;
  final int taMax8High;
  final int taMin9;
  final int taMin9Low;
  final int taMin9High;
  final int taMax9;
  final int taMax9Low;
  final int taMax9High;
  final int taMin10;
  final int taMin10Low;
  final int taMin10High;
  final int taMax10;
  final int taMax10Low;
  final int taMax10High;
  MidTaResponse({
    required this.regId,
    this.taMin4,
    this.taMin4Low,
    this.taMin4High,
    this.taMax4,
    this.taMax4Low,
    this.taMax4High,
    required this.taMin5,
    required this.taMin5Low,
    required this.taMin5High,
    required this.taMax5,
    required this.taMax5Low,
    required this.taMax5High,
    required this.taMin6,
    required this.taMin6Low,
    required this.taMin6High,
    required this.taMax6,
    required this.taMax6Low,
    required this.taMax6High,
    required this.taMin7,
    required this.taMin7Low,
    required this.taMin7High,
    required this.taMax7,
    required this.taMax7Low,
    required this.taMax7High,
    required this.taMin8,
    required this.taMin8Low,
    required this.taMin8High,
    required this.taMax8,
    required this.taMax8Low,
    required this.taMax8High,
    required this.taMin9,
    required this.taMin9Low,
    required this.taMin9High,
    required this.taMax9,
    required this.taMax9Low,
    required this.taMax9High,
    required this.taMin10,
    required this.taMin10Low,
    required this.taMin10High,
    required this.taMax10,
    required this.taMax10Low,
    required this.taMax10High,
  });

  MidTaResponse copyWith({
    String? regId,
    int? taMin4,
    int? taMin4Low,
    int? taMin4High,
    int? taMax4,
    int? taMax4Low,
    int? taMax4High,
    int? taMin5,
    int? taMin5Low,
    int? taMin5High,
    int? taMax5,
    int? taMax5Low,
    int? taMax5High,
    int? taMin6,
    int? taMin6Low,
    int? taMin6High,
    int? taMax6,
    int? taMax6Low,
    int? taMax6High,
    int? taMin7,
    int? taMin7Low,
    int? taMin7High,
    int? taMax7,
    int? taMax7Low,
    int? taMax7High,
    int? taMin8,
    int? taMin8Low,
    int? taMin8High,
    int? taMax8,
    int? taMax8Low,
    int? taMax8High,
    int? taMin9,
    int? taMin9Low,
    int? taMin9High,
    int? taMax9,
    int? taMax9Low,
    int? taMax9High,
    int? taMin10,
    int? taMin10Low,
    int? taMin10High,
    int? taMax10,
    int? taMax10Low,
    int? taMax10High,
  }) {
    return MidTaResponse(
      regId: regId ?? this.regId,
      taMin4: taMin4 ?? this.taMin4,
      taMin4Low: taMin4Low ?? this.taMin4Low,
      taMin4High: taMin4High ?? this.taMin4High,
      taMax4: taMax4 ?? this.taMax4,
      taMax4Low: taMax4Low ?? this.taMax4Low,
      taMax4High: taMax4High ?? this.taMax4High,
      taMin5: taMin5 ?? this.taMin5,
      taMin5Low: taMin5Low ?? this.taMin5Low,
      taMin5High: taMin5High ?? this.taMin5High,
      taMax5: taMax5 ?? this.taMax5,
      taMax5Low: taMax5Low ?? this.taMax5Low,
      taMax5High: taMax5High ?? this.taMax5High,
      taMin6: taMin6 ?? this.taMin6,
      taMin6Low: taMin6Low ?? this.taMin6Low,
      taMin6High: taMin6High ?? this.taMin6High,
      taMax6: taMax6 ?? this.taMax6,
      taMax6Low: taMax6Low ?? this.taMax6Low,
      taMax6High: taMax6High ?? this.taMax6High,
      taMin7: taMin7 ?? this.taMin7,
      taMin7Low: taMin7Low ?? this.taMin7Low,
      taMin7High: taMin7High ?? this.taMin7High,
      taMax7: taMax7 ?? this.taMax7,
      taMax7Low: taMax7Low ?? this.taMax7Low,
      taMax7High: taMax7High ?? this.taMax7High,
      taMin8: taMin8 ?? this.taMin8,
      taMin8Low: taMin8Low ?? this.taMin8Low,
      taMin8High: taMin8High ?? this.taMin8High,
      taMax8: taMax8 ?? this.taMax8,
      taMax8Low: taMax8Low ?? this.taMax8Low,
      taMax8High: taMax8High ?? this.taMax8High,
      taMin9: taMin9 ?? this.taMin9,
      taMin9Low: taMin9Low ?? this.taMin9Low,
      taMin9High: taMin9High ?? this.taMin9High,
      taMax9: taMax9 ?? this.taMax9,
      taMax9Low: taMax9Low ?? this.taMax9Low,
      taMax9High: taMax9High ?? this.taMax9High,
      taMin10: taMin10 ?? this.taMin10,
      taMin10Low: taMin10Low ?? this.taMin10Low,
      taMin10High: taMin10High ?? this.taMin10High,
      taMax10: taMax10 ?? this.taMax10,
      taMax10Low: taMax10Low ?? this.taMax10Low,
      taMax10High: taMax10High ?? this.taMax10High,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'regId': regId,
      'taMin4': taMin4,
      'taMin4Low': taMin4Low,
      'taMin4High': taMin4High,
      'taMax4': taMax4,
      'taMax4Low': taMax4Low,
      'taMax4High': taMax4High,
      'taMin5': taMin5,
      'taMin5Low': taMin5Low,
      'taMin5High': taMin5High,
      'taMax5': taMax5,
      'taMax5Low': taMax5Low,
      'taMax5High': taMax5High,
      'taMin6': taMin6,
      'taMin6Low': taMin6Low,
      'taMin6High': taMin6High,
      'taMax6': taMax6,
      'taMax6Low': taMax6Low,
      'taMax6High': taMax6High,
      'taMin7': taMin7,
      'taMin7Low': taMin7Low,
      'taMin7High': taMin7High,
      'taMax7': taMax7,
      'taMax7Low': taMax7Low,
      'taMax7High': taMax7High,
      'taMin8': taMin8,
      'taMin8Low': taMin8Low,
      'taMin8High': taMin8High,
      'taMax8': taMax8,
      'taMax8Low': taMax8Low,
      'taMax8High': taMax8High,
      'taMin9': taMin9,
      'taMin9Low': taMin9Low,
      'taMin9High': taMin9High,
      'taMax9': taMax9,
      'taMax9Low': taMax9Low,
      'taMax9High': taMax9High,
      'taMin10': taMin10,
      'taMin10Low': taMin10Low,
      'taMin10High': taMin10High,
      'taMax10': taMax10,
      'taMax10Low': taMax10Low,
      'taMax10High': taMax10High,
    };
  }

  factory MidTaResponse.fromMap(Map<String, dynamic> map) {
    return MidTaResponse(
      regId: map['regId'] as String,
      taMin4: map['taMin4'] as int?,
      taMin4Low: map['taMin4Low'] as int?,
      taMin4High: map['taMin4High'] as int?,
      taMax4: map['taMax4'] as int?,
      taMax4Low: map['taMax4Low'] as int?,
      taMax4High: map['taMax4High'] as int?,
      taMin5: map['taMin5'] as int,
      taMin5Low: map['taMin5Low'] as int,
      taMin5High: map['taMin5High'] as int,
      taMax5: map['taMax5'] as int,
      taMax5Low: map['taMax5Low'] as int,
      taMax5High: map['taMax5High'] as int,
      taMin6: map['taMin6'] as int,
      taMin6Low: map['taMin6Low'] as int,
      taMin6High: map['taMin6High'] as int,
      taMax6: map['taMax6'] as int,
      taMax6Low: map['taMax6Low'] as int,
      taMax6High: map['taMax6High'] as int,
      taMin7: map['taMin7'] as int,
      taMin7Low: map['taMin7Low'] as int,
      taMin7High: map['taMin7High'] as int,
      taMax7: map['taMax7'] as int,
      taMax7Low: map['taMax7Low'] as int,
      taMax7High: map['taMax7High'] as int,
      taMin8: map['taMin8'] as int,
      taMin8Low: map['taMin8Low'] as int,
      taMin8High: map['taMin8High'] as int,
      taMax8: map['taMax8'] as int,
      taMax8Low: map['taMax8Low'] as int,
      taMax8High: map['taMax8High'] as int,
      taMin9: map['taMin9'] as int,
      taMin9Low: map['taMin9Low'] as int,
      taMin9High: map['taMin9High'] as int,
      taMax9: map['taMax9'] as int,
      taMax9Low: map['taMax9Low'] as int,
      taMax9High: map['taMax9High'] as int,
      taMin10: map['taMin10'] as int,
      taMin10Low: map['taMin10Low'] as int,
      taMin10High: map['taMin10High'] as int,
      taMax10: map['taMax10'] as int,
      taMax10Low: map['taMax10Low'] as int,
      taMax10High: map['taMax10High'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory MidTaResponse.fromJson(String source) => MidTaResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MidTaResponse(regId: $regId, taMin4: $taMin4, taMin4Low: $taMin4Low, taMin4High: $taMin4High, taMax4: $taMax4, taMax4Low: $taMax4Low, taMax4High: $taMax4High, taMin5: $taMin5, taMin5Low: $taMin5Low, taMin5High: $taMin5High, taMax5: $taMax5, taMax5Low: $taMax5Low, taMax5High: $taMax5High, taMin6: $taMin6, taMin6Low: $taMin6Low, taMin6High: $taMin6High, taMax6: $taMax6, taMax6Low: $taMax6Low, taMax6High: $taMax6High, taMin7: $taMin7, taMin7Low: $taMin7Low, taMin7High: $taMin7High, taMax7: $taMax7, taMax7Low: $taMax7Low, taMax7High: $taMax7High, taMin8: $taMin8, taMin8Low: $taMin8Low, taMin8High: $taMin8High, taMax8: $taMax8, taMax8Low: $taMax8Low, taMax8High: $taMax8High, taMin9: $taMin9, taMin9Low: $taMin9Low, taMin9High: $taMin9High, taMax9: $taMax9, taMax9Low: $taMax9Low, taMax9High: $taMax9High, taMin10: $taMin10, taMin10Low: $taMin10Low, taMin10High: $taMin10High, taMax10: $taMax10, taMax10Low: $taMax10Low, taMax10High: $taMax10High)';
  }

  @override
  bool operator ==(covariant MidTaResponse other) {
    if (identical(this, other)) return true;

    return other.regId == regId &&
        other.taMin4 == taMin4 &&
        other.taMin4Low == taMin4Low &&
        other.taMin4High == taMin4High &&
        other.taMax4 == taMax4 &&
        other.taMax4Low == taMax4Low &&
        other.taMax4High == taMax4High &&
        other.taMin5 == taMin5 &&
        other.taMin5Low == taMin5Low &&
        other.taMin5High == taMin5High &&
        other.taMax5 == taMax5 &&
        other.taMax5Low == taMax5Low &&
        other.taMax5High == taMax5High &&
        other.taMin6 == taMin6 &&
        other.taMin6Low == taMin6Low &&
        other.taMin6High == taMin6High &&
        other.taMax6 == taMax6 &&
        other.taMax6Low == taMax6Low &&
        other.taMax6High == taMax6High &&
        other.taMin7 == taMin7 &&
        other.taMin7Low == taMin7Low &&
        other.taMin7High == taMin7High &&
        other.taMax7 == taMax7 &&
        other.taMax7Low == taMax7Low &&
        other.taMax7High == taMax7High &&
        other.taMin8 == taMin8 &&
        other.taMin8Low == taMin8Low &&
        other.taMin8High == taMin8High &&
        other.taMax8 == taMax8 &&
        other.taMax8Low == taMax8Low &&
        other.taMax8High == taMax8High &&
        other.taMin9 == taMin9 &&
        other.taMin9Low == taMin9Low &&
        other.taMin9High == taMin9High &&
        other.taMax9 == taMax9 &&
        other.taMax9Low == taMax9Low &&
        other.taMax9High == taMax9High &&
        other.taMin10 == taMin10 &&
        other.taMin10Low == taMin10Low &&
        other.taMin10High == taMin10High &&
        other.taMax10 == taMax10 &&
        other.taMax10Low == taMax10Low &&
        other.taMax10High == taMax10High;
  }

  @override
  int get hashCode {
    return regId.hashCode ^
        taMin4.hashCode ^
        taMin4Low.hashCode ^
        taMin4High.hashCode ^
        taMax4.hashCode ^
        taMax4Low.hashCode ^
        taMax4High.hashCode ^
        taMin5.hashCode ^
        taMin5Low.hashCode ^
        taMin5High.hashCode ^
        taMax5.hashCode ^
        taMax5Low.hashCode ^
        taMax5High.hashCode ^
        taMin6.hashCode ^
        taMin6Low.hashCode ^
        taMin6High.hashCode ^
        taMax6.hashCode ^
        taMax6Low.hashCode ^
        taMax6High.hashCode ^
        taMin7.hashCode ^
        taMin7Low.hashCode ^
        taMin7High.hashCode ^
        taMax7.hashCode ^
        taMax7Low.hashCode ^
        taMax7High.hashCode ^
        taMin8.hashCode ^
        taMin8Low.hashCode ^
        taMin8High.hashCode ^
        taMax8.hashCode ^
        taMax8Low.hashCode ^
        taMax8High.hashCode ^
        taMin9.hashCode ^
        taMin9Low.hashCode ^
        taMin9High.hashCode ^
        taMax9.hashCode ^
        taMax9Low.hashCode ^
        taMax9High.hashCode ^
        taMin10.hashCode ^
        taMin10Low.hashCode ^
        taMin10High.hashCode ^
        taMax10.hashCode ^
        taMax10Low.hashCode ^
        taMax10High.hashCode;
  }
}
