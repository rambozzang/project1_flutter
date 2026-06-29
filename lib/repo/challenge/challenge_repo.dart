import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/challenge/data/challenge_complete_data.dart';
import 'package:project1/repo/challenge/data/challenge_me_data.dart';
import 'package:project1/repo/challenge/data/challenge_today_data.dart';
import 'package:project1/repo/common/res_data.dart';

class ChallengeRepo {
  Future<ResData> getTodayChallenge(String custId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/challenge/today';
      Response response = await dio.post(url, data: {'custId': custId});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }

  Future<ResData> completeChallenge(int challengeId, String custId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/challenge/complete';
      Response response = await dio.post(url, data: {
        'challengeId': challengeId,
        'custId': custId,
      });
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }

  Future<ResData> getMyChallengeStatus(String custId, int challengeId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/challenge/me?custId=$custId&challengeId=$challengeId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }

  static ChallengeTodayData? parseTodayData(dynamic data) {
    if (data == null) return null;
    return ChallengeTodayData.fromMap(data as Map<String, dynamic>);
  }

  static ChallengeCompleteData? parseCompleteData(dynamic data) {
    if (data == null) return null;
    return ChallengeCompleteData.fromMap(data as Map<String, dynamic>);
  }

  static ChallengeMeData? parseMeData(dynamic data) {
    if (data == null) return null;
    return ChallengeMeData.fromMap(data as Map<String, dynamic>);
  }
}
