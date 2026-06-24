import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/achievement/data/achievement_data.dart';
import 'package:project1/repo/common/res_data.dart';

class AchievementRepo {
  Future<ResData> getMyAchievements() async {
    final dio = await AuthDio.instance.getDio();
    try {
      final response = await dio.post('${UrlConfig.baseURL}/achievement/my');
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }

  static MyAchievementsData? parseMyAchievements(dynamic data) {
    if (data == null) return null;
    return MyAchievementsData.fromMap(data as Map<String, dynamic>);
  }
}
