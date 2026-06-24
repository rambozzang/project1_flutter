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
    if (data == null) return [];
    return (data as List).map((e) => FeelRankingData.fromMap(e as Map<String, dynamic>)).toList();
  }
}
