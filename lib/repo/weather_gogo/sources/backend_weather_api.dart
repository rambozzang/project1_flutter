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

  /// 미세먼지 조회 - GET /weather/mist?sidoName=
  Future<Map<String, dynamic>?> getMistData(String sidoName) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get(
        '${UrlConfig.baseURL}/weather/mist',
        queryParameters: {'sidoName': sidoName},
      );
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) {
        lo.g('BackendWeatherApi mist 빈응답');
        return null;
      }
      return Map<String, dynamic>.from(resData.data as Map);
    } catch (e) {
      lo.g('BackendWeatherApi.getMistData error: $e');
      return null;
    }
  }

  /// 중기예보 조회 (육상+기온) - GET /weather/mid?lat=&lng=
  Future<Map<String, dynamic>?> getMidForecast(double lat, double lng) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.get(
        '${UrlConfig.baseURL}/weather/mid',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) {
        lo.g('BackendWeatherApi mid 빈응답');
        return null;
      }
      return Map<String, dynamic>.from(resData.data as Map);
    } catch (e) {
      lo.g('BackendWeatherApi.getMidForecast error: $e');
      return null;
    }
  }

  /// 기상특보 조회 - POST /weather/warn/current
  Future<List<dynamic>> getWeatherWarnings() async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/weather/warn/current');
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) {
        lo.g('BackendWeatherApi warn 빈응답');
        return [];
      }
      return resData.data as List<dynamic>;
    } catch (e) {
      lo.g('BackendWeatherApi.getWeatherWarnings error: $e');
      return [];
    }
  }
}
