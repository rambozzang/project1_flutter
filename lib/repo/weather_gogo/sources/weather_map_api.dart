import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/utils/log_utils.dart';

/// 전국 날씨 지도 자료 — 우리 백엔드 `/weather/map/*`.
///
/// 백엔드는 이미 매시간 수집해 둔 230개 좌표의 실황·단기예보를 모아서 준다(기상청 추가
/// 호출 없음). 지진·태풍·레이더·위성은 백엔드가 요청 시에만 기상청을 부르고 10분 보관한다.
///
/// 실패하면 예외 대신 빈 값을 돌려준다 — 지도 화면은 비어 보일 뿐 죽지 않아야 한다.
class WeatherMapApi {
  Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? query}) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}$path', queryParameters: query);
      final resData = AuthDio.instance.dioResponse(res);
      if (resData.code != '00' || resData.data == null) {
        lo.g('WeatherMapApi $path 빈응답 code=${resData.code} msg=${resData.msg}');
        return const {};
      }
      final data = resData.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'list': data};
    } catch (e) {
      lo.g('WeatherMapApi $path 실패: $e');
      return const {};
    }
  }

  /// 전국 실황 — {obsTime, points:[{lat,lon,T1H,RN1,REH,WSD,VEC,PTY}]}
  Future<Map<String, dynamic>> now() => _post('/weather/map/now');

  /// 예보 시각 목록(yyyyMMddHHmm, 오름차순)
  Future<List<String>> forecastTimes() async {
    final res = await _post('/weather/map/forecast/times');
    final list = res['list'];
    return list is List ? list.map((e) => e.toString()).toList() : const [];
  }

  /// 한 시각의 전국 예보 — {time, points:[{lat,lon,TMP,SKY,PTY,POP,PCP,PCP_MM,REH,WSD,SNO,SNO_CM}]}
  Future<Map<String, dynamic>> forecast(String time) =>
      _post('/weather/map/forecast', query: {'time': time});

  /// 강수예측 시각 목록(초단기예보 6시간)
  Future<List<String>> nowcastTimes() async {
    final res = await _post('/weather/map/nowcast/times');
    final list = res['list'];
    return list is List ? list.map((e) => e.toString()).toList() : const [];
  }

  /// 한 시각의 강수예측 — {time, points:[{lat,lon,RN1_MM,LGT,PTY,SKY,T1H}]}
  Future<Map<String, dynamic>> nowcast(String time) => _post('/weather/map/nowcast', query: {'time': time});

  /// 시도별 미세먼지 — {dataTime, points:[{sido,lat,lon,PM10,PM25}]}
  Future<Map<String, dynamic>> air() => _post('/weather/map/air');

  /// {available, items:[기상청 원문]}
  Future<Map<String, dynamic>> earthquakes() => _post('/weather/map/earthquake');

  /// {available, items:[기상청 원문]}
  Future<Map<String, dynamic>> typhoons() => _post('/weather/map/typhoon');

  /// {available, images:[주소]}
  Future<Map<String, dynamic>> radar() => _post('/weather/map/radar');

  /// {available, images:[주소]} — band: ir105(적외) | vi006(가시) | rgbt(컬러)
  Future<Map<String, dynamic>> satellite({String band = 'ir105'}) =>
      _post('/weather/map/satellite', query: {'band': band});

  /// 현재 발효 중인 특보(기존 API 재사용) — [{wrnNm, areaNm, status, tmFc, tmEf, ...}]
  Future<List<dynamic>> warnings() async {
    final res = await _post('/weather/warn/current');
    final list = res['list'];
    return list is List ? list : const [];
  }
}
