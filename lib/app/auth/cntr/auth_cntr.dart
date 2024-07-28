import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/privacy_policy_dialog.dart';
import 'package:project1/app/chatting/lib/flutter_supabase_chat_core.dart';
import 'package:project1/repo/api/google_api.dart';
import 'package:project1/repo/api/kakao_api.dart';
import 'package:project1/repo/api/naver_api.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/app/auth/cntr/login_data.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart' as supa;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthCntr>(() => AuthCntr());
  }
}

class AuthCntr extends GetxController with SecureStorage {
  static AuthCntr get to => Get.find();

  final CustRepo _custRepo = CustRepo();
  final Rx<LoginRes> resLoginData = LoginRes().obs;
  final RxBool isLogged = false.obs;
  final RxString custId = "".obs;
  late String fcmId = "";
  String currentChatId = "";

  //개인정보 처리 동의
  RxBool privacyPolicyAgreed = false.obs;
  RxBool termsOfServiceAgreed = false.obs;
  RxBool marketingAgreed = false.obs;
  RxBool locationServiceAgreed = false.obs;

  @override
  void onInit() async {
    super.onInit();

    // removeAll();

    await loginCheck();
  }

  Future<void> loginCheck() async {
    Lo.g("loginCheck 시작");
    isLogged.value = false;
    custId.value = await getCustId() ?? '';

    if (StringUtils.isEmpty(custId.value)) {
      Get.offAndToNamed("/JoinPage");
      return;
    }
    await login();
  }

  Future<void> login() async {
    if (StringUtils.isEmpty(custId.value)) {
      Utils.alert("로그인 정보가 없습니다.");
      return;
    }

    try {
      await _getFcmToken();
      ResData res = await _custRepo.login(custId.value, fcmId);
      if (res.code != "00") {
        Utils.alert("잠시 후 다시 시도해주세요. ${res.msg}");
        sleep(const Duration(seconds: 3));
        if (Platform.isIOS) {
          exit(0);
        } else {
          SystemNavigator.pop();
        }
        return;
      }
      resLoginData.value = LoginRes.fromMap(res.data);
      isLogged.value = true;
      update();
      await _initializeSupabaseIfNeeded();
    } catch (e) {
      Lo.g("로그인 에러: $e");
      isLogged.value = false;
      Utils.alert("네트워크가 불안정합니다. 잠시 후 다시 시도해주세요.");
      sleep(const Duration(seconds: 3));
      if (Platform.isIOS) {
        exit(0);
      } else {
        SystemNavigator.pop();
      }
    }
  }

  Future<void> _getFcmToken() async {
    try {
      fcmId = await FirebaseMessaging.instance.getToken() ?? "0000000000";
    } catch (e) {
      Lo.g("fcmId 발급 에러: $e");
      fcmId = "0000000000";
    }
    Lo.g("fcmId: $fcmId");
  }

  Future<void> _initializeSupabaseIfNeeded() async {
    if (resLoginData.value.chatId == '' || resLoginData.value.chatId == null) {
      await initSupaBaseSession();
    }
  }

  Future<bool> showPrivacyPolicyDialog() async {
    bool? result = await Get.dialog<bool>(
      PrivacyPolicyDialog(),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  Future<bool> testAgree(String _custId) async {
    bool agreed = await Get.toNamed('/AgreePage');
    if (!agreed) {
      Utils.alert('필수 약관에 동의해야 회원가입을 진행할 수 있습니다.');
      return false;
    }
    return true;
  }

  Future<ResData> signUpProc(String _custId) async {
    ResData resData = ResData();
    resData.code = "00";

    // bool agreed = await Get.toNamed('/AgreePage/$_custId'); //  await showPrivacyPolicyDialog();
    // if (!agreed) {
    //   resData.code = "99";
    //   resData.msg = "필수 약관에 동의해야 회원가입을 진행할 수 있습니다.";
    //   return resData;
    // }

    custId.value = _custId;
    await saveCustId(_custId);
    await _getFcmToken();

    try {
      ResData res = await _custRepo.login(custId.value, fcmId);
      if (res.code != "00") {
        resData.code = "99";
        resData.msg = res.msg;
        return resData;
      }
      resLoginData.value = LoginRes.fromMap(res.data);
      isLogged.value = true;

      return resData;
    } catch (e) {
      isLogged.value = false;
      resData.code = "99";
      resData.msg = e.toString();
      return resData;
      //   Get.offAllNamed("/JoinPage");
      //   return false;
    }
  }

  void upDateNickNmAndCustName(String nickNm, String custNm) {
    resLoginData.update((val) {
      val!.nickNm = nickNm;
      val.custNm = custNm;
    });
  }

  Future<void> initSupaBaseSession() async {
    try {
      supa.User? supaUser = Supabase.instance.client.auth.currentUser;

      if (supaUser != null) {
        await updateUserInfo(supaUser.id);
        return;
      }

      supaUser = await _trySupabaseLogin();

      supaUser ??= await signUp();

      await updateUserInfo(supaUser.id);
    } catch (e) {
      Lo.g('initSupaBaseSession() error: $e');
      await signUp();
    }
  }

  Future<supa.User?> _trySupabaseLogin() async {
    try {
      AuthResponse authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: resLoginData.value.email,
        password: resLoginData.value.custId!,
      );
      return authRes.session?.user;
    } catch (e) {
      Lo.g('Supabase 로그인 실패: $e');
      return null;
    }
  }

  Future<supa.User> signUp() async {
    Lo.g("Supabase 회원 가입 시도");
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: resLoginData.value.email,
        password: resLoginData.value.custId!,
      );
      return response.user!;
    } catch (e) {
      Lo.g('Supabase 회원가입 실패: $e');
      return (await _trySupabaseLogin())!;
    }
  }

  Future<void> updateUserInfo(String chatUid) async {
    try {
      String name = resLoginData.value.nickNm ?? resLoginData.value.custNm ?? '';
      Map<String, dynamic> metadata = {
        'email': resLoginData.value.email ?? '',
        'custId': resLoginData.value.custId ?? '',
        'nickNm': resLoginData.value.nickNm ?? '',
        'custNm': resLoginData.value.custNm ?? '',
        'selfId': resLoginData.value.custData?.selfId ?? '',
      };

      await SupabaseChatCore.instance
          .updateUser(types.User(id: chatUid, firstName: name, lastName: "", imageUrl: resLoginData.value.profilePath, metadata: metadata));

      await _custRepo.updateChatId(resLoginData.value.custId!, chatUid);
    } catch (e) {
      Lo.g('updateUserInfo() error: $e');
    }
  }

  Future<void> leave() async {
    try {
      // 진행 상황을 사용자에게 알림
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      // 1. 주요 계정 정보 삭제
      CustRepo repo = CustRepo();
      ResData res = await repo.deleteCust(AuthCntr.to.resLoginData.value.custId.toString());
      if (res.code != '00') {
        lo.g('Failed to delete customer data');
      }

      // 2. Supabase 사용자 삭제
      final user = SupabaseChatCore.instance.client.auth.currentUser;

      if (user != null) {
        try {
          // 잠시보류 대화이력이 있는 사람이 탈퇴를 해서 auth user를 삭제 하면 상대방 rooms 를 못가져오는 오류로 일단 로그오프만 시킴.
          // Auth Users 먼저 삭제
          // 모든 방에서 나가기
          await SupabaseChatCore.instance.leaveAllRooms();
          final FunctionResponse data = await SupabaseChatCore.instance.client.functions.invoke('delete-user');
          if (data.status != 200) {
            lo.g('Failed to delete user: ${data.data}');
            lo.g('Failed to delete user: ${data.status}');
          }
          await SupabaseChatCore.instance.client.auth.signOut();
        } catch (e) {
          await SupabaseChatCore.instance.client.auth.signOut();
        }
      }

      // 3. 소셜 로그인 연결 해제 (병렬 처리)

      switch (resLoginData.value.provider) {
        case 'KAKAO':
          KakaoApi().logOut();
          break;
        case 'NAVER':
          NaverApi().logOut();
          break;
        case 'GOOGLE':
          GoogleApi().logOut();
          break;
        case 'APPLE':
          // Apple은 로그아웃 API가 없으므로 로컬 토큰만 삭제
          break;
      }
      // 4. 로컬 스토리지 정리 및 상태 초기화
      await removeAll();
      // await Get.deleteAll();

      // 진행 상황 다이얼로그 닫기

      Get.back();

      //
      resLoginData.value = LoginRes();
      custId.value = '';
      isLogged.value = false;

      // 사용자에게 앱 재시작 알림
      await Get.dialog(
        AlertDialog(
          title: const Text('회원 탈퇴 완료'),
          content: const Text('회원 탈퇴가 완료되었습니다.\n\n그동안 감사드립니다.'),
          actions: [
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Get.back();
                // Get.offAllNamed('/JoinPage');
                if (Platform.isIOS) {
                  exit(0);
                } else {
                  SystemNavigator.pop();
                }
              },
            ),
          ],
        ),
      );
    } catch (e) {
      // 진행 상황 다이얼로그 닫기
      Get.back();
      // 에러 발생 시 사용자에게 알림
      Utils.alert('회원탈퇴 실패: $e');
      lo.g('Leave process failed: ${e}');
      lo.g('Leave process failed: ${e.toString()}');
    }
  }
}

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:project1/repo/common/res_data.dart';
// import 'package:project1/repo/cust/cust_repo.dart';
// import 'package:project1/app/auth/cntr/login_data.dart';
// import 'package:project1/repo/secure_storge.dart';
// import 'package:project1/utils/StringUtils.dart';
// import 'package:project1/utils/log_utils.dart';

// import 'package:project1/utils/utils.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:gotrue/gotrue.dart' as supa;
// import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

// class AuthBinding implements Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<AuthCntr>(() => AuthCntr());
//   }
// }

// class AuthCntr extends GetxController with SecureStorage {
//   static AuthCntr get to => Get.find();

//   Rx<LoginRes> resLoginData = LoginRes().obs;

//   RxBool isLogged = false.obs;

//   //로그인 방식
//   RxString custId = "".obs;

//   late String fcmId = "";

//   String currentChatId = "";

//   @override
//   void onInit() async {
//     super.onInit();
//     loginCheck();
//   }

//   void loginCheck() async {
//     Lo.g("loginCheck 시작!! ");
//     isLogged.value = false;

//     // 테스트 중 - 스토리지 초기화
//     //await removeAll();
//     //회원번호 가져오기
//     custId.value = (await getCustId()) ?? '';
//     Lo.g("custId : ${custId.value}");
//     if (StringUtils.isEmpty(custId.value)) {
//       Get.offAndToNamed("/JoinPage");
//       return;
//     }
//     await login();
//     return;
//   }

//   Future<void> login() async {
//     Stopwatch stopwatch = Stopwatch()..start();
//     lo.g('login : ${custId.value}');
//     if (StringUtils.isEmpty(custId.value)) {
//       Utils.alert("로그인 정보가 없습니다.");
//       return;
//     }

//     //fcmID 발급
//     try {
//       fcmId = await FirebaseMessaging.instance.getToken() ?? "0000000000";
//     } catch (e) {
//       lo.g("fcmId 발급 에러 : $e");
//       fcmId = "0000000000";
//     }

//     lo.g('@@@  login FCM  =>. ${stopwatch.elapsed}');
//     Lo.g("fcmId : $fcmId");
//     CustRepo repo = CustRepo();
//     ResData res = await repo.login(custId.value, fcmId);
//     if (res.code != "00") {
//       Utils.alert(res.msg.toString());
//       isLogged.value = false;
//       Utils.alert("네트워크가 불안정 합니다. 잠시 후 다시 시도해주세요.");
//       // Get.offAndToNamed("/JoinPage");
//       return;
//     }
//     lo.g('@@@  login 1  =>. ${stopwatch.elapsed}');
//     isLogged.value = true;

//     resLoginData.value = LoginRes.fromMap(res.data);
//     stopwatch.stop();
//     lo.g('@@@  login 2  =>. ${stopwatch.elapsed}');

//     //chatId 없으면 채팅서버와 회원가입 또는 로그인 처리한다.
//     if (resLoginData.value.chatId == '' || resLoginData.value.chatId == null) {
//       await initSupaBaseSession();
//     }

//     update();

//     // Get.offAndToNamed("/rootPage");
//   }

//   //회원가입시
//   Future<bool> signUpProc(String _custId) async {
//     custId.value = _custId;
//     await saveCustId(_custId);
//     //fcmID 발급
//     fcmId = await FirebaseMessaging.instance.getToken() ?? "0000000000";
//     Lo.g("fcmId : $fcmId");
//     CustRepo repo = CustRepo();
//     ResData res = await repo.login(custId.value, fcmId);
//     if (res.code != "00") {
//       Utils.alert(res.msg.toString());
//       isLogged.value = false;
//       Get.offAllNamed("/JoinPage");
//       return false;
//     }

//     resLoginData.value = LoginRes.fromMap(res.data);
//     isLogged.value = true;
//     var requestStatus = await Permission.notification.request();

//     update();
//     // Get.offAllNamed("/rootPage");
//     return true;
//   }

//   Future<void> initSupaBaseSession() async {
//     try {
//       // 1.세션이 존재하는지 체크 한다.
//       supa.User? supaUser = Supabase.instance.client.auth.currentUser;

//       lo.g('Supabase 세션에 회원 체크 : supaUser : $supaUser');
//       if (supaUser != null) {
//         await updateUserInfo(supaUser!.id);
//         return;
//       }

//       // 2.없으면 로그인을 시도한다.
//       lo.g("로그인 시도 1: ${resLoginData.value.email} / ${resLoginData.value.custId}");
//       AuthResponse authRes = await Supabase.instance.client.auth.signInWithPassword(
//         email: Get.find<AuthCntr>().resLoginData.value.email,
//         password: Get.find<AuthCntr>().resLoginData.value.custId!,
//       );
//       supaUser = authRes.session?.user;
//       lo.g("로그인 시도 결과 : $supaUser");

//       if (supaUser != null) {
//         await updateUserInfo(supaUser!.id);
//         return;
//       }

//       // 4.로그인이 안되면 회원가입을 시도한다.
//       signUp();

//       Supabase.instance.client.auth.onAuthStateChange.listen((data) {
//         lo.g('Supabase onAuthStateChange : ${data.session}');
//         lo.g('Supabase onAuthStateChange: $supaUser');

//         supaUser = data.session?.user;
//         Utils.alertIcon('Supabase 세션에 회원 체크 : _user : $supaUser', icontype: 'W');
//       });
//     } catch (e) {
//       lo.g('initSupaBaseSession() error : $e');
//       signUp();
//     }
//   }

//   Future<supa.User> signUp() async {
//     lo.g("회원 가입 시도");

//     try {
//       final response = await Supabase.instance.client.auth.signUp(
//         email: resLoginData.value.email,
//         password: resLoginData.value.custId!,
//       );
//       await updateUserInfo(response.user!.id);
//       return response.user!;
//     } catch (e) {
//       lo.g('error : $e');
//       lo.g('error : ${Get.find<AuthCntr>().resLoginData.value.email}');
//       lo.g('error : ${Get.find<AuthCntr>().resLoginData.value.custId}');
//       AuthResponse authRes = await Supabase.instance.client.auth.signInWithPassword(
//         email: Get.find<AuthCntr>().resLoginData.value.email,
//         password: Get.find<AuthCntr>().resLoginData.value.custId!,
//       );

//       supa.User _supaUser = authRes.session!.user;
//       return _supaUser;
//     }
//   }

//   Future<void> updateUserInfo(String chatUid) async {
//     try {
//       String name = resLoginData.value.nickNm ?? '';
//       if (resLoginData.value.nickNm == 'null' || resLoginData.value.nickNm == null || resLoginData.value.nickNm == '') {
//         name = resLoginData.value.custNm!;
//       }

//       Map<String, dynamic> metadata = {
//         'email': resLoginData.value.email ?? '',
//         'custId': resLoginData.value.custId ?? '',
//         'nickNm': resLoginData.value.nickNm ?? '',
//         'custNm': resLoginData.value.custNm ?? '',
//         'selfId': resLoginData.value.custData?.selfId ?? '',
//       };
//       // supabase chat 서버에 회원정보 업데이트
//       await SupabaseChatCore.instance
//           .updateUser(types.User(id: chatUid, firstName: name, lastName: "", imageUrl: resLoginData.value.profilePath, metadata: metadata));
//       supa.User? _supaUser = Supabase.instance.client.auth.currentUser;

//       // 우리 서버 ChatId 업데이트 처리
//       CustRepo repo = CustRepo();
//       repo.updateChatId(resLoginData.value.custId!, chatUid);
//     } catch (e) {
//       lo.g('updateUserInfo() error : $e');
//     }
//   }
// }
