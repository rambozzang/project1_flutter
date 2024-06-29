// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

// 미세먼지 단위 ㎍/㎥
class MistViewData {
  String? mist10;
  String? mist10Grade;
  String? mist25;
  String? mist25Grade;
  MistViewData({
    this.mist10,
    this.mist10Grade,
    this.mist25,
    this.mist25Grade,
  });

  MistViewData copyWith({
    String? mist10,
    String? mist10Grade,
    String? mist25,
    String? mist25Grade,
  }) {
    return MistViewData(
      mist10: mist10 ?? this.mist10,
      mist10Grade: mist10Grade ?? this.mist10Grade,
      mist25: mist25 ?? this.mist25,
      mist25Grade: mist25Grade ?? this.mist25Grade,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mist10': mist10,
      'mist10Grade': mist10Grade,
      'mist25': mist25,
      'mist25Grade': mist25Grade,
    };
  }

  factory MistViewData.fromMap(Map<String, dynamic> map) {
    return MistViewData(
      mist10: map['mist10'] != null ? map['mist10'] as String : null,
      mist10Grade: map['mist10Grade'] != null ? map['mist10Grade'] as String : null,
      mist25: map['mist25'] != null ? map['mist25'] as String : null,
      mist25Grade: map['mist25Grade'] != null ? map['mist25Grade'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MistViewData.fromJson(String source) => MistViewData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MistViewData(mist10: $mist10, mist10Grade: $mist10Grade, mist25: $mist25, mist25Grade: $mist25Grade)';
  }

  @override
  bool operator ==(covariant MistViewData other) {
    if (identical(this, other)) return true;

    return other.mist10 == mist10 && other.mist10Grade == mist10Grade && other.mist25 == mist25 && other.mist25Grade == mist25Grade;
  }

  @override
  int get hashCode {
    return mist10.hashCode ^ mist10Grade.hashCode ^ mist25.hashCode ^ mist25Grade.hashCode;
  }
}
