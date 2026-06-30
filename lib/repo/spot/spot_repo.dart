import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/spot/data/spot_data.dart';
import 'package:project1/repo/spot/data/spot_admin_data.dart';
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

  // ───────────────────────── 하이브리드 등록 ─────────────────────────

  /// 사용자 스팟 제보 → 승인대기. 성공 시 (true, 메시지), 실패 시 (false, 메시지).
  Future<(bool, String)> submitSpot({
    required String name,
    required String category,
    required double lat,
    required double lon,
    required int nx,
    required int ny,
    String? addr,
  }) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post(
        '${UrlConfig.baseURL}/spot/submit',
        data: {'name': name, 'category': category, 'lat': lat, 'lon': lon, 'nx': nx, 'ny': ny, 'addr': addr},
      );
      final resData = AuthDio.instance.dioResponse(res);
      return (resData.code == '00', resData.msg?.toString() ?? '');
    } catch (e) {
      lo.g('SpotRepo.submitSpot error: $e');
      return (false, '제보 중 오류가 발생했습니다: $e');
    }
  }

  /// 내가 제보한 스팟 목록(상태 포함).
  Future<List<SpotAdminData>> getMySpots() async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/spot/my');
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) return [];
      final list = resData.data as List<dynamic>;
      return list.map((e) => SpotAdminData.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      lo.g('SpotRepo.getMySpots error: $e');
      return [];
    }
  }

  /// 현재 사용자가 운영자(ADMIN)인지.
  Future<bool> getIsAdmin() async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/spot/isAdmin');
      final resData = AuthDio.instance.dioResponse(res);
      return resData.code == '00' && resData.data == true;
    } catch (e) {
      lo.g('SpotRepo.getIsAdmin error: $e');
      return false;
    }
  }

  /// 운영자: 승인 대기 목록.
  Future<List<SpotAdminData>> getPendingSpots() async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/spot/pending');
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) return [];
      final list = resData.data as List<dynamic>;
      return list.map((e) => SpotAdminData.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      lo.g('SpotRepo.getPendingSpots error: $e');
      return [];
    }
  }

  /// 운영자: 승인.
  Future<bool> approveSpot(int spotId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/spot/approve', queryParameters: {'spotId': spotId});
      final resData = AuthDio.instance.dioResponse(res);
      return resData.code == '00';
    } catch (e) {
      lo.g('SpotRepo.approveSpot error: $e');
      return false;
    }
  }

  /// 운영자: 반려(+사유).
  Future<bool> rejectSpot(int spotId, String reason) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/spot/reject', data: {'spotId': spotId, 'reason': reason});
      final resData = AuthDio.instance.dioResponse(res);
      return resData.code == '00';
    } catch (e) {
      lo.g('SpotRepo.rejectSpot error: $e');
      return false;
    }
  }
}
