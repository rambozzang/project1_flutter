// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class MidLandFcstResponse {
  final String regId;
  // 4일차는 발표 시각에 따라 값이 비어 올 수 있어 nullable 로 둔다(5일차 이상은 기존처럼 필수).
  final int? rnSt4Am;
  final int? rnSt4Pm;
  final int rnSt5Am;
  final int rnSt5Pm;
  final int rnSt6Am;
  final int rnSt6Pm;
  final int rnSt7Am;
  final int rnSt7Pm;
  final int rnSt8;
  final int rnSt9;
  final int rnSt10;
  final String? wf4Am;
  final String? wf4Pm;
  final String wf5Am;
  final String wf5Pm;
  final String wf6Am;
  final String wf6Pm;
  final String wf7Am;
  final String wf7Pm;
  final String wf8;
  final String wf9;
  final String wf10;
  MidLandFcstResponse({
    required this.regId,
    this.rnSt4Am,
    this.rnSt4Pm,
    required this.rnSt5Am,
    required this.rnSt5Pm,
    required this.rnSt6Am,
    required this.rnSt6Pm,
    required this.rnSt7Am,
    required this.rnSt7Pm,
    required this.rnSt8,
    required this.rnSt9,
    required this.rnSt10,
    this.wf4Am,
    this.wf4Pm,
    required this.wf5Am,
    required this.wf5Pm,
    required this.wf6Am,
    required this.wf6Pm,
    required this.wf7Am,
    required this.wf7Pm,
    required this.wf8,
    required this.wf9,
    required this.wf10,
  });

  MidLandFcstResponse copyWith({
    String? regId,
    int? rnSt4Am,
    int? rnSt4Pm,
    int? rnSt5Am,
    int? rnSt5Pm,
    int? rnSt6Am,
    int? rnSt6Pm,
    int? rnSt7Am,
    int? rnSt7Pm,
    int? rnSt8,
    int? rnSt9,
    int? rnSt10,
    String? wf4Am,
    String? wf4Pm,
    String? wf5Am,
    String? wf5Pm,
    String? wf6Am,
    String? wf6Pm,
    String? wf7Am,
    String? wf7Pm,
    String? wf8,
    String? wf9,
    String? wf10,
  }) {
    return MidLandFcstResponse(
      regId: regId ?? this.regId,
      rnSt4Am: rnSt4Am ?? this.rnSt4Am,
      rnSt4Pm: rnSt4Pm ?? this.rnSt4Pm,
      rnSt5Am: rnSt5Am ?? this.rnSt5Am,
      rnSt5Pm: rnSt5Pm ?? this.rnSt5Pm,
      rnSt6Am: rnSt6Am ?? this.rnSt6Am,
      rnSt6Pm: rnSt6Pm ?? this.rnSt6Pm,
      rnSt7Am: rnSt7Am ?? this.rnSt7Am,
      rnSt7Pm: rnSt7Pm ?? this.rnSt7Pm,
      rnSt8: rnSt8 ?? this.rnSt8,
      rnSt9: rnSt9 ?? this.rnSt9,
      rnSt10: rnSt10 ?? this.rnSt10,
      wf4Am: wf4Am ?? this.wf4Am,
      wf4Pm: wf4Pm ?? this.wf4Pm,
      wf5Am: wf5Am ?? this.wf5Am,
      wf5Pm: wf5Pm ?? this.wf5Pm,
      wf6Am: wf6Am ?? this.wf6Am,
      wf6Pm: wf6Pm ?? this.wf6Pm,
      wf7Am: wf7Am ?? this.wf7Am,
      wf7Pm: wf7Pm ?? this.wf7Pm,
      wf8: wf8 ?? this.wf8,
      wf9: wf9 ?? this.wf9,
      wf10: wf10 ?? this.wf10,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'regId': regId,
      'rnSt4Am': rnSt4Am,
      'rnSt4Pm': rnSt4Pm,
      'rnSt5Am': rnSt5Am,
      'rnSt5Pm': rnSt5Pm,
      'rnSt6Am': rnSt6Am,
      'rnSt6Pm': rnSt6Pm,
      'rnSt7Am': rnSt7Am,
      'rnSt7Pm': rnSt7Pm,
      'rnSt8': rnSt8,
      'rnSt9': rnSt9,
      'rnSt10': rnSt10,
      'wf4Am': wf4Am,
      'wf4Pm': wf4Pm,
      'wf5Am': wf5Am,
      'wf5Pm': wf5Pm,
      'wf6Am': wf6Am,
      'wf6Pm': wf6Pm,
      'wf7Am': wf7Am,
      'wf7Pm': wf7Pm,
      'wf8': wf8,
      'wf9': wf9,
      'wf10': wf10,
    };
  }

  factory MidLandFcstResponse.fromMap(Map<String, dynamic> map) {
    return MidLandFcstResponse(
      regId: map['regId'] as String,
      rnSt4Am: map['rnSt4Am'] as int?,
      rnSt4Pm: map['rnSt4Pm'] as int?,
      rnSt5Am: map['rnSt5Am'] as int,
      rnSt5Pm: map['rnSt5Pm'] as int,
      rnSt6Am: map['rnSt6Am'] as int,
      rnSt6Pm: map['rnSt6Pm'] as int,
      rnSt7Am: map['rnSt7Am'] as int,
      rnSt7Pm: map['rnSt7Pm'] as int,
      rnSt8: map['rnSt8'] as int,
      rnSt9: map['rnSt9'] as int,
      rnSt10: map['rnSt10'] as int,
      wf4Am: map['wf4Am'] as String?,
      wf4Pm: map['wf4Pm'] as String?,
      wf5Am: map['wf5Am'] as String,
      wf5Pm: map['wf5Pm'] as String,
      wf6Am: map['wf6Am'] as String,
      wf6Pm: map['wf6Pm'] as String,
      wf7Am: map['wf7Am'] as String,
      wf7Pm: map['wf7Pm'] as String,
      wf8: map['wf8'] as String,
      wf9: map['wf9'] as String,
      wf10: map['wf10'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory MidLandFcstResponse.fromJson(String source) => MidLandFcstResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MidLandFcstResponse(regId: $regId, rnSt4Am: $rnSt4Am, rnSt4Pm: $rnSt4Pm, rnSt5Am: $rnSt5Am, rnSt5Pm: $rnSt5Pm, rnSt6Am: $rnSt6Am, rnSt6Pm: $rnSt6Pm, rnSt7Am: $rnSt7Am, rnSt7Pm: $rnSt7Pm, rnSt8: $rnSt8, rnSt9: $rnSt9, rnSt10: $rnSt10, wf4Am: $wf4Am, wf4Pm: $wf4Pm, wf5Am: $wf5Am, wf5Pm: $wf5Pm, wf6Am: $wf6Am, wf6Pm: $wf6Pm, wf7Am: $wf7Am, wf7Pm: $wf7Pm, wf8: $wf8, wf9: $wf9, wf10: $wf10)';
  }

  @override
  bool operator ==(covariant MidLandFcstResponse other) {
    if (identical(this, other)) return true;

    return other.regId == regId &&
        other.rnSt4Am == rnSt4Am &&
        other.rnSt4Pm == rnSt4Pm &&
        other.rnSt5Am == rnSt5Am &&
        other.rnSt5Pm == rnSt5Pm &&
        other.rnSt6Am == rnSt6Am &&
        other.rnSt6Pm == rnSt6Pm &&
        other.rnSt7Am == rnSt7Am &&
        other.rnSt7Pm == rnSt7Pm &&
        other.rnSt8 == rnSt8 &&
        other.rnSt9 == rnSt9 &&
        other.rnSt10 == rnSt10 &&
        other.wf4Am == wf4Am &&
        other.wf4Pm == wf4Pm &&
        other.wf5Am == wf5Am &&
        other.wf5Pm == wf5Pm &&
        other.wf6Am == wf6Am &&
        other.wf6Pm == wf6Pm &&
        other.wf7Am == wf7Am &&
        other.wf7Pm == wf7Pm &&
        other.wf8 == wf8 &&
        other.wf9 == wf9 &&
        other.wf10 == wf10;
  }

  @override
  int get hashCode {
    return regId.hashCode ^
        rnSt4Am.hashCode ^
        rnSt4Pm.hashCode ^
        rnSt5Am.hashCode ^
        rnSt5Pm.hashCode ^
        rnSt6Am.hashCode ^
        rnSt6Pm.hashCode ^
        rnSt7Am.hashCode ^
        rnSt7Pm.hashCode ^
        rnSt8.hashCode ^
        rnSt9.hashCode ^
        rnSt10.hashCode ^
        wf4Am.hashCode ^
        wf4Pm.hashCode ^
        wf5Am.hashCode ^
        wf5Pm.hashCode ^
        wf6Am.hashCode ^
        wf6Pm.hashCode ^
        wf7Am.hashCode ^
        wf7Pm.hashCode ^
        wf8.hashCode ^
        wf9.hashCode ^
        wf10.hashCode;
  }
}
// Response Data Class
// class MidLandFcstResponse {
//   final String regId;
//   final int rnSt3Am;
//   final int rnSt3Pm;
//   final int rnSt4Am;
//   final int rnSt4Pm;
//   final int rnSt5Am;
//   final int rnSt5Pm;
//   final int rnSt6Am;
//   final int rnSt6Pm;
//   final int rnSt7Am;
//   final int rnSt7Pm;
//   final String wf3Am;
//   final String wf3Pm;
//   final String wf4Am;
//   final String wf4Pm;
//   final String wf5Am;
//   final String wf5Pm;
//   final String wf6Am;
//   final String wf6Pm;
//   final String wf7Am;
//   final String wf7Pm;
//   MidLandFcstResponse({
//     required this.regId,
//     required this.rnSt3Am,
//     required this.rnSt3Pm,
//     required this.rnSt4Am,
//     required this.rnSt4Pm,
//     required this.rnSt5Am,
//     required this.rnSt5Pm,
//     required this.rnSt6Am,
//     required this.rnSt6Pm,
//     required this.rnSt7Am,
//     required this.rnSt7Pm,
//     required this.wf3Am,
//     required this.wf3Pm,
//     required this.wf4Am,
//     required this.wf4Pm,
//     required this.wf5Am,
//     required this.wf5Pm,
//     required this.wf6Am,
//     required this.wf6Pm,
//     required this.wf7Am,
//     required this.wf7Pm,
//   });

//   MidLandFcstResponse copyWith({
//     String? regId,
//     int? rnSt3Am,
//     int? rnSt3Pm,
//     int? rnSt4Am,
//     int? rnSt4Pm,
//     int? rnSt5Am,
//     int? rnSt5Pm,
//     int? rnSt6Am,
//     int? rnSt6Pm,
//     int? rnSt7Am,
//     int? rnSt7Pm,
//     String? wf3Am,
//     String? wf3Pm,
//     String? wf4Am,
//     String? wf4Pm,
//     String? wf5Am,
//     String? wf5Pm,
//     String? wf6Am,
//     String? wf6Pm,
//     String? wf7Am,
//     String? wf7Pm,
//   }) {
//     return MidLandFcstResponse(
//       regId: regId ?? this.regId,
//       rnSt3Am: rnSt3Am ?? this.rnSt3Am,
//       rnSt3Pm: rnSt3Pm ?? this.rnSt3Pm,
//       rnSt4Am: rnSt4Am ?? this.rnSt4Am,
//       rnSt4Pm: rnSt4Pm ?? this.rnSt4Pm,
//       rnSt5Am: rnSt5Am ?? this.rnSt5Am,
//       rnSt5Pm: rnSt5Pm ?? this.rnSt5Pm,
//       rnSt6Am: rnSt6Am ?? this.rnSt6Am,
//       rnSt6Pm: rnSt6Pm ?? this.rnSt6Pm,
//       rnSt7Am: rnSt7Am ?? this.rnSt7Am,
//       rnSt7Pm: rnSt7Pm ?? this.rnSt7Pm,
//       wf3Am: wf3Am ?? this.wf3Am,
//       wf3Pm: wf3Pm ?? this.wf3Pm,
//       wf4Am: wf4Am ?? this.wf4Am,
//       wf4Pm: wf4Pm ?? this.wf4Pm,
//       wf5Am: wf5Am ?? this.wf5Am,
//       wf5Pm: wf5Pm ?? this.wf5Pm,
//       wf6Am: wf6Am ?? this.wf6Am,
//       wf6Pm: wf6Pm ?? this.wf6Pm,
//       wf7Am: wf7Am ?? this.wf7Am,
//       wf7Pm: wf7Pm ?? this.wf7Pm,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'regId': regId,
//       'rnSt3Am': rnSt3Am,
//       'rnSt3Pm': rnSt3Pm,
//       'rnSt4Am': rnSt4Am,
//       'rnSt4Pm': rnSt4Pm,
//       'rnSt5Am': rnSt5Am,
//       'rnSt5Pm': rnSt5Pm,
//       'rnSt6Am': rnSt6Am,
//       'rnSt6Pm': rnSt6Pm,
//       'rnSt7Am': rnSt7Am,
//       'rnSt7Pm': rnSt7Pm,
//       'wf3Am': wf3Am,
//       'wf3Pm': wf3Pm,
//       'wf4Am': wf4Am,
//       'wf4Pm': wf4Pm,
//       'wf5Am': wf5Am,
//       'wf5Pm': wf5Pm,
//       'wf6Am': wf6Am,
//       'wf6Pm': wf6Pm,
//       'wf7Am': wf7Am,
//       'wf7Pm': wf7Pm,
//     };
//   }

//   factory MidLandFcstResponse.fromMap(Map<String, dynamic> map) {
//     return MidLandFcstResponse(
//       regId: map['regId'] as String,
//       rnSt3Am: map['rnSt3Am'] as int,
//       rnSt3Pm: map['rnSt3Pm'] as int,
//       rnSt4Am: map['rnSt4Am'] as int,
//       rnSt4Pm: map['rnSt4Pm'] as int,
//       rnSt5Am: map['rnSt5Am'] as int,
//       rnSt5Pm: map['rnSt5Pm'] as int,
//       rnSt6Am: map['rnSt6Am'] as int,
//       rnSt6Pm: map['rnSt6Pm'] as int,
//       rnSt7Am: map['rnSt7Am'] as int,
//       rnSt7Pm: map['rnSt7Pm'] as int,
//       wf3Am: map['wf3Am'] as String,
//       wf3Pm: map['wf3Pm'] as String,
//       wf4Am: map['wf4Am'] as String,
//       wf4Pm: map['wf4Pm'] as String,
//       wf5Am: map['wf5Am'] as String,
//       wf5Pm: map['wf5Pm'] as String,
//       wf6Am: map['wf6Am'] as String,
//       wf6Pm: map['wf6Pm'] as String,
//       wf7Am: map['wf7Am'] as String,
//       wf7Pm: map['wf7Pm'] as String,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory MidLandFcstResponse.fromJson(String source) => MidLandFcstResponse.fromMap(json.decode(source) as Map<String, dynamic>);

//   @override
//   String toString() {
//     return 'MidLandFcstResponse(regId: $regId, rnSt3Am: $rnSt3Am, rnSt3Pm: $rnSt3Pm, rnSt4Am: $rnSt4Am, rnSt4Pm: $rnSt4Pm, rnSt5Am: $rnSt5Am, rnSt5Pm: $rnSt5Pm, rnSt6Am: $rnSt6Am, rnSt6Pm: $rnSt6Pm, rnSt7Am: $rnSt7Am, rnSt7Pm: $rnSt7Pm, wf3Am: $wf3Am, wf3Pm: $wf3Pm, wf4Am: $wf4Am, wf4Pm: $wf4Pm, wf5Am: $wf5Am, wf5Pm: $wf5Pm, wf6Am: $wf6Am, wf6Pm: $wf6Pm, wf7Am: $wf7Am, wf7Pm: $wf7Pm)';
//   }

//   @override
//   bool operator ==(covariant MidLandFcstResponse other) {
//     if (identical(this, other)) return true;

//     return other.regId == regId &&
//         other.rnSt3Am == rnSt3Am &&
//         other.rnSt3Pm == rnSt3Pm &&
//         other.rnSt4Am == rnSt4Am &&
//         other.rnSt4Pm == rnSt4Pm &&
//         other.rnSt5Am == rnSt5Am &&
//         other.rnSt5Pm == rnSt5Pm &&
//         other.rnSt6Am == rnSt6Am &&
//         other.rnSt6Pm == rnSt6Pm &&
//         other.rnSt7Am == rnSt7Am &&
//         other.rnSt7Pm == rnSt7Pm &&
//         other.wf3Am == wf3Am &&
//         other.wf3Pm == wf3Pm &&
//         other.wf4Am == wf4Am &&
//         other.wf4Pm == wf4Pm &&
//         other.wf5Am == wf5Am &&
//         other.wf5Pm == wf5Pm &&
//         other.wf6Am == wf6Am &&
//         other.wf6Pm == wf6Pm &&
//         other.wf7Am == wf7Am &&
//         other.wf7Pm == wf7Pm;
//   }

//   @override
//   int get hashCode {
//     return regId.hashCode ^
//         rnSt3Am.hashCode ^
//         rnSt3Pm.hashCode ^
//         rnSt4Am.hashCode ^
//         rnSt4Pm.hashCode ^
//         rnSt5Am.hashCode ^
//         rnSt5Pm.hashCode ^
//         rnSt6Am.hashCode ^
//         rnSt6Pm.hashCode ^
//         rnSt7Am.hashCode ^
//         rnSt7Pm.hashCode ^
//         wf3Am.hashCode ^
//         wf3Pm.hashCode ^
//         wf4Am.hashCode ^
//         wf4Pm.hashCode ^
//         wf5Am.hashCode ^
//         wf5Pm.hashCode ^
//         wf6Am.hashCode ^
//         wf6Pm.hashCode ^
//         wf7Am.hashCode ^
//         wf7Pm.hashCode;
//   }
// }
