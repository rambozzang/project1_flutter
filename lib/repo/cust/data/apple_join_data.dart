// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AppleJoinData {
  String? uid;
  String? email;
  String? displayName;
  String? chatId;
  AppleJoinData({
    this.uid,
    this.email,
    this.displayName,
    this.chatId,
  });

  AppleJoinData copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? chatId,
  }) {
    return AppleJoinData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      chatId: chatId ?? this.chatId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'chatId': chatId,
    };
  }

  factory AppleJoinData.fromMap(Map<String, dynamic> map) {
    return AppleJoinData(
      uid: map['uid'] != null ? map['uid'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      displayName: map['displayName'] != null ? map['displayName'] as String : null,
      chatId: map['chatId'] != null ? map['chatId'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppleJoinData.fromJson(String source) => AppleJoinData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AppleJoinData(uid: $uid, email: $email, displayName: $displayName, chatId: $chatId)';
  }

  @override
  bool operator ==(covariant AppleJoinData other) {
    if (identical(this, other)) return true;

    return other.uid == uid && other.email == email && other.displayName == displayName && other.chatId == chatId;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ email.hashCode ^ displayName.hashCode ^ chatId.hashCode;
  }
}
