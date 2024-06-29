// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ChatUpdateData {
  // firstName , lastName , imageUrl
  String? uid;
  String? firstName;
  String? lastName;
  String? imageUrl;
  ChatUpdateData({
    this.uid,
    this.firstName,
    this.lastName,
    this.imageUrl,
  });

  ChatUpdateData copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? imageUrl,
  }) {
    return ChatUpdateData(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'imageUrl': imageUrl,
    };
  }

  factory ChatUpdateData.fromMap(Map<String, dynamic> map) {
    return ChatUpdateData(
      uid: map['uid'] != null ? map['uid'] as String : null,
      firstName: map['firstName'] != null ? map['firstName'] as String : null,
      lastName: map['lastName'] != null ? map['lastName'] as String : null,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatUpdateData.fromJson(String source) => ChatUpdateData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChatUpdateData(uid: $uid, firstName: $firstName, lastName: $lastName, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(covariant ChatUpdateData other) {
    if (identical(this, other)) return true;

    return other.uid == uid && other.firstName == firstName && other.lastName == lastName && other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ firstName.hashCode ^ lastName.hashCode ^ imageUrl.hashCode;
  }
}
