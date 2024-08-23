// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class NaverJoinData {
  String? stauts;
  String? chatId;
  String? deviceId;
  NaverAccount? account;
  NaverJoinData({
    this.stauts,
    this.chatId,
    this.deviceId,
    this.account,
  });

  NaverJoinData copyWith({
    String? stauts,
    String? chatId,
    String? deviceId,
    NaverAccount? account,
  }) {
    return NaverJoinData(
      stauts: stauts ?? this.stauts,
      chatId: chatId ?? this.chatId,
      deviceId: deviceId ?? this.deviceId,
      account: account ?? this.account,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'stauts': stauts,
      'chatId': chatId,
      'deviceId': deviceId,
      'account': account?.toMap(),
    };
  }

  factory NaverJoinData.fromMap(Map<String, dynamic> map) {
    return NaverJoinData(
      stauts: map['stauts'] != null ? map['stauts'] as String : null,
      chatId: map['chatId'] != null ? map['chatId'] as String : null,
      deviceId: map['deviceId'] != null ? map['deviceId'] as String : null,
      account: map['account'] != null ? NaverAccount.fromMap(map['account'] as Map<String, dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory NaverJoinData.fromJson(String source) => NaverJoinData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'NaverJoinData(stauts: $stauts, chatId: $chatId, deviceId: $deviceId, account: $account)';
  }

  @override
  bool operator ==(covariant NaverJoinData other) {
    if (identical(this, other)) return true;

    return other.stauts == stauts && other.chatId == chatId && other.deviceId == deviceId && other.account == account;
  }

  @override
  int get hashCode {
    return stauts.hashCode ^ chatId.hashCode ^ deviceId.hashCode ^ account.hashCode;
  }
}

class NaverAccount {
  String? nickname;
  String? id;
  String? name;
  String? email;
  String? gender;
  String? age;
  String? birthday;
  String? birthyear;
  String? profileImage;
  String? mobile;
  NaverAccount({
    this.nickname,
    this.id,
    this.name,
    this.email,
    this.gender,
    this.age,
    this.birthday,
    this.birthyear,
    this.profileImage,
    this.mobile,
  });

  NaverAccount copyWith({
    String? nickname,
    String? id,
    String? name,
    String? email,
    String? gender,
    String? age,
    String? birthday,
    String? birthyear,
    String? profileImage,
    String? mobile,
  }) {
    return NaverAccount(
      nickname: nickname ?? this.nickname,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      birthday: birthday ?? this.birthday,
      birthyear: birthyear ?? this.birthyear,
      profileImage: profileImage ?? this.profileImage,
      mobile: mobile ?? this.mobile,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nickname': nickname,
      'id': id,
      'name': name,
      'email': email,
      'gender': gender,
      'age': age,
      'birthday': birthday,
      'birthyear': birthyear,
      'profileImage': profileImage,
      'mobile': mobile,
    };
  }

  factory NaverAccount.fromMap(Map<String, dynamic> map) {
    return NaverAccount(
      nickname: map['nickname'] != null ? map['nickname'] as String : null,
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      gender: map['gender'] != null ? map['gender'] as String : null,
      age: map['age'] != null ? map['age'] as String : null,
      birthday: map['birthday'] != null ? map['birthday'] as String : null,
      birthyear: map['birthyear'] != null ? map['birthyear'] as String : null,
      profileImage: map['profileImage'] != null ? map['profileImage'] as String : null,
      mobile: map['mobile'] != null ? map['mobile'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory NaverAccount.fromJson(String source) => NaverAccount.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'NaverAccount(nickname: $nickname, id: $id, name: $name, email: $email, gender: $gender, age: $age, birthday: $birthday, birthyear: $birthyear, profileImage: $profileImage, mobile: $mobile)';
  }

  @override
  bool operator ==(covariant NaverAccount other) {
    if (identical(this, other)) return true;

    return other.nickname == nickname &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.gender == gender &&
        other.age == age &&
        other.birthday == birthday &&
        other.birthyear == birthyear &&
        other.profileImage == profileImage &&
        other.mobile == mobile;
  }

  @override
  int get hashCode {
    return nickname.hashCode ^
        id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        gender.hashCode ^
        age.hashCode ^
        birthday.hashCode ^
        birthyear.hashCode ^
        profileImage.hashCode ^
        mobile.hashCode;
  }
}
