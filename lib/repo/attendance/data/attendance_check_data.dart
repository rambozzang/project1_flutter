// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AttendanceCheckData {
  bool? checked;
  DateTime? attendanceDate;
  int? consecutiveDays;
  int? monthCount;
  String? message;

  AttendanceCheckData({
    this.checked,
    this.attendanceDate,
    this.consecutiveDays,
    this.monthCount,
    this.message,
  });

  AttendanceCheckData copyWith({
    bool? checked,
    DateTime? attendanceDate,
    int? consecutiveDays,
    int? monthCount,
    String? message,
  }) {
    return AttendanceCheckData(
      checked: checked ?? this.checked,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      monthCount: monthCount ?? this.monthCount,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'checked': checked,
      'attendanceDate': attendanceDate?.toIso8601String(),
      'consecutiveDays': consecutiveDays,
      'monthCount': monthCount,
      'message': message,
    };
  }

  factory AttendanceCheckData.fromMap(Map<String, dynamic> map) {
    return AttendanceCheckData(
      checked: map['checked'] != null ? map['checked'] as bool : null,
      attendanceDate: map['attendanceDate'] != null
          ? DateTime.tryParse(map['attendanceDate'].toString())
          : null,
      consecutiveDays: map['consecutiveDays'] != null ? (map['consecutiveDays'] as num).toInt() : null,
      monthCount: map['monthCount'] != null ? (map['monthCount'] as num).toInt() : null,
      message: map['message'] != null ? map['message'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceCheckData.fromJson(String source) =>
      AttendanceCheckData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'AttendanceCheckData(checked: $checked, consecutiveDays: $consecutiveDays, monthCount: $monthCount)';
}
