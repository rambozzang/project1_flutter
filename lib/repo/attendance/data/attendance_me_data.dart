// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AttendanceMeData {
  int? consecutiveDays;
  int? monthCount;
  List<DateTime>? attendanceDates;

  AttendanceMeData({
    this.consecutiveDays,
    this.monthCount,
    this.attendanceDates,
  });

  AttendanceMeData copyWith({
    int? consecutiveDays,
    int? monthCount,
    List<DateTime>? attendanceDates,
  }) {
    return AttendanceMeData(
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      monthCount: monthCount ?? this.monthCount,
      attendanceDates: attendanceDates ?? this.attendanceDates,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'consecutiveDays': consecutiveDays,
      'monthCount': monthCount,
      'attendanceDates': attendanceDates?.map((x) => x.toIso8601String()).toList(),
    };
  }

  factory AttendanceMeData.fromMap(Map<String, dynamic> map) {
    return AttendanceMeData(
      consecutiveDays: map['consecutiveDays'] != null ? (map['consecutiveDays'] as num).toInt() : null,
      monthCount: map['monthCount'] != null ? (map['monthCount'] as num).toInt() : null,
      attendanceDates: map['attendanceDates'] != null
          ? List<DateTime>.from(
              (map['attendanceDates'] as List<dynamic>).map(
                (x) => DateTime.tryParse(x.toString()) ?? DateTime.now(),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceMeData.fromJson(String source) =>
      AttendanceMeData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'AttendanceMeData(consecutiveDays: $consecutiveDays, monthCount: $monthCount)';
}
