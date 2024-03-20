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
  Future<void> saveCustId(String membNo) async {
    debugPrint("[Storage Action] : saveCustId('$membNo')");
    await storage.write(key: "CUST_ID", value: membNo);
  }

  // 사용자 ID 조회
  Future<String?> getCustId() async {
    String? membNo = await storage.read(key: "CUST_ID");
    debugPrint("[Storage Action] : getCustId('$membNo')");
    //테스트를위한 하드코딩
    return '202309120001';
    // return membNo;
  }

  // 사용자 ID 삭제
  Future<void> removeCustId(String membNo) async {
    debugPrint("[Storage Action] : removeCustId('$membNo')");
    await storage.delete(key: "CUST_ID");
  }

  Future<(String?, String?)> getAllData() async {
    return (await storage.read(key: "MEMB_NO"), await storage.read(key: "AUTH_METHOD"));
  }

  Future<void> removeAll() async {
    await storage.deleteAll();
  }
}
