import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/repo/community/data/community_member_data.dart';
import 'package:project1/utils/log_utils.dart';

/// 모임(커뮤니티) API 클라이언트. 백엔드 /api/community/* 계약.
class CommunityRepo {
  /// 내가 가입(JOINED)한 모임 목록.
  Future<List<CommunityData>> getMyCommunities() async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/community/my');
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) return [];
      return (resData.data as List).map((e) => CommunityData.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      lo.g('CommunityRepo.getMyCommunities error: $e');
      return [];
    }
  }

  /// 모임 검색(keyword 없으면 추천 - 멤버 많은 순).
  Future<List<CommunityData>> search(String keyword) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/community/search', queryParameters: {'keyword': keyword});
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) return [];
      return (resData.data as List).map((e) => CommunityData.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      lo.g('CommunityRepo.search error: $e');
      return [];
    }
  }

  /// 모임 상세.
  Future<CommunityData?> getDetail(int communityId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/community/detail', queryParameters: {'communityId': communityId});
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) return null;
      return CommunityData.fromMap(Map<String, dynamic>.from(resData.data as Map));
    } catch (e) {
      lo.g('CommunityRepo.getDetail error: $e');
      return null;
    }
  }

  /// 모임 생성. 성공 시 (true, 메시지, communityId).
  Future<(bool, String, int?)> create({
    required String name,
    String? description,
    String? imageUrl,
    int? spotId,
    String isPublic = 'Y',
    String joinType = 'AUTO',
    double? lat,
    double? lon,
  }) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/community/create', data: {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'spotId': spotId,
        'isPublic': isPublic,
        'joinType': joinType,
        'lat': lat,
        'lon': lon,
      });
      final resData = AuthDio.instance.dioResponse(res);
      final ok = resData.code == '00';
      final id = ok && resData.data != null ? (resData.data as num).toInt() : null;
      return (ok, resData.msg?.toString() ?? '', id);
    } catch (e) {
      lo.g('CommunityRepo.create error: $e');
      return (false, '모임 생성 중 오류가 발생했습니다: $e', null);
    }
  }

  /// 가입. 성공 시 (true, status['JOINED'|'PENDING'], 메시지).
  Future<(bool, String, String)> join(int communityId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/community/join', queryParameters: {'communityId': communityId});
      final resData = AuthDio.instance.dioResponse(res);
      final ok = resData.code == '00';
      return (ok, ok ? (resData.data?.toString() ?? 'JOINED') : '', resData.msg?.toString() ?? '');
    } catch (e) {
      lo.g('CommunityRepo.join error: $e');
      return (false, '', '가입 중 오류가 발생했습니다: $e');
    }
  }

  /// 탈퇴.
  Future<(bool, String)> leave(int communityId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/community/leave', queryParameters: {'communityId': communityId});
      final resData = AuthDio.instance.dioResponse(res);
      return (resData.code == '00', resData.msg?.toString() ?? '');
    } catch (e) {
      lo.g('CommunityRepo.leave error: $e');
      return (false, '탈퇴 중 오류가 발생했습니다: $e');
    }
  }

  /// 멤버 목록(비공개는 멤버만).
  Future<List<CommunityMemberData>> getMembers(int communityId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/community/members', queryParameters: {'communityId': communityId});
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) return [];
      return (resData.data as List).map((e) => CommunityMemberData.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      lo.g('CommunityRepo.getMembers error: $e');
      return [];
    }
  }

  /// 승인 대기 목록(방장/매니저).
  Future<List<CommunityMemberData>> getPendingMembers(int communityId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get('${UrlConfig.baseURL}/community/pending', queryParameters: {'communityId': communityId});
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) return [];
      return (resData.data as List).map((e) => CommunityMemberData.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      lo.g('CommunityRepo.getPendingMembers error: $e');
      return [];
    }
  }

  /// 가입 승인(방장/매니저).
  Future<(bool, String)> approve(int communityId, String custId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/community/approve', queryParameters: {'communityId': communityId, 'custId': custId});
      final resData = AuthDio.instance.dioResponse(res);
      return (resData.code == '00', resData.msg?.toString() ?? '');
    } catch (e) {
      lo.g('CommunityRepo.approve error: $e');
      return (false, '승인 중 오류가 발생했습니다: $e');
    }
  }

  /// 모임 피드(원본 ResData) - 풀스크린 뷰어(VideoMyinfoListCntr) 재사용용.
  Future<ResData> getFeedRes(int communityId, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      final res = await dio.get('${UrlConfig.baseURL}/community/feed',
          queryParameters: {'communityId': communityId, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(res);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }
}
