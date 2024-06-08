// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

// key=sVI6l9pfWdIclwcZP3Go7orBQKYcp2jKs3AtbfXuAOsQOZ3bZmgpdQ9AJ0AM4fEfmJKYyLlSmhLFLWRRrIwg
// cctvid=L933103
// cctvName=강원 강릉 주민진방파제
// kind=KB
// cctvip=9995
// cctvch=null
// id=null
// cctvpasswd=null
// cctvport=null

class CctvSeoulViewData {
  String? key;
  String? cctvid;
  String? cctvName;
  String? kind;
  String? cctvip;
  String? cctvch;
  String? id;
  String? cctvpasswd;
  CctvSeoulViewData({
    this.key,
    this.cctvid,
    this.cctvName,
    this.kind,
    this.cctvip,
    this.cctvch,
    this.id,
    this.cctvpasswd,
  });

  CctvSeoulViewData copyWith({
    String? key,
    String? cctvid,
    String? cctvName,
    String? kind,
    String? cctvip,
    String? cctvch,
    String? id,
    String? cctvpasswd,
  }) {
    return CctvSeoulViewData(
      key: key ?? this.key,
      cctvid: cctvid ?? this.cctvid,
      cctvName: cctvName ?? this.cctvName,
      kind: kind ?? this.kind,
      cctvip: cctvip ?? this.cctvip,
      cctvch: cctvch ?? this.cctvch,
      id: id ?? this.id,
      cctvpasswd: cctvpasswd ?? this.cctvpasswd,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'cctvid': cctvid,
      'cctvName': cctvName,
      'kind': kind,
      'cctvip': cctvip,
      'cctvch': cctvch,
      'id': id,
      'cctvpasswd': cctvpasswd,
    };
  }

  factory CctvSeoulViewData.fromMap(Map<String, dynamic> map) {
    return CctvSeoulViewData(
      key: map['key'] != null ? map['key'] as String : null,
      cctvid: map['cctvid'] != null ? map['cctvid'] as String : null,
      cctvName: map['cctvName'] != null ? map['cctvName'] as String : null,
      kind: map['kind'] != null ? map['kind'] as String : null,
      cctvip: map['cctvip'] != null ? map['cctvip'] as String : null,
      cctvch: map['cctvch'] != null ? map['cctvch'] as String : null,
      id: map['id'] != null ? map['id'] as String : null,
      cctvpasswd: map['cctvpasswd'] != null ? map['cctvpasswd'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CctvSeoulViewData.fromJson(String source) => CctvSeoulViewData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CctvSeoulViewData(key: $key, cctvid: $cctvid, cctvName: $cctvName, kind: $kind, cctvip: $cctvip, cctvch: $cctvch, id: $id, cctvpasswd: $cctvpasswd)';
  }

  @override
  bool operator ==(covariant CctvSeoulViewData other) {
    if (identical(this, other)) return true;

    return other.key == key &&
        other.cctvid == cctvid &&
        other.cctvName == cctvName &&
        other.kind == kind &&
        other.cctvip == cctvip &&
        other.cctvch == cctvch &&
        other.id == id &&
        other.cctvpasswd == cctvpasswd;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        cctvid.hashCode ^
        cctvName.hashCode ^
        kind.hashCode ^
        cctvip.hashCode ^
        cctvch.hashCode ^
        id.hashCode ^
        cctvpasswd.hashCode;
  }
}
