import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 날씨 메인 화면의 마지막 스냅샷을 로컬(SharedPreferences)에 저장/복원한다.
///
/// stale-while-revalidate: 앱을 다시 열면 저장된 스냅샷을 즉시 그려 빈 화면을 없애고,
/// 백그라운드에서 최신 데이터를 받아 교체한다. 캐시는 부가 기능이라 실패해도 조용히 무시한다.
class WeatherCacheStore {
  static const String _key = 'weather_snapshot_v1';

  Future<void> save(Map<String, dynamic> snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(snapshot));
    } catch (_) {
      // 캐시 저장 실패는 무시(부가 기능).
    }
  }

  Future<Map<String, dynamic>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = json.decode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }
}
