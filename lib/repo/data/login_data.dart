// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class LoginRes {
  String? custId;
  String? nickNm;
  String? custNm;
  String? email;
  String? hpNo;
  String? birthday;
  String? fcmId;
  String? provider;
  String? profilePath;
  String? accessToken;
  String? refreshToken;
  LoginRes({
    this.custId,
    this.nickNm,
    this.custNm,
    this.email,
    this.hpNo,
    this.birthday,
    this.fcmId,
    this.provider,
    this.profilePath,
    this.accessToken,
    this.refreshToken,
  });

  LoginRes copyWith({
    String? custId,
    String? nickNm,
    String? custNm,
    String? email,
    String? hpNo,
    String? birthday,
    String? fcmId,
    String? provider,
    String? profilePath,
    String? accessToken,
    String? refreshToken,
  }) {
    return LoginRes(
      custId: custId ?? this.custId,
      nickNm: nickNm ?? this.nickNm,
      custNm: custNm ?? this.custNm,
      email: email ?? this.email,
      hpNo: hpNo ?? this.hpNo,
      birthday: birthday ?? this.birthday,
      fcmId: fcmId ?? this.fcmId,
      provider: provider ?? this.provider,
      profilePath: profilePath ?? this.profilePath,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'custId': custId,
      'nickNm': nickNm,
      'custNm': custNm,
      'email': email,
      'hpNo': hpNo,
      'birthday': birthday,
      'fcmId': fcmId,
      'provider': provider,
      'profilePath': profilePath,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  factory LoginRes.fromMap(Map<String, dynamic> map) {
    return LoginRes(
      custId: map['custId'] != null ? map['custId'] as String : null,
      nickNm: map['nickNm'] != null ? map['nickNm'] as String : null,
      custNm: map['custNm'] != null ? map['custNm'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      hpNo: map['hpNo'] != null ? map['hpNo'] as String : null,
      birthday: map['birthday'] != null ? map['birthday'] as String : null,
      fcmId: map['fcmId'] != null ? map['fcmId'] as String : null,
      provider: map['provider'] != null ? map['provider'] as String : null,
      profilePath:
          map['profilePath'] != null ? map['profilePath'] as String : null,
      accessToken:
          map['accessToken'] != null ? map['accessToken'] as String : null,
      refreshToken:
          map['refreshToken'] != null ? map['refreshToken'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LoginRes.fromJson(String source) =>
      LoginRes.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LoginRes(custId: $custId, nickNm: $nickNm, custNm: $custNm, email: $email, hpNo: $hpNo, birthday: $birthday, fcmId: $fcmId, provider: $provider, profilePath: $profilePath, accessToken: $accessToken, refreshToken: $refreshToken)';
  }

  @override
  bool operator ==(covariant LoginRes other) {
    if (identical(this, other)) return true;

    return other.custId == custId &&
        other.nickNm == nickNm &&
        other.custNm == custNm &&
        other.email == email &&
        other.hpNo == hpNo &&
        other.birthday == birthday &&
        other.fcmId == fcmId &&
        other.provider == provider &&
        other.profilePath == profilePath &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode {
    return custId.hashCode ^
        nickNm.hashCode ^
        custNm.hashCode ^
        email.hashCode ^
        hpNo.hashCode ^
        birthday.hashCode ^
        fcmId.hashCode ^
        provider.hashCode ^
        profilePath.hashCode ^
        accessToken.hashCode ^
        refreshToken.hashCode;
  }
}
