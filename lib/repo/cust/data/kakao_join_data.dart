// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class KakaoJoinData {
  int? id;
  String? chatId;

  KakaoAccount? kakaoAccount;
  KakaoJoinData({
    this.id,
    this.chatId,
    this.kakaoAccount,
  });

  KakaoJoinData copyWith({
    int? id,
    String? chatId,
    KakaoAccount? kakaoAccount,
  }) {
    return KakaoJoinData(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      kakaoAccount: kakaoAccount ?? this.kakaoAccount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'chatId': chatId,
      'kakaoAccount': kakaoAccount?.toMap(),
    };
  }

  factory KakaoJoinData.fromMap(Map<String, dynamic> map) {
    return KakaoJoinData(
      id: map['id'] != null ? map['id'] as int : null,
      chatId: map['chatId'] != null ? map['chatId'] as String : null,
      kakaoAccount: map['kakaoAccount'] != null ? KakaoAccount.fromMap(map['kakaoAccount'] as Map<String, dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory KakaoJoinData.fromJson(String source) => KakaoJoinData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'KakaoJoinData(id: $id, chatId: $chatId, kakaoAccount: $kakaoAccount)';

  @override
  bool operator ==(covariant KakaoJoinData other) {
    if (identical(this, other)) return true;

    return other.id == id && other.chatId == chatId && other.kakaoAccount == kakaoAccount;
  }

  @override
  int get hashCode => id.hashCode ^ chatId.hashCode ^ kakaoAccount.hashCode;
}

class KakaoAccount {
  Profile? profile;
  String? email;
  String? ageRange;
  String? gender;
  String? ci;
  String? birthday;
  String? birthdayType;
  String? name;
  String? phoneNumber;
  KakaoAccount({
    this.profile,
    this.email,
    this.ageRange,
    this.gender,
    this.ci,
    this.birthday,
    this.birthdayType,
    this.name,
    this.phoneNumber,
  });

  KakaoAccount copyWith({
    Profile? profile,
    String? email,
    String? ageRange,
    String? gender,
    String? ci,
    String? birthday,
    String? birthdayType,
    String? name,
    String? phoneNumber,
  }) {
    return KakaoAccount(
      profile: profile ?? this.profile,
      email: email ?? this.email,
      ageRange: ageRange ?? this.ageRange,
      gender: gender ?? this.gender,
      ci: ci ?? this.ci,
      birthday: birthday ?? this.birthday,
      birthdayType: birthdayType ?? this.birthdayType,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'profile': profile?.toMap(),
      'email': email,
      'ageRange': ageRange,
      'gender': gender,
      'ci': ci,
      'birthday': birthday,
      'birthdayType': birthdayType,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  factory KakaoAccount.fromMap(Map<String, dynamic> map) {
    return KakaoAccount(
      profile: map['profile'] != null ? Profile.fromMap(map['profile'] as Map<String, dynamic>) : null,
      email: map['email'] != null ? map['email'] as String : null,
      ageRange: map['ageRange'] != null ? map['ageRange'] as String : null,
      gender: map['gender'] != null ? map['gender'] as String : null,
      ci: map['ci'] != null ? map['ci'] as String : null,
      birthday: map['birthday'] != null ? map['birthday'] as String : null,
      birthdayType: map['birthdayType'] != null ? map['birthdayType'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      phoneNumber: map['phoneNumber'] != null ? map['phoneNumber'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory KakaoAccount.fromJson(String source) => KakaoAccount.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'KakaoAccount(profile: $profile, email: $email, ageRange: $ageRange, gender: $gender, ci: $ci, birthday: $birthday, birthdayType: $birthdayType, name: $name, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(covariant KakaoAccount other) {
    if (identical(this, other)) return true;

    return other.profile == profile &&
        other.email == email &&
        other.ageRange == ageRange &&
        other.gender == gender &&
        other.ci == ci &&
        other.birthday == birthday &&
        other.birthdayType == birthdayType &&
        other.name == name &&
        other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode {
    return profile.hashCode ^
        email.hashCode ^
        ageRange.hashCode ^
        gender.hashCode ^
        ci.hashCode ^
        birthday.hashCode ^
        birthdayType.hashCode ^
        name.hashCode ^
        phoneNumber.hashCode;
  }
}

class Profile {
  String? nickname;
  String? profileImageUrl;
  String? thumbnailImageUrl;
  Profile({
    this.nickname,
    this.profileImageUrl,
    this.thumbnailImageUrl,
  });

  Profile copyWith({
    String? nickname,
    String? profileImageUrl,
    String? thumbnailImageUrl,
  }) {
    return Profile(
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      thumbnailImageUrl: thumbnailImageUrl ?? this.thumbnailImageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'thumbnailImageUrl': thumbnailImageUrl,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      nickname: map['nickname'] != null ? map['nickname'] as String : null,
      profileImageUrl: map['profileImageUrl'] != null ? map['profileImageUrl'] as String : null,
      thumbnailImageUrl: map['thumbnailImageUrl'] != null ? map['thumbnailImageUrl'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Profile.fromJson(String source) => Profile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Profile(nickname: $nickname, profileImageUrl: $profileImageUrl, thumbnailImageUrl: $thumbnailImageUrl)';

  @override
  bool operator ==(covariant Profile other) {
    if (identical(this, other)) return true;

    return other.nickname == nickname && other.profileImageUrl == profileImageUrl && other.thumbnailImageUrl == thumbnailImageUrl;
  }

  @override
  int get hashCode => nickname.hashCode ^ profileImageUrl.hashCode ^ thumbnailImageUrl.hashCode;
}
