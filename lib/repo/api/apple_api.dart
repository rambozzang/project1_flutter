import 'package:project1/repo/cust/data/apple_join_data.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/chatting/chat_repo.dart';
import 'package:project1/repo/chatting/data/signup_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class AppleApi with SecureStorage {
  Future<ResData> signInWithApple() async {
    ResData resData = ResData();
    resData.code = "00";
    try {
      // 1. Apple 로그인 진행
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      lo.g('Apple credential: $credential');

      // 2. Apple 로그인 정보로 회원가입/로그인 처리
      AppleJoinData appleJoinData = AppleJoinData();
      appleJoinData.uid = credential.userIdentifier;
      appleJoinData.email = credential.email;
      appleJoinData.displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();

      // 채팅서버 회원가입
      appleJoinData.chatId = await chatSignUp(appleJoinData);

      CustRepo repo = CustRepo();
      ResData res = await repo.createAppleCust(appleJoinData);
      if (res.code != "00") {
        // lo.g('res: ${res.toString()}');
        // Utils.alert(res.msg.toString());
        // return false;
        resData.code = '99';
        resData.msg = res.msg.toString();
        return resData;
      }

      // ResData signUpProcRes = await AuthCntr.to.signUpProc(appleJoinData.uid.toString());
      // return signUpProcRes;
      resData.data = appleJoinData.uid.toString();
      return resData;
    } catch (e) {
      resData.code = '99';
      resData.msg = e.toString();
      return resData;
    }
  }

  Future<String> chatSignUp(AppleJoinData appleJoinData) async {
    try {
      ChatRepo chatRepo = ChatRepo();
      ChatSignupData chatSignupData = ChatSignupData();
      chatSignupData.email = appleJoinData.email;
      chatSignupData.uid = appleJoinData.uid.toString();
      chatSignupData.firstName = appleJoinData.displayName;
      // Apple doesn't provide a photo URL, so we'll leave it empty
      chatSignupData.imageUrl = '';
      ResData resData = await chatRepo.signup(chatSignupData);

      return resData.data.toString();
    } catch (e) {
      lo.g('chatSignup: $e');
      return '';
    }
  }

  void logout() async {
    // Apple doesn't provide a method to sign out on the client side
    // Instead, you should manage the logout on your server and clear local session data
    // await clearAll(); // Clear all stored data
  }
}
