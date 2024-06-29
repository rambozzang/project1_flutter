import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/chatting/data/signup_data.dart';
import 'package:project1/repo/chatting/data/update_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatRepo {
  // 최초가입시 간단하게
  // email , password(uid) , firstName , lastName , imageUrl

  // 그 이후 사용자 수정할때 업데이트 처리
  // firstName , lastName , imageUrl 만 업데이트

  Future<ResData> signup(ChatSignupData data) async {
    ResData resData = ResData();
    try {
      resData.code = '99';

      if (data.email == null || data.uid == null || data.firstName == null) {
        Utils.alert('채팅서버 가입  : email or uid or firstName 필수값 입니다.');
        resData.msg = '채팅서버 가입  : email or uid or firstName 필수값 입니다.';
        return resData;
      }
      // supabase 회원가입
      final response = await Supabase.instance.client.auth.signUp(
        email: data.email,
        password: data.uid.toString(),
      );

      log('supabase Result : ${response.user!.id}');

      await SupabaseChatCore.instance.updateUser(
        types.User(firstName: data.firstName ?? '', id: response.user!.id, lastName: '', imageUrl: data.imageUrl),
      );
      resData.code = '00';
      resData.data = response.user!.id;
      return resData;
    } catch (e) {
      log('Kakao supabase signUp Result : $e');
      Utils.alert(e.toString());
      resData.msg = e.toString();
      return resData;
    }
  }

  // 사용자 정보 업데이트
  Future<ResData> updateUserino(ChatUpdateData data) async {
    ResData resData = ResData();
    try {
      resData.code = '99';

      if (data.uid == null || data.firstName == null) {
        Utils.alert('채팅서버 가입  : email or uid or firstName 필수값 입니다.');
        resData.msg = '채팅서버 가입  : email or uid or firstName 필수값 입니다.';
        return resData;
      }

      var resLoginData = Get.find<AuthCntr>().resLoginData.value;
      String name = resLoginData.nickNm ?? '';
      if (resLoginData.nickNm == 'null' || resLoginData.nickNm == null || resLoginData.nickNm == '') {
        name = resLoginData.custNm!;
      }
      Map<String, dynamic> metadata = {
        'email': resLoginData.email ?? '',
        'custId': resLoginData.custId ?? '',
        'nickNm': resLoginData.nickNm ?? '',
        'custNm': resLoginData.custNm ?? '',
        'selfId': resLoginData.custData?.selfId ?? '',
      };

      await SupabaseChatCore.instance.updateUser(
        types.User(firstName: name, id: data.uid!, lastName: '', imageUrl: data.imageUrl, metadata: metadata),
      );
      resData.code = '00';
      resData.msg = '업데이트 성공';
      return resData;
    } catch (e) {
      log('Kakao supabase signUp Result : $e');
      Utils.alert(e.toString());
      resData.msg = e.toString();
      return resData;
    }
  }
}