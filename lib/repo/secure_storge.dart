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
  Future<void> saveCustId(String custId) async {
    debugPrint("[Storage Action] : saveCustId('$custId')");
    await storage.write(key: "CUST_ID", value: custId);
  }

  // 사용자 ID 조회
  Future<String?> getCustId() async {
    String? custId = await storage.read(key: "CUST_ID");
    debugPrint("[Storage Action] : getCustId('$custId')");
    return custId;
  }

  // 사용자 ID 삭제
  Future<void> removeCustId(String custId) async {
    debugPrint("[Storage Action] : removeCustId('$custId')");
    await storage.delete(key: "CUST_ID");
  }

  Future<(String?, String?)> getAllData() async {
    return (
      await storage.read(key: "CUST_ID"),
      await storage.read(key: "AUTH_METHOD")
    );
  }

  Future<void> removeAll() async {
    await storage.deleteAll();
  }
}
