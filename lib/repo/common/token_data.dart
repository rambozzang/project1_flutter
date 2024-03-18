// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:convert';

// class TokenData {
//   String? accessToken;
//   String? refreshToken;
//   String? fcmToken;
//   String? membNo;

//   TokenData({
//     this.accessToken,
//     this.refreshToken,
//     this.fcmToken,
//     this.membNo,
//   });

//   TokenData copyWith({
//     String? accessToken,
//     String? refreshToken,
//     String? fcmToken,
//     String? membNo,
//   }) {
//     return TokenData(
//       accessToken: accessToken ?? this.accessToken,
//       refreshToken: refreshToken ?? this.refreshToken,
//       fcmToken: fcmToken ?? this.fcmToken,
//       membNo: membNo ?? this.membNo,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'accessToken': accessToken,
//       'refreshToken': refreshToken,
//       'fcmToken': fcmToken,
//       'membNo': membNo,
//     };
//   }

//   factory TokenData.fromMap(Map<String, dynamic> map) {
//     return TokenData(
//       accessToken: map['accessToken'] as String,
//       refreshToken: map['refreshToken'] as String,
//       fcmToken: map['fcmToken'] as String,
//       membNo: map['membNo'] as String,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory TokenData.fromJson(String source) => TokenData.fromMap(json.decode(source) as Map<String, dynamic>);

//   @override
//   String toString() {
//     return 'TokenData(accessToken: $accessToken, refreshToken: $refreshToken, fcmToken: $fcmToken, membNo: $membNo)';
//   }

//   @override
//   bool operator ==(covariant TokenData other) {
//     if (identical(this, other)) return true;

//     return other.accessToken == accessToken && other.refreshToken == refreshToken && other.fcmToken == fcmToken && other.membNo == membNo;
//   }

//   @override
//   int get hashCode {
//     return accessToken.hashCode ^ refreshToken.hashCode ^ fcmToken.hashCode ^ membNo.hashCode;
//   }
// }
