import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/chatting/chat_repo.dart';
import 'package:project1/repo/chatting/data/signup_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/naver_join_data.dart';
import 'package:project1/repo/secure_storge.dart';

import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

//  연결 주소 : https://developers.naver.com/docs/login/api/api.md
class NaverApi with SecureStorage {
  Future<bool> signInWithNaver() async {
    NaverLoginResult result = await FlutterNaverLogin.logIn();
    log('Naver Login Result : $result');
    NaverJoinData naverJoinData = NaverJoinData();

    try {
      CustRepo repo = CustRepo();

      naverJoinData.stauts = result.status.toString();

      NaverAccount naverAccount = NaverAccount();
      naverAccount.nickname = result.account.nickname;
      naverAccount.id = result.account.id.toString();
      naverAccount.name = result.account.name;
      naverAccount.email = result.account.email;
      naverAccount.gender = result.account.gender;
      naverAccount.age = result.account.age;
      naverAccount.birthday = result.account.birthday;
      naverAccount.birthyear = result.account.birthyear;
      naverAccount.profileImage = result.account.profileImage;
      naverAccount.mobile = result.account.mobile!.replaceAll('-', '');

      naverJoinData.account = naverAccount;

      // 채팅서버 회원가입
      naverJoinData.chatId = await chatSignUp(result);

      ResData res = await repo.createNaverCust(naverJoinData);
      if (res.code != "00") {
        Utils.alert(res.msg.toString());
        return false;
      }
    } catch (e) {
      Utils.alert(e.toString());
      return false;
    }

    bool result1 = await AuthCntr.to.signUpProc(naverJoinData.account!.id.toString());
    return result1;
  }

  Future<String> chatSignUp(NaverLoginResult result) async {
    try {
      ChatRepo chatRepo = ChatRepo();
      ChatSignupData chatSignupData = ChatSignupData();
      chatSignupData.email = result.account.email;
      chatSignupData.uid = result.account.id.toString();
      chatSignupData.firstName = result.account.nickname ?? result.account.name;
      chatSignupData.imageUrl = result.account.profileImage;
      ResData resData1 = await chatRepo.signup(chatSignupData);

      return resData1.data.toString();
    } catch (e) {
      log('chatSignup : $e');
      return '';
    }
  }
}
