import 'package:project1/app/chatting/lib/flutter_supabase_chat_core.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

// post gresql://postgres.tnxglgjtuhrxxokpxphr:x2pqx8mjEDO5387C@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres

class SupaBaseRepo {
  // SupaBaseRepo._();
  bool isInitialized = false;

// It's handy to then extract the Supabase client in a variable for later uses
  final supabase = Supabase.instance.client;

  // 0. 초기화
  Future<void> initializeFlutterFire() async {
    try {
      User? _user;
      supabase.auth.onAuthStateChange.listen((data) {
        lo.g('Supabase : ${data.session}');
        _user = data.session?.user;
        isInitialized = true;
      });
    } catch (e) {
      Lo.g('initializeFlutterFire error: $e');
    }
  }

  // 1. 회원가입
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      AuthResponse res = await supabase.auth.signUp(email: email, password: password);
      Lo.g('res : $res');
      return res;
    } catch (e) {
      Lo.g('signUp error: $e');
      return Future.error(e);
    }
  }

  // 2. 로그인
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      AuthResponse res = await supabase.auth.signInWithPassword(email: email, password: password);
      Lo.g('res : $res');
      return res;
    } catch (e) {
      Lo.g('signIn error: $e');
      return Future.error(e);
    }
  }

  // 3. 로그아웃
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      Lo.g('signOut error: $e');
    }
  }

  // 4. 채팅방 생성
  Future<void> createRoom(types.User user) async {
    try {
      types.Room room = await SupabaseChatCore.instance.createRoom(user);
      Lo.g('room : $room');
      Lo.g('room : ${room.toString()}');
    } catch (e) {
      Lo.g('createRoom error: $e');
    }
  }

  // 5. 사용자 삭제
  Future<void> removeUser(String chatId) async {
    try {
      await Supabase.instance.client.from('users').delete().eq('id', chatId);
    } catch (e) {
      Lo.g('removeUser 1 error: $e');
    }
    try {
      await Supabase.instance.client.auth.admin.deleteUser(chatId);
    } catch (e) {
      Lo.g('removeUser 2 error: $e');
    }
  }

  // 5. 채팅방 삭제
  // 6. 채팅방 목록 조회
  // 7. 채팅방 입장
  // 8. 채팅방 퇴장
  // 9. 채팅방 메시지 전송
  // 10. 채팅방 메시지 조회
  // 11. 채팅방 메시지 삭제
  // 12. 채팅방 메시지 수정
  // 13. 채팅방 메시지 신고

  // 14. 사용자 정보 변경
  Future<void> updateUserInfo(types.User user) async {
    try {
      await SupabaseChatCore.instance.updateUser(user);
    } catch (e) {
      Lo.g('updateUserInfo error: $e');
    }
  }
}
