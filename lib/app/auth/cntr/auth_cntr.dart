import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/app/auth/cntr/login_data.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';

import 'package:project1/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthCntr>(() => AuthCntr());
  }
}

class AuthCntr extends GetxController with SecureStorage {
  static AuthCntr get to => Get.find();

  Rx<LoginRes> resLoginData = LoginRes().obs;

  RxBool isLogged = false.obs;

  //로그인 방식
  RxString custId = "".obs;

  late String fcmId = "";

  @override
  void onInit() async {
    super.onInit();
    loginCheck();
  }

  void loginCheck() async {
    Lo.g("loginCheck 시작!! ");
    isLogged.value = false;

    // 테스트 중 - 스토리지 초기화
    //await removeAll();
    //회원번호 가져오기
    custId.value = (await getCustId()) ?? '';
    Lo.g("custId : ${custId.value}");
    if (StringUtils.isEmpty(custId.value)) {
      Get.offAndToNamed("/JoinPage");
      return;
    }
    await login();
    return;
  }

  Future<void> login() async {
    lo.g('login : ${custId.value}');
    if (StringUtils.isEmpty(custId.value)) {
      Utils.alert("로그인 정보가 없습니다.");
      return;
    }

    //fcmID 발급
    try {
      fcmId = await FirebaseMessaging.instance.getToken() ?? "0000000000";
    } catch (e) {
      lo.g("fcmId 발급 에러 : $e");
      fcmId = "0000000000";
    }
    Lo.g("fcmId : $fcmId");
    CustRepo repo = CustRepo();
    ResData res = await repo.login(custId.value, fcmId);
    if (res.code != "00") {
      Utils.alert(res.msg.toString());
      isLogged.value = false;
      Get.offAndToNamed("/JoinPage");
      return;
    }

    resLoginData.value = LoginRes.fromMap(res.data);

    isLogged.value = true;
    update();
    // Get.offAndToNamed("/rootPage");
  }

  //회원가입시
  Future<bool> signUpProc(String _custId) async {
    custId.value = _custId;
    await saveCustId(_custId);
    //fcmID 발급
    fcmId = await FirebaseMessaging.instance.getToken() ?? "0000000000";
    Lo.g("fcmId : $fcmId");
    CustRepo repo = CustRepo();
    ResData res = await repo.login(custId.value, fcmId);
    if (res.code != "00") {
      Utils.alert(res.msg.toString());
      isLogged.value = false;
      Get.offAllNamed("/JoinPage");
      return false;
    }

    resLoginData.value = LoginRes.fromMap(res.data);
    isLogged.value = true;

    update();
    // Get.offAllNamed("/rootPage");
    return true;
  }
}
