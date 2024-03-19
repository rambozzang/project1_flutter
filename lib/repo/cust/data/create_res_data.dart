// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:convert';

// import 'package:project1/repo/cust/data/google_res_data.dart';
// import 'package:project1/repo/cust/data/kakao_join_data.dart';
// import 'package:project1/repo/cust/data/naver_res_data.dart';

// class CreateResData {
//   String? authProvider;
//   KakaoResData? kakaoUserInfo;
//   NaverResData? naverUserInfo;
//   GoogleResData? googleUserInfo;
//   String? accessToken;
//   String? refreshToken;
//   String? firebaseToken;
//   String? userid;
//   CreateResData({
//     this.authProvider,
//     this.kakaoUserInfo,
//     this.naverUserInfo,
//     this.googleUserInfo,
//     this.accessToken,
//     this.refreshToken,
//     this.firebaseToken,
//     this.userid,
//   });

//   CreateResData copyWith({
//     String? authProvider,
//     KakaoResData? kakaoUserInfo,
//     NaverResData? naverUserInfo,
//     GoogleResData? googleUserInfo,
//     String? accessToken,
//     String? refreshToken,
//     String? firebaseToken,
//     String? userid,
//   }) {
//     return CreateResData(
//       authProvider: authProvider ?? this.authProvider,
//       kakaoUserInfo: kakaoUserInfo ?? this.kakaoUserInfo,
//       naverUserInfo: naverUserInfo ?? this.naverUserInfo,
//       googleUserInfo: googleUserInfo ?? this.googleUserInfo,
//       accessToken: accessToken ?? this.accessToken,
//       refreshToken: refreshToken ?? this.refreshToken,
//       firebaseToken: firebaseToken ?? this.firebaseToken,
//       userid: userid ?? this.userid,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'authProvider': authProvider,
//       'kakaoUserInfo': kakaoUserInfo?.toMap(),
//       'naverUserInfo': naverUserInfo?.toMap(),
//       'googleUserInfo': googleUserInfo?.toMap(),
//       'accessToken': accessToken,
//       'refreshToken': refreshToken,
//       'firebaseToken': firebaseToken,
//       'userid': userid,
//     };
//   }

//   factory CreateResData.fromMap(Map<String, dynamic> map) {
//     return CreateResData(
//       authProvider: map['authProvider'] != null ? map['authProvider'] as String : null,
//       kakaoUserInfo: map['kakaoUserInfo'] != null ? KakaoResData.fromMap(map['kakaoUserInfo'] as Map<String, dynamic>) : null,
//       naverUserInfo: map['naverUserInfo'] != null ? NaverResData.fromMap(map['naverUserInfo'] as Map<String, dynamic>) : null,
//       googleUserInfo: map['googleUserInfo'] != null ? GoogleResData.fromMap(map['googleUserInfo'] as Map<String, dynamic>) : null,
//       accessToken: map['accessToken'] != null ? map['accessToken'] as String : null,
//       refreshToken: map['refreshToken'] != null ? map['refreshToken'] as String : null,
//       firebaseToken: map['firebaseToken'] != null ? map['firebaseToken'] as String : null,
//       userid: map['userid'] != null ? map['userid'] as String : null,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory CreateResData.fromJson(String source) => CreateResData.fromMap(json.decode(source) as Map<String, dynamic>);

//   @override
//   String toString() {
//     return 'CreateResData(authProvider: $authProvider, kakaoUserInfo: $kakaoUserInfo, naverUserInfo: $naverUserInfo, googleUserInfo: $googleUserInfo, accessToken: $accessToken, refreshToken: $refreshToken, firebaseToken: $firebaseToken, userid: $userid)';
//   }

//   @override
//   bool operator ==(covariant CreateResData other) {
//     if (identical(this, other)) return true;

//     return other.authProvider == authProvider &&
//         other.kakaoUserInfo == kakaoUserInfo &&
//         other.naverUserInfo == naverUserInfo &&
//         other.googleUserInfo == googleUserInfo &&
//         other.accessToken == accessToken &&
//         other.refreshToken == refreshToken &&
//         other.firebaseToken == firebaseToken &&
//         other.userid == userid;
//   }

//   @override
//   int get hashCode {
//     return authProvider.hashCode ^
//         kakaoUserInfo.hashCode ^
//         naverUserInfo.hashCode ^
//         googleUserInfo.hashCode ^
//         accessToken.hashCode ^
//         refreshToken.hashCode ^
//         firebaseToken.hashCode ^
//         userid.hashCode;
//   }
// }
