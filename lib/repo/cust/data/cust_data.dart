// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CustData {
  String? custId;
  String? nickNm;
  String? custNm;
  String? selfIntro;
  String? selfId;
  String? email;
  String? hpNo;
  String? birthday;
  String? fcmId;
  String? provider;
  String? profilePath;
  String? accessToken;
  CustData({
    this.custId,
    this.nickNm,
    this.custNm,
    this.selfIntro,
    this.selfId,
    this.email,
    this.hpNo,
    this.birthday,
    this.fcmId,
    this.provider,
    this.profilePath,
    this.accessToken,
  });

  CustData copyWith({
    String? custId,
    String? nickNm,
    String? custNm,
    String? selfIntro,
    String? selfId,
    String? email,
    String? hpNo,
    String? birthday,
    String? fcmId,
    String? provider,
    String? profilePath,
    String? accessToken,
  }) {
    return CustData(
      custId: custId ?? this.custId,
      nickNm: nickNm ?? this.nickNm,
      custNm: custNm ?? this.custNm,
      selfIntro: selfIntro ?? this.selfIntro,
      selfId: selfId ?? this.selfId,
      email: email ?? this.email,
      hpNo: hpNo ?? this.hpNo,
      birthday: birthday ?? this.birthday,
      fcmId: fcmId ?? this.fcmId,
      provider: provider ?? this.provider,
      profilePath: profilePath ?? this.profilePath,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'custId': custId,
      'nickNm': nickNm,
      'custNm': custNm,
      'selfIntro': selfIntro,
      'selfId': selfId,
      'email': email,
      'hpNo': hpNo,
      'birthday': birthday,
      'fcmId': fcmId,
      'provider': provider,
      'profilePath': profilePath,
      'accessToken': accessToken,
    };
  }

  factory CustData.fromMap(Map<String, dynamic> map) {
    return CustData(
      custId: map['custId'] != null ? map['custId'] as String : null,
      nickNm: map['nickNm'] != null ? map['nickNm'] as String : null,
      custNm: map['custNm'] != null ? map['custNm'] as String : null,
      selfIntro: map['selfIntro'] != null ? map['selfIntro'] as String : null,
      selfId: map['selfId'] != null ? map['selfId'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      hpNo: map['hpNo'] != null ? map['hpNo'] as String : null,
      birthday: map['birthday'] != null ? map['birthday'] as String : null,
      fcmId: map['fcmId'] != null ? map['fcmId'] as String : null,
      provider: map['provider'] != null ? map['provider'] as String : null,
      profilePath: map['profilePath'] != null ? map['profilePath'] as String : null,
      accessToken: map['accessToken'] != null ? map['accessToken'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustData.fromJson(String source) => CustData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CustData(custId: $custId, nickNm: $nickNm, custNm: $custNm, selfIntro: $selfIntro, selfId: $selfId, email: $email, hpNo: $hpNo, birthday: $birthday, fcmId: $fcmId, provider: $provider, profilePath: $profilePath, accessToken: $accessToken)';
  }

  @override
  bool operator ==(covariant CustData other) {
    if (identical(this, other)) return true;

    return other.custId == custId &&
        other.nickNm == nickNm &&
        other.custNm == custNm &&
        other.selfIntro == selfIntro &&
        other.selfId == selfId &&
        other.email == email &&
        other.hpNo == hpNo &&
        other.birthday == birthday &&
        other.fcmId == fcmId &&
        other.provider == provider &&
        other.profilePath == profilePath &&
        other.accessToken == accessToken;
  }

  @override
  int get hashCode {
    return custId.hashCode ^
        nickNm.hashCode ^
        custNm.hashCode ^
        selfIntro.hashCode ^
        selfId.hashCode ^
        email.hashCode ^
        hpNo.hashCode ^
        birthday.hashCode ^
        fcmId.hashCode ^
        provider.hashCode ^
        profilePath.hashCode ^
        accessToken.hashCode;
  }
}
