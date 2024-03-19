// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CreateData {
  String? authProvider;
  String? code;
  String? accessToken;
  String? refreshToken;
  CreateData({
    this.authProvider,
    this.code,
    this.accessToken,
    this.refreshToken,
  });

  CreateData copyWith({
    String? authProvider,
    String? code,
    String? accessToken,
    String? refreshToken,
  }) {
    return CreateData(
      authProvider: authProvider ?? this.authProvider,
      code: code ?? this.code,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'authProvider': authProvider,
      'code': code,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  factory CreateData.fromMap(Map<String, dynamic> map) {
    return CreateData(
      authProvider: map['authProvider'] != null ? map['authProvider'] as String : null,
      code: map['code'] != null ? map['code'] as String : null,
      accessToken: map['accessToken'] != null ? map['accessToken'] as String : null,
      refreshToken: map['refreshToken'] != null ? map['refreshToken'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CreateData.fromJson(String source) => CreateData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CreateData(authProvider: $authProvider, code: $code, accessToken: $accessToken, refreshToken: $refreshToken)';
  }

  @override
  bool operator ==(covariant CreateData other) {
    if (identical(this, other)) return true;

    return other.authProvider == authProvider &&
        other.code == code &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode {
    return authProvider.hashCode ^ code.hashCode ^ accessToken.hashCode ^ refreshToken.hashCode;
  }
}
