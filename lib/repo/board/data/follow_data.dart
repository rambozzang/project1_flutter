// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class FollowData {
  String? custId;
  String? custNm;
  String? nickNm;
  String? profilePath;
  String? email;
  String? selfId;
  String? selfIntro;
  String? birthday;
  String? hpNo;
  String? followYn;
  String? alramYn;
  String? regDate;
  FollowData({
    this.custId,
    this.custNm,
    this.nickNm,
    this.profilePath,
    this.email,
    this.selfId,
    this.selfIntro,
    this.birthday,
    this.hpNo,
    this.followYn,
    this.alramYn,
    this.regDate,
  });

  FollowData copyWith({
    String? custId,
    String? custNm,
    String? nickNm,
    String? profilePath,
    String? email,
    String? selfId,
    String? selfIntro,
    String? birthday,
    String? hpNo,
    String? followYn,
    String? alramYn,
    String? regDate,
  }) {
    return FollowData(
      custId: custId ?? this.custId,
      custNm: custNm ?? this.custNm,
      nickNm: nickNm ?? this.nickNm,
      profilePath: profilePath ?? this.profilePath,
      email: email ?? this.email,
      selfId: selfId ?? this.selfId,
      selfIntro: selfIntro ?? this.selfIntro,
      birthday: birthday ?? this.birthday,
      hpNo: hpNo ?? this.hpNo,
      followYn: followYn ?? this.followYn,
      alramYn: alramYn ?? this.alramYn,
      regDate: regDate ?? this.regDate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'custId': custId,
      'custNm': custNm,
      'nickNm': nickNm,
      'profilePath': profilePath,
      'email': email,
      'selfId': selfId,
      'selfIntro': selfIntro,
      'birthday': birthday,
      'hpNo': hpNo,
      'followYn': followYn,
      'alramYn': alramYn,
      'regDate': regDate,
    };
  }

  factory FollowData.fromMap(Map<String, dynamic> map) {
    return FollowData(
      custId: map['custId'] != null ? map['custId'] as String : null,
      custNm: map['custNm'] != null ? map['custNm'] as String : null,
      nickNm: map['nickNm'] != null ? map['nickNm'] as String : null,
      profilePath: map['profilePath'] != null ? map['profilePath'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      selfId: map['selfId'] != null ? map['selfId'] as String : null,
      selfIntro: map['selfIntro'] != null ? map['selfIntro'] as String : null,
      birthday: map['birthday'] != null ? map['birthday'] as String : null,
      hpNo: map['hpNo'] != null ? map['hpNo'] as String : null,
      followYn: map['followYn'] != null ? map['followYn'] as String : null,
      alramYn: map['alramYn'] != null ? map['alramYn'] as String : null,
      regDate: map['regDate'] != null ? map['regDate'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory FollowData.fromJson(String source) => FollowData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'FollowData(custId: $custId, custNm: $custNm, nickNm: $nickNm, profilePath: $profilePath, email: $email, selfId: $selfId, selfIntro: $selfIntro, birthday: $birthday, hpNo: $hpNo, followYn: $followYn, alramYn: $alramYn, regDate: $regDate)';
  }

  @override
  bool operator ==(covariant FollowData other) {
    if (identical(this, other)) return true;

    return other.custId == custId &&
        other.custNm == custNm &&
        other.nickNm == nickNm &&
        other.profilePath == profilePath &&
        other.email == email &&
        other.selfId == selfId &&
        other.selfIntro == selfIntro &&
        other.birthday == birthday &&
        other.hpNo == hpNo &&
        other.followYn == followYn &&
        other.alramYn == alramYn &&
        other.regDate == regDate;
  }

  @override
  int get hashCode {
    return custId.hashCode ^
        custNm.hashCode ^
        nickNm.hashCode ^
        profilePath.hashCode ^
        email.hashCode ^
        selfId.hashCode ^
        selfIntro.hashCode ^
        birthday.hashCode ^
        hpNo.hashCode ^
        followYn.hashCode ^
        alramYn.hashCode ^
        regDate.hashCode;
  }
}
