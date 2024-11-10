import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeController extends GetxController {
  final storage = const FlutterSecureStorage();
  final _key = 'isDarkMode';

  final _isDarkMode = false.obs;

  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    loadThemeMode();
  }

  // 테마 모드 불러오기
  Future<void> loadThemeMode() async {
    final themeMode = await storage.read(key: _key);
    _isDarkMode.value = themeMode == 'true';
  }

  // 테마 모드 전환
  Future<void> toggleTheme() async {
    var updateMode = !_isDarkMode.value;
    await storage.write(key: _key, value: updateMode.toString());
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeTheme(updateMode ? ThemeData.dark() : ThemeData.light());

    // Get.changeThemeMode((_isDarkMode.value ? ThemeData.dark : ThemeData.light) as ThemeMode);
  }
}
