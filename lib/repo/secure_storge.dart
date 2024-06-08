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
    return (await storage.read(key: "CUST_ID"), await storage.read(key: "AUTH_METHOD"));
  }

  Future<void> removeAll() async {
    await storage.deleteAll();
  }

  // 검색어 저장
  Future<List<String>> saveSearchWord(String searchWord) async {
    debugPrint("[Storage Action] : saveSearchWord('$searchWord')");

    String? items = await storage.read(key: "SEARCH_WORD");
    List<String> list = [];
    if (items != null && items.isNotEmpty) {
      list = items.split(",");
    }

    if (list.length > 9) {
      list.removeAt(0);
    }

    if (list.contains(searchWord)) {
      list.remove(searchWord);
    }
    list.add(searchWord);

    await storage.write(key: "SEARCH_WORD", value: list.join(","));
    return list;
  }

  // 검색어 조회
  Future<List<String>> getSearchWord() async {
    // storage.delete(key: "SEARCH_WORD");
    String? items = await storage.read(key: "SEARCH_WORD");
    if (items == null) {
      return [];
    }
    debugPrint("[Storage Action] : getSearchWord('$items')");
    return items.split(",");
  }

  // 검색어 한건 삭제
  Future<List<String>> removeSearchWord(String searchWord) async {
    debugPrint("[Storage Action] : removeSearchWord('$searchWord')");

    String? items = await storage.read(key: "SEARCH_WORD");
    List<String> list = [];
    if (items != null) {
      list = items.split(",");
    }

    if (list.contains(searchWord)) {
      list.remove(searchWord);
    }

    await storage.write(key: "SEARCH_WORD", value: list.join(","));
    return list;
  }

  // 검색어 전체 삭제
  Future<void> removeAllSearchWord() async {
    debugPrint("[Storage Action] : removeAllSearchWord()");
    await storage.delete(key: "SEARCH_WORD");
  }
}
