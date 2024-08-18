import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:project1/repo/chatting/chat_repo.dart';
import 'package:project1/repo/chatting/data/signup_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/naver_join_data.dart';
import 'package:project1/repo/secure_storge.dart';

import 'package:project1/utils/log_utils.dart';

//  연결 주소 : https://developers.naver.com/docs/login/api/api.md
class NaverApi with SecureStorage {
  Future<ResData<String>> signInWithNaver() async {
    ResData<String> resData = ResData<String>();
    resData.code = "00";

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
        resData.code = res.code.toString();
        resData.msg = res.msg.toString();
        return resData;
      }
    } catch (e) {
      resData.code = '99';
      resData.msg = e.toString();
      return resData;
    }

    // ResData signUpProcRes = await AuthCntr.to.signUpProc(naverJoinData.account!.id.toString());
    // return signUpProcRes;
    resData.data = naverJoinData.account!.id.toString();
    return resData;
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

  Future<void> logOut() async {
    try {
      // await FlutterNaverLogin.logOut();
      await FlutterNaverLogin.logOutAndDeleteToken();
      print('로그아웃 성공, SDK에서 토큰 삭제');
    } catch (error) {
      print('로그아웃 실패, SDK에서 토큰 삭제 $error');
    }
  }
}
