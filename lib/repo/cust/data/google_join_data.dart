// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class GoogleJoinData {
  String? uid;
  String? chatId;
  String? deviceId;
  String? email;
  String? displayName;
  String? phoneNumber;
  String? photoURL;
  GoogleJoinData({
    this.uid,
    this.chatId,
    this.deviceId,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
  });

  GoogleJoinData copyWith({
    String? uid,
    String? chatId,
    String? deviceId,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) {
    return GoogleJoinData(
      uid: uid ?? this.uid,
      chatId: chatId ?? this.chatId,
      deviceId: deviceId ?? this.deviceId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'chatId': chatId,
      'deviceId': deviceId,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
    };
  }

  factory GoogleJoinData.fromMap(Map<String, dynamic> map) {
    return GoogleJoinData(
      uid: map['uid'] != null ? map['uid'] as String : null,
      chatId: map['chatId'] != null ? map['chatId'] as String : null,
      deviceId: map['deviceId'] != null ? map['deviceId'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      displayName: map['displayName'] != null ? map['displayName'] as String : null,
      phoneNumber: map['phoneNumber'] != null ? map['phoneNumber'] as String : null,
      photoURL: map['photoURL'] != null ? map['photoURL'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory GoogleJoinData.fromJson(String source) => GoogleJoinData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'GoogleJoinData(uid: $uid, chatId: $chatId, deviceId: $deviceId, email: $email, displayName: $displayName, phoneNumber: $phoneNumber, photoURL: $photoURL)';
  }

  @override
  bool operator ==(covariant GoogleJoinData other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.chatId == chatId &&
        other.deviceId == deviceId &&
        other.email == email &&
        other.displayName == displayName &&
        other.phoneNumber == phoneNumber &&
        other.photoURL == photoURL;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        chatId.hashCode ^
        deviceId.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        phoneNumber.hashCode ^
        photoURL.hashCode;
  }
}
