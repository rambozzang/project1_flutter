import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/google_join_data.dart';

import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class GoogleApi {
  void signInWithGoogle() async {
    // Future<UserCredential> signInWithGoogle() async {
    // ---------------------------------------------------------
    // 1. Google 로그인 진행
    // ---------------------------------------------------------
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    log('googleUser : $googleUser');
    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    // ---------------------------------------------------------
    // 2. firebase 회원가입,로그인 처리
    // ---------------------------------------------------------
    GoogleJoinData googleJoinData = GoogleJoinData();
    await FirebaseAuth.instance
        .signInWithCredential(credential)
        .then((UserCredential value) {
      log('displayName : ${value.user!.displayName}');
      log('email : ${value.user!.email}');
      log('photoURL : ${value.user!.photoURL}');
      log('uid : ${value.user!.uid}');
      log('phoneNumber : ${value.user!.phoneNumber}');
      log('accessToken : ${value.credential!.accessToken}');
      log('token : ${value.credential!.token}');

      googleJoinData.displayName = value.user!.displayName;
      googleJoinData.email = value.user!.email;
      googleJoinData.phoneNumber = value.user!.phoneNumber;
      googleJoinData.photoURL = value.user!.photoURL;
      googleJoinData.uid = value.user!.uid;
    }).onError((error, stackTrace) {
      log('error : $error');
    });

    CustRepo repo = CustRepo();

    ResData res = await repo.createGoogleCust(googleJoinData);
    if (res.code != "00") {
      Utils.alert(res.msg.toString());
      return;
    }

    Utils.alert("회원가입 성공 :  ${res.data}");
  }

  void loginProc(UserCredential data) async {
    log('loginProc : UserCredential :  $data ');
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
  }
}

// flutter: 2024-03-16T01:17:35.309898 [🚫♥️DEBUG🐯💥] : displayName : Tiger Bk
// flutter: 2024-03-16T01:17:35.310403 [🚫♥️DEBUG🐯💥] : email : rambo.zzang@gmail.com
// flutter: 2024-03-16T01:17:35.310801 [🚫♥️DEBUG🐯💥] : photoURL : https://lh3.googleusercontent.com/a/ACg8ocJxXUa53SBipVBLB-usUa7hl-6ST17_kaTZyj0ouZK44UU=s96-c
// flutter: 2024-03-16T01:17:35.311199 [🚫♥️DEBUG🐯💥] : uid : WwKFevQXTXVlzU6TfaRjxAdbb633
// flutter: 2024-03-16T01:17:35.311495 [🚫♥️DEBUG🐯💥] : phoneNumber : null
// flutter: 2024-03-16T01:17:35.311779 [🚫♥️DEBUG🐯💥] : accessToken : ya29.a0Ad52N3-_ZpDjlLyzuff8hchlJSRDrBkPB8l19wI0UBR8Q6SPv5cpEBMBiqxBjE6_sddXqa3cWjWWtITEvMPITMBlJD7B82uyr7GhmVhX6tqJ3tgAx5b2wie0LPomf6UC0K4PtETo6vM0NJAYg8WA9YXG4OSCb4Z2fSHaaCgYKAaYSARMSFQHGX2MiJXPa2e0hkjK_KBUibt3NPg0171
// flutter: 2024-03-16T01:17:35.312009 [🚫♥️DEBUG🐯💥] : token : 105553151051408

// flutter: 2024-03-17T00:07:23.171453 [🚫♥️DEBUG🐯💥] : googleUser : GoogleSignInAccount:{displayName: bumkyu chun, email: v100004v@gmail.com, id: 108410322394245105208, photoUrl: https://lh3.googleusercontent.com/a/ACg8ocIs2USLHt5f32DbHbRq-wJWz7hEARbp4lsxv_tbeBIt=s1337, serverAuthCode: null}
// flutter: 2024-03-17T00:07:24.395857 [🚫♥️DEBUG🐯💥] : displayName : bumkyu chun
// flutter: 2024-03-17T00:07:24.396216 [🚫♥️DEBUG🐯💥] : email : v100004v@gmail.com
// flutter: 2024-03-17T00:07:24.396416 [🚫♥️DEBUG🐯💥] : photoURL : https://lh3.googleusercontent.com/a/ACg8ocIs2USLHt5f32DbHbRq-wJWz7hEARbp4lsxv_tbeBIt=s96-c
// flutter: 2024-03-17T00:07:24.396651 [🚫♥️DEBUG🐯💥] : uid : hgbJYxYBbtghrA541SnRHT2idiV2
// flutter: 2024-03-17T00:07:24.396849 [🚫♥️DEBUG🐯💥] : phoneNumber : null
// flutter: 2024-03-17T00:07:24.397047 [🚫♥️DEBUG🐯💥] : accessToken : ya29.a0Ad52N39wVavHPzOD5N-p7RNlx5cnBCa5YtdQaSy0WUg4kl1bn1Q7XtBqEHtA6I1zk6v8bfYXkWDzgQIYjcUabpoUp_daraeGeF0y31bzp5ABQysI8ACcJ3R8XjpaOw_aA0MFkxlCzHbXwnyQilcxLZrFdCiQM1HdKqfNaCgYKAXgSARASFQHGX2MiUE2KxW3wkycmVvZ8rW_rqA0171
// flutter: 2024-03-17T00:07:24.397278 [🚫♥️DEBUG🐯💥] : token : 105553150986912
