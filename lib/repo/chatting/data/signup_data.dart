// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ChatSignupData {
  // email , password(uid) , firstName , lastName , imageUrl
  String? email;
  String? uid; // Chat서버 UID값으로 사용
  String? firstName;
  String? lastName;
  String? imageUrl;
  ChatSignupData({
    this.email,
    this.uid,
    this.firstName,
    this.lastName,
    this.imageUrl,
  });

  ChatSignupData copyWith({
    String? email,
    String? uid,
    String? firstName,
    String? lastName,
    String? imageUrl,
  }) {
    return ChatSignupData(
      email: email ?? this.email,
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'imageUrl': imageUrl,
    };
  }

  factory ChatSignupData.fromMap(Map<String, dynamic> map) {
    return ChatSignupData(
      email: map['email'] != null ? map['email'] as String : null,
      uid: map['uid'] != null ? map['uid'] as String : null,
      firstName: map['firstName'] != null ? map['firstName'] as String : null,
      lastName: map['lastName'] != null ? map['lastName'] as String : null,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatSignupData.fromJson(String source) => ChatSignupData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChatSignupData(email: $email, uid: $uid, firstName: $firstName, lastName: $lastName, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(covariant ChatSignupData other) {
    if (identical(this, other)) return true;

    return other.email == email &&
        other.uid == uid &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return email.hashCode ^ uid.hashCode ^ firstName.hashCode ^ lastName.hashCode ^ imageUrl.hashCode;
  }
}
