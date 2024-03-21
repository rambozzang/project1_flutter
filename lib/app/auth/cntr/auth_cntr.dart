import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/data/login_data.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';

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
    super.onInit();
    loginCheck();
  }

  void loginCheck() async {
    Lo.g("loginCheck 시작!! ");

    //회원번호 가져오기
    custId.value = (await getCustId()) ?? '';
    Lo.g("custId : ${custId.value}");

    if (StringUtils.isEmpty(custId.value)) {
      Get.offAndToNamed("/OnboardingPage");
      return;
    }
    //fcmID 발급
    String fcmId = await FirebaseMessaging.instance.getToken() ?? "0000000000";
    Lo.g("fcmId : $fcmId");
    // d1VIL7ciiEuNnjl1tVW17N:APA91bEmNiWagDAstMOiOWV1elPvjTisrykB1LxB5aQ3XnnhBSayxch7N_TfnGOVO0PNtbPTPD0RWREf7BSNnZ0rNLZqaai5yBM6JE_sB3jFhWcEkGsKe26K971O53MmUd9BRBEBPNXG

    //  ResLoginData resLoginData = ResLoginData.fromMap(resData.data);

    //로그인 데이터 저장
    // resLoginData.value = resLoginData;
    await login(custId.value, fcmId);
  }

  Future<void> login(String custId, String fcmId) async {
    CustRepo repo = CustRepo();

    ResData res = await repo.login(custId, fcmId);
    if (res.code != "00") {
      Utils.alert(res.msg.toString());
      Get.offAndToNamed('/JoinPage');
      return;
    }
    resLoginData.value = LoginRes.fromMap(res.data);
    isLogged.value = true;
    Get.offAndToNamed('/rootPage');
  }

  //회원가입시 각각 서비스에서 호출.
  void signUpProc(String custId) {
    saveCustId(custId);
    Get.offAndToNamed('/rootPage');
  }
}
