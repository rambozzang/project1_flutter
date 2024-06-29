// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AlramDenyData {
  String? denyType;
  String? denyYn;
  String? denyCustId;
  AlramDenyData({
    this.denyType,
    this.denyYn,
    this.denyCustId,
  });

  AlramDenyData copyWith({
    String? denyType,
    String? denyYn,
    String? denyCustId,
  }) {
    return AlramDenyData(
      denyType: denyType ?? this.denyType,
      denyYn: denyYn ?? this.denyYn,
      denyCustId: denyCustId ?? this.denyCustId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'denyType': denyType,
      'denyYn': denyYn,
      'denyCustId': denyCustId,
    };
  }

  factory AlramDenyData.fromMap(Map<String, dynamic> map) {
    return AlramDenyData(
      denyType: map['denyType'] != null ? map['denyType'] as String : null,
      denyYn: map['denyYn'] != null ? map['denyYn'] as String : null,
      denyCustId: map['denyCustId'] != null ? map['denyCustId'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlramDenyData.fromJson(String source) => AlramDenyData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'AlramDenyData(denyType: $denyType, denyYn: $denyYn, denyCustId: $denyCustId)';

  @override
  bool operator ==(covariant AlramDenyData other) {
    if (identical(this, other)) return true;

    return other.denyType == denyType && other.denyYn == denyYn && other.denyCustId == denyCustId;
  }

  @override
  int get hashCode => denyType.hashCode ^ denyYn.hashCode ^ denyCustId.hashCode;
}
