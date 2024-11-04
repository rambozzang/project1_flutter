import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project1/repo/api/chat_api.dart';
import 'package:project1/repo/chatting/chat_repo.dart';
import 'package:project1/repo/chatting/data/signup_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/google_join_data.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:uuid/uuid.dart';

class GoogleApi with SecureStorage {
  Future<ResData<String>> signInWithGoogle() async {
    try {
      ResData<String> resData = ResData<String>();
      resData.code = "00";

      // ---------------------------------------------------------
      // 1. Google 로그인 진행
      // ---------------------------------------------------------
      lo.g('UserCredential gogo');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: ['profile', 'email']).signIn();
      lo.g('googleUser : $googleUser');
      if (googleUser == null) {
        resData.code = '99';
        resData.msg = '로그인 취소';
        return resData;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      lo.g('googleAuth.accessToken : ${googleAuth.accessToken}');

      lo.g('googleAuth.idToken : ${googleAuth.idToken}');

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ---------------------------------------------------------
      // 2. firebase 회원가입,로그인 처리
      // ---------------------------------------------------------
      GoogleJoinData googleJoinData = GoogleJoinData();
      late ResData? res;

      await FirebaseAuth.instance.signInWithCredential(credential).then((UserCredential value) {
        googleJoinData.displayName = value.user!.displayName;
        googleJoinData.email = value.user!.email;
        googleJoinData.phoneNumber = value.user!.phoneNumber;
        googleJoinData.photoURL = value.user!.photoURL;
        googleJoinData.uid = value.user!.uid;
      }).onError((error, stackTrace) {
        log('error : $error');
      });

      // 채팅서버 회원가입
      // googleJoinData.chatId = await chatSignUp(googleJoinData);
      // 채팅서버 회원가입
      ChatApi chatApi = ChatApi();
      googleJoinData.chatId = await chatApi.chatSignUp(
          googleJoinData.email ?? '', googleJoinData.uid.toString(), googleJoinData.displayName ?? '', googleJoinData.photoURL ?? '');

      // deviceID 생성
      googleJoinData.deviceId = const Uuid().v4();
      saveDeviceId(googleJoinData.deviceId.toString());

      CustRepo repo = CustRepo();
      res = await repo.createGoogleCust(googleJoinData);
      if (res.code != "00") {
        resData.code = '99';
        resData.msg = res.msg.toString();
        return resData;
      }
      // ResData signUpProcRes = await AuthCntr.to.signUpProc(googleJoinData.uid.toString());
      // return signUpProcRes;
      resData.data = googleJoinData.uid.toString();
      return resData;
    } catch (e) {
      ResData<String> resData = ResData<String>();
      resData.code = '99';
      resData.msg = e.toString();
      return resData;
    }
  }

  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
