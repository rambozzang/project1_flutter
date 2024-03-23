import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/kakao_join_data.dart' as Join;
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as Kakao;

// 카카오 개발문서
// https://developers.kakao.com/docs/latest/ko/kakaologin/flutter
// https://velog.io/@qazws78941/FlutterKakao-login-api%EB%A5%BC-%EC%9D%B4%EC%9A%A9%ED%95%9C-%EB%A1%9C%EA%B7%B8%EC%9D%B8
// https://velog.io/@sumong/Flutter%EC%97%90%EC%84%9C-%EC%B9%B4%EC%B9%B4%EC%98%A4-%EB%A1%9C%EA%B7%B8%EC%9D%B8-%EA%B5%AC%ED%98%84%ED%95%98%EA%B8%B0
class KakaoApi with SecureStorage {
  // 사용자의 추가 동의가 필요한 사용자 정보 동의항목 확인
  List<String> scopes = [
    'account_email',
    "birthday",
    "birthyear",
    "phone_number",
    "profile",
    "account_ci"
  ];

  Future<void> signInWithKakaoApp() async {
    // 카카오톡 실행 가능 여부
    if (await isKakaoTalkInstalled()) {
      log("카카오톡가 있는 경우 프로세스 1");
      try {
        // 카카오톡에 연결된 카카오계정 및 인증 정보를 사용
        OAuthToken? token =
            await UserApi.instance.loginWithKakaoTalk(serviceTerms: scopes);
        log('카카오톡으로 로그인 성공1 : _token :  $token ');
        signUpProc(token.toString());
        await TokenManagerProvider.instance.manager.setToken(token);
      } catch (error) {
        log('카카오톡으로 로그인1 실패 $error');
        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }
        try {
          // 사용자가 카카오계정 정보를 직접 입력하지 않아도 간편하게 로그인 가능
          OAuthToken? token = await UserApi.instance
              .loginWithKakaoAccount(serviceTerms: scopes);
          signUpProc(token.toString());
          log('카카오계정으로 로그인2 성공 : _token :  $token ');
        } catch (error) {
          log('카카오계정으로 로그인2 실패 $error');
        }
      }
    } else {
      log("카카오톡가 없는 경우 프로세스 3");
      try {
        // 사용자가 카카오계정 정보를 직접 입력하지 않아도 간편하게 로그인 가능
        OAuthToken? token =
            await UserApi.instance.loginWithKakaoAccount(serviceTerms: scopes);
        log('카카오계정으로 로그인3 성공 : _token :  $token ');

        signUpProc(token.accessToken.toString());
      } catch (error) {
        log('카카오계정으로 로그인3 실패 $error');
      }
    }
  }

  void signUpProc(String token) async {
    try {
      Kakao.User user;

      user = await UserApi.instance.me();
      log('사용자 정보 요청 성공'
          '\nUser: ${user.toString()}');

      CustRepo repo = CustRepo();

      Join.KakaoJoinData kakaoJoinData = Join.KakaoJoinData();
      kakaoJoinData.id = user.id;

      Join.KakaoAccount kakaoAccount = Join.KakaoAccount();
      kakaoAccount.ageRange = user.kakaoAccount?.ageRange.toString();
      kakaoAccount.birthday = user.kakaoAccount?.birthday;
      kakaoAccount.birthdayType = user.kakaoAccount?.birthdayType.toString();
      kakaoAccount.ci = user.kakaoAccount?.ci;
      kakaoAccount.email = user.kakaoAccount?.email;
      kakaoAccount.gender = user.kakaoAccount?.gender.toString();
      kakaoAccount.name = user.kakaoAccount?.name;
      kakaoAccount.phoneNumber = user.kakaoAccount?.phoneNumber;

      Join.Profile profile = Join.Profile();
      profile.nickname = user.kakaoAccount?.profile?.nickname;
      profile.profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;
      profile.thumbnailImageUrl = user.kakaoAccount?.profile?.thumbnailImageUrl;

      kakaoAccount.profile = profile;
      kakaoJoinData.kakaoAccount = kakaoAccount;

      ResData res = await repo.createKakaoCust(kakaoJoinData);
      if (res.code != "00") {
        Utils.alert(res.msg.toString());
        return;
      }

      Utils.alert("회원가입 성공 :  ${res.data}");

      AuthCntr.to.signUpProc(kakaoJoinData.id.toString());
      return;
    } catch (e) {
      log(e.toString());
      Utils.alert(e.toString());
      return;
    }

/*
    // 사용자의 추가 동의가 필요한 사용자 정보 동의항목 확인
    List<String> scopes = [];

    if (user.kakaoAccount?.emailNeedsAgreement == true) {
      scopes.add('account_email');
    }
    if (user.kakaoAccount?.birthdayNeedsAgreement == true) {
      scopes.add("birthday");
    }
    if (user.kakaoAccount?.birthyearNeedsAgreement == true) {
      scopes.add("birthyear");
    }
    if (user.kakaoAccount?.ciNeedsAgreement == true) {
      scopes.add("account_ci");
    }
    if (user.kakaoAccount?.phoneNumberNeedsAgreement == true) {
      scopes.add("phone_number");
    }
    if (user.kakaoAccount?.profileNeedsAgreement == true) {
      scopes.add("profile");
    }
    if (user.kakaoAccount?.ageRangeNeedsAgreement == true) {
      scopes.add("age_range");
    }

    if (scopes.length > 0) {
      print('사용자에게 추가 동의 받아야 하는 항목이 있습니다');

      // OpenID Connect 사용 시
      // scope 목록에 "openid" 문자열을 추가하고 요청해야 함
      // 해당 문자열을 포함하지 않은 경우, ID 토큰이 재발급되지 않음
      // scopes.add("openid")

      // scope 목록을 전달하여 추가 항목 동의 받기 요청
      // 지정된 동의항목에 대한 동의 화면을 거쳐 다시 카카오 로그인 수행
      OAuthToken token;
      try {
        token = await UserApi.instance.loginWithNewScopes(scopes);

        print('현재 사용자가 동의한 동의항목: ${token.scopes}');
      } catch (error) {
        print('추가 동의 요청 실패 $error');
        return;
      }

      // 사용자 정보 재요청
      try {
        Kakao.User user = await UserApi.instance.me();
        print('사용자 정보 요청 성공'
            '\n회원번호: ${user.id}'
            '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
            '\n이메일: ${user.kakaoAccount?.email}');
      } catch (error) {
        print('사용자 정보 요청 실패 $error');
      }
    }

    // log('loginProc : _token :  $token');
    // Kakao.User user = await UserApi.instance.me();
    // log(user.toString());

    // print('사용자 정보 요청 성공'
    //     '\n회원번호: ${user.id}'
    //     '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
    //     '\n이메일: ${user.kakaoAccount?.email}');

    // final token = await FirebaseApi().createCustomToken({
    //   'uid': user!.id.toString(),
    //   'displayName': user!.kakaoAccount!.profile!.nickname,
    //   'email': user!.kakaoAccount!.email!,
    //   'photoURL': user!.kakaoAccount!.profile!.profileImageUrl!,
    // });

    // ---------------------------------------------------------
    // 2. firebase 회원가입,로그인 처리
    // ---------------------------------------------------------
    // await FirebaseAuth.instance.signInWithCredential(token.data).then((UserCredential value) {
    //   log('displayName : ${value.user!.displayName}');
    //   log('email : ${value.user!.email}');
    //   log('photoURL : ${value.user!.photoURL}');
    //   log('uid : ${value.user!.uid}');
    //   log('phoneNumber : ${value.user!.phoneNumber}');
    //   log('accessToken : ${value.credential!.accessToken}');
    //   log('token : ${value.credential!.token}');
    // }).onError((error, stackTrace) {
    //   log('error : $error');
    // });
    */
  }

  void logout() async {
    try {
      await UserApi.instance.logout();
      print('로그아웃 성공, SDK에서 토큰 삭제');
    } catch (error) {
      print('로그아웃 실패, SDK에서 토큰 삭제 $error');
    }
  }
}



// 2
// [log] [🔬]
// [log] [🔬] DioException [bad response]: This exception was thrown because the response has a status code of 401 and RequestOptions.validateStatus was configured to throw for this status code.
//       The status code of 401 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"
//       Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
//       In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.
// [log] [🔬]  www-authenticate: Bearer realm="oauth", error="misconfigured", error_description="invalid android_key_hash or ios_bundle_id or web_site_url"
// [log] [🔬] {"error":"misconfigured","error_description":"invalid android_key_hash or ios_bundle_id or web_site_url","error_code":"KOE009"}
// [log] [🔬] https://kauth.kakao.com/oauth/authorize?client_id=257e56e034badf50ce13baaa28018e7d&redirect_uri=kakao257e56e034badf50ce13baaa28018e7d%3A%2F%2Foauth&response_type=code&service_terms=account_email%2Cbirthday%2Cbirthyear%2Cphone_number%2Cprofile%2Caccount_ci&code_challenge=3RrBKt1Oz6W8PrS7IzK4AVVS8dKc1M77e6ppqGXl4CI&code_challenge_method=S256&ka=sdk%2F1.9.1%2B2+sdk_type%2Fflutter+os%2Fandroid-34+lang%2Fko-KR+origin%2Fev7ZyJW3%2FpjhDZHSwXtNPlQkHeM%3D+device%2FSM-S926N+android_pkg%2Fcom.example.project1+app_ver%2F1.0.0