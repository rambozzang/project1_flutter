import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:project1/repo/cust/data/apple_join_data.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:project1/repo/chatting/chat_repo.dart';
import 'package:project1/repo/chatting/data/signup_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:uuid/uuid.dart';

class AppleApi with SecureStorage {
  Future<ResData<String>> signInWithApple() async {
    ResData<String> resData = ResData<String>();
    resData.code = "00";
    String? uid = '';
    String? email2 = '';
    String? displayName = '';

    try {
      // 1. Apple 로그인 진행
      AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      // email null 이고 identityToken 이 있는 경우
      if (credential.email == null && credential.identityToken != null) {
        List<String> jwt = credential.identityToken?.split('.') ?? [];
        String payload = jwt[1];
        payload = base64.normalize(payload);

        final List<int> jsonData = base64.decode(payload);
        final userInfo = jsonDecode(utf8.decode(jsonData));

        email2 = userInfo['email'];
        uid = userInfo['sub'];
        displayName = '${userInfo['given_name'] ?? ''} ${userInfo['family_name'] ?? ''}'.trim();
      } else {
        email2 = credential.email;
        uid = credential.userIdentifier;
        displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      }
      displayName = (displayName == null || displayName == '') ? email2!.split('@')[0] : displayName;

      // if (credential.userIdentifier == null) {
      //   resData.code = '99';
      //   resData.msg = 'Apple의 사용자 정보가 없습니다.';
      //   return resData;
      // }
      if (email2 == null || email2.isEmpty) {
        email2 = '$uid@privaterelay.appleid.com';
      }
      // 6. displayName이 비어있는 경우 대체 이름 사용
      if (displayName == null || displayName == '') {
        displayName = 'Apple User';
      }

      // 2. Apple 로그인 정보로 회원가입/로그인 처리
      AppleJoinData appleJoinData = AppleJoinData();
      appleJoinData.uid = uid;
      appleJoinData.email = email2;
      appleJoinData.displayName = displayName;

      // deviceID 생성
      appleJoinData.deviceId = const Uuid().v4();
      saveDeviceId(appleJoinData.deviceId.toString());

      CustRepo repo = CustRepo();
      ResData res = await repo.createAppleCust(appleJoinData);
      if (res.code != "00") {
        resData.code = '99';
        resData.msg = res.msg.toString();
        return resData;
      }
      // 채팅서버 회원가입
      appleJoinData.chatId = await chatSignUp(appleJoinData);
      resData.data = appleJoinData.uid.toString();
      return resData;
    } catch (e) {
      resData.code = '99';
      resData.msg = e.toString();
      return resData;
    }
  }

  Future<String> chatSignUp(AppleJoinData appleJoinData) async {
    ChatRepo chatRepo = ChatRepo();
    ChatSignupData chatSignupData = ChatSignupData();
    chatSignupData.email = appleJoinData.email;
    chatSignupData.uid = appleJoinData.uid.toString();
    chatSignupData.firstName = appleJoinData.displayName;
    // Apple doesn't provide a photo URL, so we'll leave it empty
    chatSignupData.imageUrl = '';
    ResData resData = await chatRepo.signup(chatSignupData);

    return resData.data.toString();
  }
}
