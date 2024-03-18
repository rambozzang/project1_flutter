// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class TokenData {
  String? accessToken;
  String? refreshToken;
  String? firebaseToken;
  String? userid;

  TokenData({
    this.accessToken,
    this.refreshToken,
    this.firebaseToken,
    this.userid,
  });

  TokenData copyWith({
    String? accessToken,
    String? refreshToken,
    String? firebaseToken,
    String? userid,
  }) {
    return TokenData(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      firebaseToken: firebaseToken ?? this.firebaseToken,
      userid: userid ?? this.userid,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'firebaseToken': firebaseToken,
      'userid': userid,
    };
  }

  factory TokenData.fromMap(Map<String, dynamic> map) {
    return TokenData(
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String,
      firebaseToken: map['firebaseToken'] as String,
      userid: map['userid'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory TokenData.fromJson(String source) =>
      TokenData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TokenData(accessToken: $accessToken, refreshToken: $refreshToken, firebaseToken: $firebaseToken, userid: $userid)';
  }

  @override
  bool operator ==(covariant TokenData other) {
    if (identical(this, other)) return true;

    return other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.firebaseToken == firebaseToken &&
        other.userid == userid;
  }

  @override
  int get hashCode {
    return accessToken.hashCode ^
        refreshToken.hashCode ^
        firebaseToken.hashCode ^
        userid.hashCode;
  }
}
