import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/*
 *  Local Storage 저장 내용
 *   - 사용자 사번
 *   - 인증 방식 (PIN , PAT , BIO)
 */
mixin SecureStorage {
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // 사용자 ID 저장(수정)
  Future<void> saveMembNo(String membNo) async {
    debugPrint("[Storage Action] : saveMembNo('$membNo')");
    await storage.write(key: "MEMB_NO", value: membNo);
  }

  // 사용자 ID 조회
  Future<String?> getMembNo() async {
    String? membNo = await storage.read(key: "MEMB_NO");
    debugPrint("[Storage Action] : getMembNo('$membNo')");
    //테스트를위한 하드코딩
    return '202309120001';
    // return membNo;
  }

  // 사용자 ID 삭제
  Future<void> removeMembNo(String membNo) async {
    debugPrint("[Storage Action] : removeMembNo('$membNo')");
    await storage.delete(key: "MEMB_NO");
  }

  // 인증 방식 저장(수정))
  Future<void> saveAuthMethod(String authMethod) async {
    debugPrint("[Storage Action] : saveAuthMethod('$authMethod')");
    await storage.write(key: "AUTH_METHOD", value: authMethod);
  }

  // 인증 방식 조회
  Future<String?> getAuthMethod() async {
    String? authMethod = await storage.read(key: "AUTH_METHOD");
    debugPrint("[Storage Action] : getAuthMethod('$authMethod')");
    return authMethod;
  }

  // 인증 방식 삭제
  Future<void> removeAuthMethod(String authMethod) async {
    debugPrint("[Storage Action] : removeAuthMethod('$authMethod')");
    await storage.delete(key: "AUTH_METHOD");
  }

  Future<(String?, String?)> getAllData() async {
    return (await storage.read(key: "MEMB_NO"), await storage.read(key: "AUTH_METHOD"));
  }

  Future<void> removeAll() async {
    await storage.deleteAll();
  }
}
