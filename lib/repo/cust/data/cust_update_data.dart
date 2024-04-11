// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CustUpdataData {
  String? custId;
  String? custNm;
  String? nickNm;
  String? selfIntro;
  String? selfId;
  String? email;
  String? hpNo;
  String? birthday;
  String? profilePath;
  CustUpdataData({
    this.custId,
    this.custNm,
    this.nickNm,
    this.selfIntro,
    this.selfId,
    this.email,
    this.hpNo,
    this.birthday,
    this.profilePath,
  });

  CustUpdataData copyWith({
    String? custId,
    String? custNm,
    String? nickNm,
    String? selfIntro,
    String? selfId,
    String? email,
    String? hpNo,
    String? birthday,
    String? profilePath,
  }) {
    return CustUpdataData(
      custId: custId ?? this.custId,
      custNm: custNm ?? this.custNm,
      nickNm: nickNm ?? this.nickNm,
      selfIntro: selfIntro ?? this.selfIntro,
      selfId: selfId ?? this.selfId,
      email: email ?? this.email,
      hpNo: hpNo ?? this.hpNo,
      birthday: birthday ?? this.birthday,
      profilePath: profilePath ?? this.profilePath,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'custId': custId,
      'custNm': custNm,
      'nickNm': nickNm,
      'selfIntro': selfIntro,
      'selfId': selfId,
      'email': email,
      'hpNo': hpNo,
      'birthday': birthday,
      'profilePath': profilePath,
    };
  }

  factory CustUpdataData.fromMap(Map<String, dynamic> map) {
    return CustUpdataData(
      custId: map['custId'] != null ? map['custId'] as String : null,
      custNm: map['custNm'] != null ? map['custNm'] as String : null,
      nickNm: map['nickNm'] != null ? map['nickNm'] as String : null,
      selfIntro: map['selfIntro'] != null ? map['selfIntro'] as String : null,
      selfId: map['selfId'] != null ? map['selfId'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      hpNo: map['hpNo'] != null ? map['hpNo'] as String : null,
      birthday: map['birthday'] != null ? map['birthday'] as String : null,
      profilePath: map['profilePath'] != null ? map['profilePath'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustUpdataData.fromJson(String source) => CustUpdataData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CustUpdataData(custId: $custId, custNm: $custNm, nickNm: $nickNm, selfIntro: $selfIntro, selfId: $selfId, email: $email, hpNo: $hpNo, birthday: $birthday, profilePath: $profilePath)';
  }

  @override
  bool operator ==(covariant CustUpdataData other) {
    if (identical(this, other)) return true;

    return other.custId == custId &&
        other.custNm == custNm &&
        other.nickNm == nickNm &&
        other.selfIntro == selfIntro &&
        other.selfId == selfId &&
        other.email == email &&
        other.hpNo == hpNo &&
        other.birthday == birthday &&
        other.profilePath == profilePath;
  }

  @override
  int get hashCode {
    return custId.hashCode ^
        custNm.hashCode ^
        nickNm.hashCode ^
        selfIntro.hashCode ^
        selfId.hashCode ^
        email.hashCode ^
        hpNo.hashCode ^
        birthday.hashCode ^
        profilePath.hashCode;
  }
}
