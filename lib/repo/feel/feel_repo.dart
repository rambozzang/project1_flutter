import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/feel/data/feel_ranking_data.dart';

class FeelRepo {
  Future<ResData> getFeelRanking({
    String period = 'WEEKLY',
    int pageNum = 0,
    int pageSize = 20,
  }) async {
    final dio = await AuthDio.instance.getDio();
    try {
      final response = await dio.post(
        '${UrlConfig.baseURL}/feel/ranking',
        data: {'period': period, 'pageNum': pageNum, 'pageSize': pageSize},
      );
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }

  Future<ResData> getAreaFeelStats({required String loX, required String loY}) async {
    final dio = await AuthDio.instance.getDio();
    try {
      final response = await dio.post(
        '${UrlConfig.baseURL}/feel/stats?loX=$loX&loY=$loY',
      );
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }

  static List<FeelRankingData> parseRanking(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => FeelRankingData.fromMap(e))
        .toList();
  }

  /// 지역 체감 통계 응답을 방어적으로 파싱한다.
  /// - List<Map>: code 는 ['feelCd','code','cd','feel'] 중 존재하는 값,
  ///   count 는 ['count','cnt','value','feelCount','total'] 중 존재하는 값.
  /// - Map (예: {"HOT":3,"COLD":5}): key=code, value=count.
  /// - 그 외/에러: [] 반환.
  static List<AreaFeelStat> parseAreaStats(dynamic data) {
    try {
      if (data is List) {
        final result = <AreaFeelStat>[];
        for (final e in data) {
          if (e is! Map) continue;
          final codeVal =
              e['feelCd'] ?? e['code'] ?? e['cd'] ?? e['feel'];
          if (codeVal == null) continue;
          final code = codeVal.toString();
          if (code.isEmpty) continue;
          final countVal = e['count'] ??
              e['cnt'] ??
              e['value'] ??
              e['feelCount'] ??
              e['total'];
          result.add(AreaFeelStat(feelCd: code, count: _coerceInt(countVal)));
        }
        return result;
      }
      if (data is Map) {
        final result = <AreaFeelStat>[];
        data.forEach((key, value) {
          final code = key?.toString() ?? '';
          if (code.isEmpty) return;
          result.add(AreaFeelStat(feelCd: code, count: _coerceInt(value)));
        });
        return result;
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  static int _coerceInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
