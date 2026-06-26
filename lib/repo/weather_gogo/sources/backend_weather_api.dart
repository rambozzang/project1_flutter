import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/utils/log_utils.dart';

/// 우리 백엔드에서 날씨를 가져오는 클라이언트.
/// data.go.kr 직접 호출(429·API 키 노출) 대신 사용.
/// - GET /api/weather/current?nx=&ny=   → 초단기실황 최신 1시간 데이터
/// - GET /api/weather/yesterday?nx=&ny= → 어제 24시간치 시계열
class BackendWeatherApi {
  Future<List<ItemSuperNct>> getCurrentWeather(int nx, int ny) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get(
        '${UrlConfig.baseURL}/weather/current',
        queryParameters: {'nx': nx, 'ny': ny},
      );
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) {
        lo.g('BackendWeatherApi 빈응답(폴백) code=${resData.code} msg=${resData.msg}');
        return [];
      }
      final list = resData.data as List<dynamic>;
      return list.map((e) => ItemSuperNct.fromJson(Map<String, Object?>.from(e as Map))).toList();
    } catch (e) {
      lo.g('BackendWeatherApi.getCurrentWeather error: $e');
      return [];
    }
  }

  Future<List<ItemSuperFct>> getSuperFct(int nx, int ny) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get(
        '${UrlConfig.baseURL}/weather/superfct',
        queryParameters: {'nx': nx, 'ny': ny},
      );
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) {
        lo.g('BackendWeatherApi superFct 빈응답');
        return [];
      }
      final list = resData.data as List<dynamic>;
      return list.map((e) => ItemSuperFct.fromJson(Map<String, Object?>.from(e as Map))).toList();
    } catch (e) {
      lo.g('BackendWeatherApi.getSuperFct error: $e');
      return [];
    }
  }

  Future<List<ItemSuperNct>> getYesterdayWeather(int nx, int ny) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get(
        '${UrlConfig.baseURL}/weather/yesterday',
        queryParameters: {'nx': nx, 'ny': ny},
      );
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) {
        lo.g('BackendWeatherApi 빈응답(폴백) code=${resData.code} msg=${resData.msg}');
        return [];
      }
      final list = resData.data as List<dynamic>;
      return list.map((e) => ItemSuperNct.fromJson(Map<String, Object?>.from(e as Map))).toList();
    } catch (e) {
      lo.g('BackendWeatherApi.getYesterdayWeather error: $e');
      return [];
    }
  }

  Future<List<ItemFct>> getFct(int nx, int ny) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get(
        '${UrlConfig.baseURL}/weather/fct',
        queryParameters: {'nx': nx, 'ny': ny},
      );
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) {
        lo.g('BackendWeatherApi fct 빈응답');
        return [];
      }
      final list = resData.data as List<dynamic>;
      return list.map((e) => ItemFct.fromJson(Map<String, Object?>.from(e as Map))).toList();
    } catch (e) {
      lo.g('BackendWeatherApi.getFct error: $e');
      return [];
    }
  }
}
