import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/privacy_policy_dialog.dart';
import 'package:project1/services/analytics_service.dart';
import 'package:project1/repo/api/google_api.dart';
import 'package:project1/repo/api/kakao_api.dart';
import 'package:project1/repo/api/naver_api.dart';
import 'package:project1/repo/attendance/attendance_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/app/auth/cntr/login_data.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

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

  // 프리미엄 구독 상태(로그인 응답 premiumYn 기준). 광고 제거 + 프리미엄 날씨 unlock.
  final RxBool isPremium = false.obs;
  // 앨범 저장 용량 티어: 'FREE' | 'PRO'
  final RxString storageTier = "FREE".obs;

  //개인정보 처리 동의
  RxBool privacyPolicyAgreed = false.obs;
  RxBool termsOfServiceAgreed = false.obs;
  RxBool marketingAgreed = false.obs;
  RxBool locationServiceAgreed = false.obs;

  @override
  void onInit() {
    super.onInit();

    // removeAll();

    loginCheck();
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
      isLogged.value = false;
      update();
      String fcmId = await _getFcmToken();
      fcmId = fcmId;
      lo.g("fcmId: $fcmId");
      deviceId = await getDeviceId() ?? '';
      ResData res = await _custRepo.login(custId.value, fcmId);
      if (res.code != "00") {
        if ('회원 정보가 없습니다!' == res.msg) {
          Utils.alert("회원 정보가 없습니다!");
          Get.offAllNamed('/JoinPage');
          return;
        }
        Utils.alert("잠시 후 다시 시도해주세요. ${res.msg}");
        sleep(const Duration(seconds: 3));
        if (Platform.isIOS) {
          exit(0);
        } else {
          SystemNavigator.pop();
        }
        return;
      }
      print("login success res.data: ${res.data}");
      resLoginData.value = LoginRes.fromMap(res.data);
      _syncPremiumFromLogin(res.data);
      isLogged.value = true;
      // 로그인 성공 계측: 사용자 식별 + 속성(login_type/is_premium) + login 이벤트
      AnalyticsService.instance
          .setUser(custId: custId.value, loginType: resLoginData.value.provider, isPremium: isPremium.value);
      AnalyticsService.instance.logLogin(resLoginData.value.provider ?? 'unknown');
      update();

      // 앱 실행 시 출석 체크 (비동기, 로그인 흐름 차단 안 함)
      _checkAttendanceAfterLogin();
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
    String fcmId = "";
    try {
      // ⚠️ getToken()은 타임아웃이 없으면 네트워크/FCM 미준비(특히 콜드 스타트) 시
      // 무한 블록 → 로그인 미완료 → 스플래시(AuthPage)에서 영영 멈춤.
      // 5초 타임아웃으로 폴백해 로그인 흐름이 절대 막히지 않게 한다.
      fcmId = await FirebaseMessaging.instance
              .getToken()
              .timeout(const Duration(seconds: 5), onTimeout: () => "0000000000") ??
          "0000000000";
    } catch (e) {
      Lo.g("fcmId 발급 에러: $e");
      fcmId = "0000000000";
    }
    return fcmId;
  }

  Future<bool> showPrivacyPolicyDialog() async {
    bool? result = await Get.dialog<bool>(
      const PrivacyPolicyDialog(),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  Future<bool> testAgree(String custId) async {
    bool agreed = await Get.toNamed('/AgreePage');
    if (!agreed) {
      Utils.alert('필수 약관에 동의해야 회원가입을 진행할 수 있습니다.');
      return false;
    }
    return true;
  }

  Future<ResData> signUpProc(String custId) async {
    ResData resData = ResData();
    resData.code = "00";

    // bool agreed = await Get.toNamed('/AgreePage/$_custId'); //  await showPrivacyPolicyDialog();
    // if (!agreed) {
    //   resData.code = "99";
    //   resData.msg = "필수 약관에 동의해야 회원가입을 진행할 수 있습니다.";
    //   return resData;
    // }

    this.custId.value = custId;
    await saveCustId(custId);
    String fcmId = await _getFcmToken();

    try {
      deviceId = await getDeviceId() ?? '';
      ResData res = await _custRepo.login(this.custId.value, fcmId);
      if (res.code != "00") {
        resData.code = "99";
        resData.msg = res.msg;
        return resData;
      }
      resLoginData.value = LoginRes.fromMap(res.data);
      _syncPremiumFromLogin(res.data);
      isLogged.value = true;
      // 회원가입 성공 계측: 사용자 식별 + 속성 + sign_up 이벤트
      AnalyticsService.instance
          .setUser(custId: this.custId.value, loginType: resLoginData.value.provider, isPremium: isPremium.value);
      AnalyticsService.instance.logSignUp(resLoginData.value.provider ?? 'unknown');

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

  /// 로그인 응답에서 premiumYn/storageTier를 읽어 프리미엄 상태를 갱신한다.
  void _syncPremiumFromLogin(Map<String, dynamic> data) {
    final bool premium = data['premiumYn'] == 'Y';
    isPremium.value = premium;
    storageTier.value = data['storageTier']?.toString() ?? (premium ? 'PRO' : 'FREE');
  }

  /// 구매/복원 확정 후 프리미엄 활성화(로컬 상태 + 로그인 데이터 반영).
  void applyPremium() {
    isPremium.value = true;
    storageTier.value = 'PRO';
    resLoginData.update((val) {
      val?.premiumYn = 'Y';
      val?.storageTier = 'PRO';
    });
    update();
  }

  /// 프리미엄 해지/만료 시 호출.
  void applyFree() {
    isPremium.value = false;
    storageTier.value = 'FREE';
    resLoginData.update((val) {
      val?.premiumYn = 'N';
      val?.storageTier = 'FREE';
    });
    update();
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

      // 2. 소셜 로그인 연결 해제 (병렬 처리)

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
      isPremium.value = false;
      storageTier.value = 'FREE';

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
      lo.g('Leave process failed: $e');
      lo.g('Leave process failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      // 진행 상황을 사용자에게 알림
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      // 1. Supabase 로그아웃 - 중단됨 주석처리
      // await SupabaseChatCore.instance.client.auth.signOut();

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
      isPremium.value = false;
      storageTier.value = 'FREE';

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

  /// 로그인 성공 후 출석 체크
  Future<void> _checkAttendanceAfterLogin() async {
    try {
      if (custId.value.isEmpty) return;
      final res = await AttendanceRepo().checkAttendance(custId.value, attendanceType: 'OPEN');
      if (res.code == '00') {
        lo.g('출석 체크 완료: ${res.data}');
      } else {
        lo.g('출석 체크 실패: ${res.msg}');
      }
    } catch (e) {
      lo.g('_checkAttendanceAfterLogin error: $e');
    }
  }
}

// 나머지 코드는 그대로 유지
