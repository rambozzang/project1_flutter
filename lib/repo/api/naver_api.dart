import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:project1/repo/api/chat_api.dart';
import 'package:project1/repo/chatting/chat_repo.dart';
import 'package:project1/repo/chatting/data/signup_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/naver_join_data.dart';
import 'package:project1/repo/secure_storge.dart';

import 'package:project1/utils/log_utils.dart';
import 'package:uuid/uuid.dart';

//  연결 주소 : https://developers.naver.com/docs/login/api/api.md
class NaverApi with SecureStorage {
  Future<ResData<String>> signInWithNaver() async {
    ResData<String> resData = ResData<String>();
    resData.code = "00";
    CustRepo repo = CustRepo();

    try {
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      if (result.status == NaverLoginStatus.error || result.status == NaverLoginStatus.cancelledByUser) {
        resData.code = '99';
        resData.msg = '사용자 취소';
        return resData;
      }
      NaverAccount naverAccount = NaverAccount();
      naverAccount.nickname = result.account.nickname;
      naverAccount.id = result.account.id.toString();
      naverAccount.name = result.account.name;
      naverAccount.email = result.account.email;
      naverAccount.profileImage = result.account.profileImage;
      naverAccount.gender = '';
      naverAccount.age = '';
      naverAccount.birthday = '';
      naverAccount.birthyear = '';
      naverAccount.mobile = '';

      NaverJoinData naverJoinData = NaverJoinData();
      naverJoinData.stauts = result.status.toString();
      naverJoinData.account = naverAccount;
      naverJoinData.deviceId = const Uuid().v4();
      // naverJoinData.chatId = await chatSignUp(result);
      // 채팅서버 회원가입
      ChatApi chatApi = ChatApi();
      naverJoinData.chatId = await chatApi.chatSignUp(
          naverAccount.email ?? '', naverAccount.id.toString(), naverAccount.nickname ?? '', naverAccount.profileImage ?? '');

      ResData res = await repo.createNaverCust(naverJoinData);

      if (res.code != "00") {
        resData.code = res.code.toString();
        resData.msg = res.msg.toString();
        return resData;
      }

      saveDeviceId(naverJoinData.deviceId.toString());
      resData.data = naverJoinData.account!.id.toString();
      return resData;
    } catch (e) {
      lo.g('err :${e.toString()}');
      resData.code = '99';
      resData.msg = e.toString();
      return resData;
    }
  }

  Future<void> logOut() async {
    try {
      // await FlutterNaverLogin.logOut();
      NaverLoginResult result = await FlutterNaverLogin.logOutAndDeleteToken();
      lo.g("logout:" + result.toString());

      print('로그아웃 성공, SDK에서 토큰 삭제');
    } catch (error) {
      print('로그아웃 실패, SDK에서 토큰 삭제 $error');
    }
  }
}
