import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/utils/log_utils.dart';

/// 2b 미디어 상세 상호작용 — 관람 이력 + 이모지 반응.
class MediaInteractionRepo {
  /// 관람자 목록: [{custId, nickNm, profilePath, viewedAt}] 최근순
  Future<List<Map<String, dynamic>>> viewers(int boardId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/media/viewers', queryParameters: {'boardId': boardId});
      final data = AuthDio.instance.dioResponse(res);
      if (data.code != '00' || data.data is! List) return [];
      return (data.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      lo.g('media viewers error: $e');
      return [];
    }
  }

  /// 반응 요약: {counts:{emoji:n}, mine:[emoji...], total}
  Future<Map<String, dynamic>> reactions(int boardId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/media/reactions', queryParameters: {'boardId': boardId});
      final data = AuthDio.instance.dioResponse(res);
      if (data.code != '00' || data.data is! Map) return {'counts': {}, 'mine': [], 'total': 0};
      return Map<String, dynamic>.from(data.data as Map);
    } catch (e) {
      lo.g('media reactions error: $e');
      return {'counts': {}, 'mine': [], 'total': 0};
    }
  }

  /// 반응 토글 → 갱신된 요약 반환
  Future<Map<String, dynamic>?> toggle(int boardId, String emoji) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/media/reaction/toggle',
          queryParameters: {'boardId': boardId, 'emoji': emoji});
      final data = AuthDio.instance.dioResponse(res);
      if (data.code != '00' || data.data is! Map) return null;
      return Map<String, dynamic>.from(data.data as Map);
    } catch (e) {
      lo.g('media reaction toggle error: $e');
      return null;
    }
  }

  /// 관람 기록(화면 열 때) — 기존 조회수 API 재사용
  Future<void> recordView(int boardId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      await dio.post('${UrlConfig.baseURL}/view/crtviewcount', queryParameters: {'boardId': boardId});
    } catch (e) {
      lo.g('recordView error: $e');
    }
  }
}
