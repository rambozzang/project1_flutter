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
  String deviceId = "";
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
      String _fcmId = await _getFcmToken();
      fcmId = _fcmId;
      deviceId = await getDeviceId() ?? '';
      ResData res = await _custRepo.login(custId.value, _fcmId);
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

  Future<String> _getFcmToken() async {
    String _fcmId = "";
    try {
      _fcmId = await FirebaseMessaging.instance.getToken() ?? "0000000000";
    } catch (e) {
      Lo.g("fcmId 발급 에러: $e");
      _fcmId = "0000000000";
    }
    Lo.g("fcmId: $_fcmId");
    return _fcmId;
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
    String _fcmId = await _getFcmToken();

    try {
      deviceId = await getDeviceId() ?? '';
      ResData res = await _custRepo.login(custId.value, _fcmId);
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
          content: const Text('회원 탈퇴가 완료되었습니다.\n\n감사합니다.'),
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

  Future<void> logout() async {
    try {
      // 진행 상황을 사용자에게 알림
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      // 1. Supabase 로그아웃
      await SupabaseChatCore.instance.client.auth.signOut();

      // 2. 소셜 로그인 연결 해제
      switch (resLoginData.value.provider) {
        case 'KAKAO':
          await KakaoApi().logOut();
          break;
        case 'NAVER':
          await NaverApi().logOut();
          break;
        case 'GOOGLE':
          await GoogleApi().logOut();
          break;
        case 'APPLE':
          // Apple은 로그아웃 API가 없으므로 별도 처리 불필요
          break;
      }

      // 3. 로컬 스토리지 정리 및 상태 초기화
      await removeAll();

      resLoginData.value = LoginRes();
      custId.value = '';
      isLogged.value = false;

      // 진행 상황 다이얼로그 닫기
      Get.back();

      // 로그아웃 완료 메시지 표시
      await Get.dialog(
        AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('로그아웃이 완료되었습니다.'),
          actions: [
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Get.back();
                Get.offAllNamed('/JoinPage'); // 로그인 페이지로 이동
              },
            ),
          ],
        ),
      );
    } catch (e) {
      // 진행 상황 다이얼로그 닫기
      Get.back();
      // 에러 발생 시 사용자에게 알림
      Utils.alert('로그아웃 실패: $e');
      lo.g('Logout process failed: $e');
    }
  }
}

// 나머지 코드는 그대로 유지
