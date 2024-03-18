import 'dart:convert';

class LoginRes {
  String? membNo;
  String? membNm;
  String? reptMembNo;
  String? reptMembNm;
  String? bizNo;
  String? officeNm;
  String? profileImgPath;
  String? accessToken;
  String? refreshToken;
  String? resCd;
  String? hpNo;
  String? birthDt;
  String? sexCd;
  String? gradeCd;
  String? permCd;
  String? firstLoginYn;

  LoginRes({
    this.membNo,
    this.membNm,
    this.reptMembNo,
    this.reptMembNm,
    this.bizNo,
    this.officeNm,
    this.profileImgPath,
    this.accessToken,
    this.refreshToken,
    this.resCd,
    this.hpNo,
    this.birthDt,
    this.sexCd,
    this.gradeCd,
    this.permCd,
    this.firstLoginYn,
  });

  LoginRes copyWith({
    String? membNo,
    String? membNm,
    String? reptMembNo,
    String? reptMembNm,
    String? bizNo,
    String? officeNm,
    String? profileImgPath,
    String? accessToken,
    String? refreshToken,
    String? resCd,
    String? hpNo,
    String? birthDt,
    String? sexCd,
    String? gradeCd,
    String? permCd,
    String? firstLoginYn,
  }) {
    return LoginRes(
      membNo: membNo ?? this.membNo,
      membNm: membNm ?? this.membNm,
      reptMembNo: reptMembNo ?? this.reptMembNo,
      reptMembNm: reptMembNm ?? this.reptMembNm,
      bizNo: bizNo ?? this.bizNo,
      officeNm: officeNm ?? this.officeNm,
      profileImgPath: profileImgPath ?? this.profileImgPath,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      resCd: resCd ?? this.resCd,
      hpNo: hpNo ?? this.hpNo,
      birthDt: birthDt ?? this.birthDt,
      sexCd: sexCd ?? this.sexCd,
      gradeCd: gradeCd ?? this.gradeCd,
      permCd: permCd ?? this.permCd,
      firstLoginYn: firstLoginYn ?? this.firstLoginYn,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'membNo': membNo,
      'membNm': membNm,
      'reptMembNo': reptMembNo,
      'reptMembNm': reptMembNm,
      'bizNo': bizNo,
      'officeNm': officeNm,
      'profileImgPath': profileImgPath,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'resCd': resCd,
      'hpNo': hpNo,
      'birthDt': birthDt,
      'sexCd': sexCd,
      'gradeCd': gradeCd,
      'permCd': permCd,
      'firstLoginYn': firstLoginYn,
    };
  }

  factory LoginRes.fromMap(Map<String, dynamic> map) {
    return LoginRes(
      membNo: map['membNo'] != null ? map['membNo'] as String : null,
      membNm: map['membNm'] != null ? map['membNm'] as String : null,
      reptMembNo:
          map['reptMembNo'] != null ? map['reptMembNo'] as String : null,
      reptMembNm:
          map['reptMembNm'] != null ? map['reptMembNm'] as String : null,
      bizNo: map['bizNo'] != null ? map['bizNo'] as String : null,
      officeNm: map['officeNm'] != null ? map['officeNm'] as String : null,
      profileImgPath: map['profileImgPath'] != null
          ? map['profileImgPath'] as String
          : null,
      accessToken:
          map['accessToken'] != null ? map['accessToken'] as String : null,
      refreshToken:
          map['refreshToken'] != null ? map['refreshToken'] as String : null,
      resCd: map['resCd'] != null ? map['resCd'] as String : null,
      hpNo: map['hpNo'] != null ? map['hpNo'] as String : null,
      birthDt: map['birthDt'] != null ? map['birthDt'] as String : null,
      sexCd: map['sexCd'] != null ? map['sexCd'] as String : null,
      gradeCd: map['gradeCd'] != null ? map['gradeCd'] as String : null,
      permCd: map['permCd'] != null ? map['permCd'] as String : null,
      firstLoginYn: map['firstLoginYn'] != null
          ? map['firstLoginYn'] as String
          : null, // Include in fromMap
    );
  }

  String toJson() => json.encode(toMap());

  factory LoginRes.fromJson(String source) =>
      LoginRes.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ResLoginData(membNo: $membNo, membNm: $membNm, reptMembNo: $reptMembNo, reptMembNm: $reptMembNm, bizNo: $bizNo, officeNm: $officeNm, profileImgPath: $profileImgPath, accessToken: $accessToken, refreshToken: $refreshToken, resCd: $resCd, hpNo: $hpNo, birthDt: $birthDt, sexCd: $sexCd, gradeCd: $gradeCd, permCd: $permCd, firstLoginYn: $firstLoginYn)';
  }

  @override
  bool operator ==(covariant LoginRes other) {
    if (identical(this, other)) return true;

    return other.membNo == membNo &&
        other.membNm == membNm &&
        other.reptMembNo == reptMembNo &&
        other.reptMembNm == reptMembNm &&
        other.bizNo == bizNo &&
        other.officeNm == officeNm &&
        other.profileImgPath == profileImgPath &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.resCd == resCd &&
        other.hpNo == hpNo &&
        other.birthDt == birthDt &&
        other.sexCd == sexCd &&
        other.gradeCd == gradeCd &&
        other.permCd == permCd &&
        other.firstLoginYn == firstLoginYn;
  }

  @override
  int get hashCode {
    return membNo.hashCode ^
        membNm.hashCode ^
        reptMembNo.hashCode ^
        reptMembNm.hashCode ^
        bizNo.hashCode ^
        officeNm.hashCode ^
        profileImgPath.hashCode ^
        accessToken.hashCode ^
        refreshToken.hashCode ^
        resCd.hashCode ^
        hpNo.hashCode ^
        birthDt.hashCode ^
        sexCd.hashCode ^
        gradeCd.hashCode ^
        permCd.hashCode ^
        firstLoginYn.hashCode;
  }
}
