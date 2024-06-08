import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/app/auth/cntr/login_data.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';

import 'package:project1/utils/utils.dart';

// class AuthBinding implements Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<AuthCntr>(() => AuthCntr());
//   }
// }

class AuthCntr extends GetxController with SecureStorage {
  static AuthCntr get to => Get.find();

  Rx<LoginRes> resLoginData = LoginRes().obs;

  RxBool isLogged = false.obs;

  //로그인 방식
  RxString custId = "".obs;

  @override
  void onInit() async {
    Lo.g("onInit 시작!! ");
    print(await KakaoSdk.origin);
    super.onInit();
    loginCheck();
  }

  void loginCheck() async {
    Lo.g("loginCheck 시작!! ");
    isLogged.value = false;

    //회원번호 가져오기
    custId.value = (await getCustId()) ?? '';
    Lo.g("custId : ${custId.value}");
    if (StringUtils.isEmpty(custId.value)) {
      Get.offAndToNamed("/OnboardingPage");
      return;
    }
    await login(custId.value);
    return;
  }

  Future<void> login(String custId) async {
    //fcmID 발급
    String fcmId = await FirebaseMessaging.instance.getToken() ?? "0000000000";
    Lo.g("fcmId : $fcmId");
    CustRepo repo = CustRepo();
    ResData res = await repo.login(custId, fcmId);
    if (res.code != "00") {
      Utils.alert(res.msg.toString());
      isLogged.value = false;
      return;
    }

    resLoginData.value = LoginRes.fromMap(res.data);
    isLogged.value = true;
    Get.toNamed("/rootPage");
  }

  //회원가입시
  Future<void> signUpProc(String custId) async {
    await saveCustId(custId).then((value) => login(custId));
  }
}
