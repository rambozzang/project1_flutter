// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ChallengeCompleteData {
  String? completeYn;
  int? consecutiveDays;
  String? message;

  ChallengeCompleteData({
    this.completeYn,
    this.consecutiveDays,
    this.message,
  });

  ChallengeCompleteData copyWith({
    String? completeYn,
    int? consecutiveDays,
    String? message,
  }) {
    return ChallengeCompleteData(
      completeYn: completeYn ?? this.completeYn,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completeYn': completeYn,
      'consecutiveDays': consecutiveDays,
      'message': message,
    };
  }

  factory ChallengeCompleteData.fromMap(Map<String, dynamic> map) {
    return ChallengeCompleteData(
      completeYn: map['completeYn'] != null ? map['completeYn'] as String : null,
      consecutiveDays: map['consecutiveDays'] != null ? (map['consecutiveDays'] as num).toInt() : null,
      message: map['message'] != null ? map['message'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChallengeCompleteData.fromJson(String source) =>
      ChallengeCompleteData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ChallengeCompleteData(completeYn: $completeYn, consecutiveDays: $consecutiveDays, message: $message)';
}
