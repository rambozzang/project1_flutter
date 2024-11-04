// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class WeatherAlertRes {
  String? stnId;
  String? title;
  int? tmFc;
  int? tmSeq;
  WeatherAlertRes({
    this.stnId,
    this.title,
    this.tmFc,
    this.tmSeq,
  });

  WeatherAlertRes copyWith({
    String? stnId,
    String? title,
    int? tmFc,
    int? tmSeq,
  }) {
    return WeatherAlertRes(
      stnId: stnId ?? this.stnId,
      title: title ?? this.title,
      tmFc: tmFc ?? this.tmFc,
      tmSeq: tmSeq ?? this.tmSeq,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'stnId': stnId,
      'title': title,
      'tmFc': tmFc,
      'tmSeq': tmSeq,
    };
  }

  factory WeatherAlertRes.fromMap(Map<String, dynamic> map) {
    return WeatherAlertRes(
      stnId: map['stnId'] != null ? map['stnId'] as String : null,
      title: map['title'] != null ? map['title'] as String : null,
      tmFc: map['tmFc'] != null ? map['tmFc'] as int : null,
      tmSeq: map['tmSeq'] != null ? map['tmSeq'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WeatherAlertRes.fromJson(String source) => WeatherAlertRes.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WeatherAlertRes(stnId: $stnId, title: $title, tmFc: $tmFc, tmSeq: $tmSeq)';
  }

  @override
  bool operator ==(covariant WeatherAlertRes other) {
    if (identical(this, other)) return true;

    return other.stnId == stnId && other.title == title && other.tmFc == tmFc && other.tmSeq == tmSeq;
  }

  @override
  int get hashCode {
    return stnId.hashCode ^ title.hashCode ^ tmFc.hashCode ^ tmSeq.hashCode;
  }
}
