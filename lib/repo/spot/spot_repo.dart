import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/spot/data/spot_data.dart';
import 'package:project1/utils/log_utils.dart';

/// 스팟(캠핑·낚시·골프) 날씨 피드 API 클라이언트.
/// (WEATHER_ACTIVATION_API_CONTRACT.md 의 /api/spot/* 계약)
class SpotRepo {
  /// 카테고리·현위치 기준 스팟 목록(거리순) + 각 스팟 현재 날씨.
  Future<List<SpotData>> getSpotList(String category, double lat, double lon) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get(
        '${UrlConfig.baseURL}/spot/list',
        queryParameters: {'category': category, 'lat': lat, 'lon': lon},
      );
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) return [];
      final list = resData.data as List<dynamic>;
      return list.map((e) => SpotData.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      lo.g('SpotRepo.getSpotList error: $e');
      return [];
    }
  }

  /// 특정 스팟 반경의 커뮤니티 영상(기존 피드와 동일한 BoardWeatherListData).
  Future<List<BoardWeatherListData>> getSpotBoard(int spotId, int pageNum, int pageSize) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get(
        '${UrlConfig.baseURL}/spot/board',
        queryParameters: {'spotId': spotId, 'pageNum': pageNum, 'pageSize': pageSize},
      );
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) return [];
      final list = resData.data as List<dynamic>;
      return list.map((e) => BoardWeatherListData.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      lo.g('SpotRepo.getSpotBoard error: $e');
      return [];
    }
  }
}
