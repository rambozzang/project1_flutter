import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/utils/log_utils.dart';

/// 2d 활동 피드 — 앨범의 업로드·댓글·반응·가입 소식(본인 제외, 최신 60건).
class ActivityRepo {
  Future<List<Map<String, dynamic>>> feed(int communityId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/community/activities',
          queryParameters: {'communityId': communityId});
      final data = AuthDio.instance.dioResponse(res);
      if (data.code != '00' || data.data is! List) return [];
      return (data.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      lo.g('activity feed error: $e');
      return [];
    }
  }
}
