// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class NaverResData {
  String? resultcode;
  String? message;
  NaverAccount? response;
  NaverResData({
    this.resultcode,
    this.message,
    this.response,
  });

  NaverResData copyWith({
    String? resultcode,
    String? message,
    NaverAccount? response,
  }) {
    return NaverResData(
      resultcode: resultcode ?? this.resultcode,
      message: message ?? this.message,
      response: response ?? this.response,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'resultcode': resultcode,
      'message': message,
      'response': response?.toMap(),
    };
  }

  factory NaverResData.fromMap(Map<String, dynamic> map) {
    return NaverResData(
      resultcode: map['resultcode'] != null ? map['resultcode'] as String : null,
      message: map['message'] != null ? map['message'] as String : null,
      response: map['response'] != null ? NaverAccount.fromMap(map['response'] as Map<String, dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory NaverResData.fromJson(String source) => NaverResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'NaverResData(resultcode: $resultcode, message: $message, response: $response)';

  @override
  bool operator ==(covariant NaverResData other) {
    if (identical(this, other)) return true;

    return other.resultcode == resultcode && other.message == message && other.response == response;
  }

  @override
  int get hashCode => resultcode.hashCode ^ message.hashCode ^ response.hashCode;
}

class NaverAccount {
  String? id;
  String? nickname;
  String? name;
  String? email;
  String? gender;
  String? age;
  String? birthday;
  String? profileImage;
  String? birthyear;
  String? mobile;
  NaverAccount({
    this.id,
    this.nickname,
    this.name,
    this.email,
    this.gender,
    this.age,
    this.birthday,
    this.profileImage,
    this.birthyear,
    this.mobile,
  });

  NaverAccount copyWith({
    String? id,
    String? nickname,
    String? name,
    String? email,
    String? gender,
    String? age,
    String? birthday,
    String? profileImage,
    String? birthyear,
    String? mobile,
  }) {
    return NaverAccount(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      birthday: birthday ?? this.birthday,
      profileImage: profileImage ?? this.profileImage,
      birthyear: birthyear ?? this.birthyear,
      mobile: mobile ?? this.mobile,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nickname': nickname,
      'name': name,
      'email': email,
      'gender': gender,
      'age': age,
      'birthday': birthday,
      'profileImage': profileImage,
      'birthyear': birthyear,
      'mobile': mobile,
    };
  }

  factory NaverAccount.fromMap(Map<String, dynamic> map) {
    return NaverAccount(
      id: map['id'] != null ? map['id'] as String : null,
      nickname: map['nickname'] != null ? map['nickname'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      gender: map['gender'] != null ? map['gender'] as String : null,
      age: map['age'] != null ? map['age'] as String : null,
      birthday: map['birthday'] != null ? map['birthday'] as String : null,
      profileImage: map['profileImage'] != null ? map['profileImage'] as String : null,
      birthyear: map['birthyear'] != null ? map['birthyear'] as String : null,
      mobile: map['mobile'] != null ? map['mobile'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory NaverAccount.fromJson(String source) => NaverAccount.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'NaverAccount(id: $id, nickname: $nickname, name: $name, email: $email, gender: $gender, age: $age, birthday: $birthday, profileImage: $profileImage, birthyear: $birthyear, mobile: $mobile)';
  }

  @override
  bool operator ==(covariant NaverAccount other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.nickname == nickname &&
        other.name == name &&
        other.email == email &&
        other.gender == gender &&
        other.age == age &&
        other.birthday == birthday &&
        other.profileImage == profileImage &&
        other.birthyear == birthyear &&
        other.mobile == mobile;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nickname.hashCode ^
        name.hashCode ^
        email.hashCode ^
        gender.hashCode ^
        age.hashCode ^
        birthday.hashCode ^
        profileImage.hashCode ^
        birthyear.hashCode ^
        mobile.hashCode;
  }
}
