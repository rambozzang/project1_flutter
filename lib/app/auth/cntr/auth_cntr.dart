import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
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

  Rx<LoginRes> resLoginData = LoginRes().obs;

  RxBool isLogged = false.obs;

  //로그인 방식
  RxString custId = "".obs;

  late String fcmId = "";

  String currentChatId = "";

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
    Stopwatch stopwatch = Stopwatch()..start();
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

    lo.g('@@@  login FCM  =>. ${stopwatch.elapsed}');
    Lo.g("fcmId : $fcmId");
    CustRepo repo = CustRepo();
    ResData res = await repo.login(custId.value, fcmId);
    if (res.code != "00") {
      Utils.alert(res.msg.toString());
      isLogged.value = false;
      Utils.alert("네트워크가 불안정 합니다. 잠시 후 다시 시도해주세요.");
      // Get.offAndToNamed("/JoinPage");
      return;
    }
    lo.g('@@@  login 1  =>. ${stopwatch.elapsed}');
    isLogged.value = true;

    resLoginData.value = LoginRes.fromMap(res.data);
    stopwatch.stop();
    lo.g('@@@  login 2  =>. ${stopwatch.elapsed}');

    //chatId 없으면 채팅서버와 회원가입 또는 로그인 처리한다.
    if (resLoginData.value.chatId == '' || resLoginData.value.chatId == null) {
      await initSupaBaseSession();
    }

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
    var requestStatus = await Permission.notification.request();

    update();
    // Get.offAllNamed("/rootPage");
    return true;
  }

  Future<void> initSupaBaseSession() async {
    try {
      // 1.세션이 존재하는지 체크 한다.
      supa.User? supaUser = Supabase.instance.client.auth.currentUser;

      lo.g('Supabase 세션에 회원 체크 : supaUser : $supaUser');
      if (supaUser != null) {
        await updateUserInfo(supaUser!.id);
        return;
      }

      // 2.없으면 로그인을 시도한다.
      lo.g("로그인 시도 1: ${resLoginData.value.email} / ${resLoginData.value.custId}");
      AuthResponse authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: Get.find<AuthCntr>().resLoginData.value.email,
        password: Get.find<AuthCntr>().resLoginData.value.custId!,
      );
      supaUser = authRes.session?.user;
      lo.g("로그인 시도 결과 : $supaUser");

      if (supaUser != null) {
        await updateUserInfo(supaUser!.id);
        return;
      }

      // 4.로그인이 안되면 회원가입을 시도한다.
      signUp();

      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        lo.g('Supabase onAuthStateChange : ${data.session}');
        lo.g('Supabase onAuthStateChange: $supaUser');

        supaUser = data.session?.user;
        Utils.alertIcon('Supabase 세션에 회원 체크 : _user : $supaUser', icontype: 'W');
      });
    } catch (e) {
      lo.g('initSupaBaseSession() error : $e');
      signUp();
    }
  }

  Future<supa.User> signUp() async {
    lo.g("회원 가입 시도");

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: resLoginData.value.email,
        password: resLoginData.value.custId!,
      );
      await updateUserInfo(response.user!.id);
      return response.user!;
    } catch (e) {
      lo.g('error : $e');
      lo.g('error : ${Get.find<AuthCntr>().resLoginData.value.email}');
      lo.g('error : ${Get.find<AuthCntr>().resLoginData.value.custId}');
      AuthResponse authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: Get.find<AuthCntr>().resLoginData.value.email,
        password: Get.find<AuthCntr>().resLoginData.value.custId!,
      );

      supa.User _supaUser = authRes.session!.user;
      return _supaUser;
    }
  }

  Future<void> updateUserInfo(String chatUid) async {
    try {
      String name = resLoginData.value.nickNm ?? '';
      if (resLoginData.value.nickNm == 'null' || resLoginData.value.nickNm == null || resLoginData.value.nickNm == '') {
        name = resLoginData.value.custNm!;
      }

      Map<String, dynamic> metadata = {
        'email': resLoginData.value.email ?? '',
        'custId': resLoginData.value.custId ?? '',
        'nickNm': resLoginData.value.nickNm ?? '',
        'custNm': resLoginData.value.custNm ?? '',
        'selfId': resLoginData.value.custData?.selfId ?? '',
      };
      // supabase chat 서버에 회원정보 업데이트
      await SupabaseChatCore.instance
          .updateUser(types.User(id: chatUid, firstName: name, lastName: "", imageUrl: resLoginData.value.profilePath, metadata: metadata));
      supa.User? _supaUser = Supabase.instance.client.auth.currentUser;

      // 우리 서버 ChatId 업데이트 처리
      CustRepo repo = CustRepo();
      repo.updateChatId(resLoginData.value.custId!, chatUid);
    } catch (e) {
      lo.g('updateUserInfo() error : $e');
    }
  }
}
