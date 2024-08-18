import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/repo/weather_gogo/adapter/adapter_map.dart';
import 'package:project1/app/weathergogo/services/regioninfo_util.dart';
import 'package:project1/repo/weather_gogo/interface/imp_fct_repository.dart';
import 'package:project1/repo/weather_gogo/interface/imp_fct_version_repository.dart';
import 'package:project1/repo/weather_gogo/interface/imp_super_fct_repository.dart';
import 'package:project1/repo/weather_gogo/interface/imp_super_nct_repository.dart';
import 'package:project1/repo/weather_gogo/models/enum/data_type.dart';
import 'package:project1/repo/weather_gogo/models/request/midland_fct_req.dart';
import 'package:project1/repo/weather_gogo/models/request/midta_fct_req.dart';
import 'package:project1/repo/weather_gogo/models/request/weather.dart';
import 'package:project1/repo/weather_gogo/models/request/weather_version.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/fct_version/fct_version_model.dart';
import 'package:project1/repo/weather_gogo/models/response/midland_fct/midlan_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/midta_fct/midta_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/weather_gogo/repository/midland_fct_repo.dart';
import 'package:project1/repo/weather_gogo/repository/weather_alert_repo.dart';
import 'package:project1/utils/log_utils.dart';

// https://www.data.go.kr/iim/api/selectAPIAcountView.do
// https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst?serviceKey=CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D&pageNo=1&numOfRows=1000&dataType=JSON&base_date=20240702&base_time=1314&nx=55&ny=127
// 하루 10000 번 제한
/*

초단기실황조회, 초단기예보조회, 단기예보조회 :  Weather class
예보버전 :  WeatherVersion class
*/
class WeatherGogoRepo {
  static const _baseURL = 'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';
  //decoding key 를 사용.
  static const _key = 'CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==';
  static Dio createDio({required bool isLog, PrettyDioLogger? customLogger}) {
    var dio = Dio(BaseOptions(baseUrl: _baseURL));

    if (isLog) {
      final logger = customLogger ?? PrettyDioLogger();
      dio.interceptors.add(logger);
    }
    return dio;
  }

  // 초단기 실황 24시 조회
  //  X축이 Longitude, Y축이 Latitude
  Future<List<ItemSuperNct>> getYesterDayJson(LatLng latLng, {isLog = false, isChache = false}) async {
    lo.g("################ 1:  ${latLng.longitude} ${latLng.latitude}");
    //위경도를 기상청 좌료로 변경
    //  제주도 126.54587355630036 33.379777816446165 - > nx: 54, ny: 36
    //  서울역 126.970606917394 37.5546788388674 ->  nx: 61, ny: 127
    //  서울 홍제 x=126.944267&y=37.588688 => =59&ny=127
    MapAdapter changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);

    Weather weather = Weather(
      serviceKey: _key,
      pageNo: 1,
      numOfRows: 100000,
      nx: changeMap.x,
      ny: changeMap.y,
    );

    final List<ItemSuperNct> items = [];
    final json = await SuperNctRepositoryImp(isLog: isLog).getYesterDayJson(weather, false);

    json.map((e) => items.add(e)).toList();

    return items;
  }

  //----------------------------------------------------------
  // 초단기 실황조회
  //----------------------------------------------------------
  // T1H : 기온 ℃
  // RN1 : 1시간 강수량 mm
  // UUU : 동서바람성분 m/s
  // VVV : 남북바람성분 m/s
  // REH : 습도 %
  // PTY : 강수형태 ㅣ (초단기) 없음(0), 비(1), 비/눈(2), 눈(3), 빗방울(5), 빗방울눈날림(6), 눈날림(7)
  // VEC : 풍량 deg
  // WSD : 풍속
  Future<List<ItemSuperNct>> getSuperNctListJson(LatLng latLng, {isLog = false, isChache = false}) async {
    MapAdapter changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);
    final weather = Weather(
      serviceKey: _key,
      pageNo: 1,
      numOfRows: 1000,
      nx: changeMap.x,
      ny: changeMap.y,
      // dateTime: DateTime.now().subtract(const Duration(hours: 23, minutes: 59, seconds: 01),
      // ),
    );
    final List<ItemSuperNct> items = [];
    final json = await SuperNctRepositoryImp(isLog: isLog).getItemListJSON(weather);

    json.map((e) => items.add(e)).toList();

    return items;
  }

  // 기온
  // 강수확률

  //----------------------------------------------------------
  // 초단기 예보조회 +6시간 정보
  //----------------------------------------------------------
  // T1H	기온	℃
  // RN1	1시간 강수량	범주 (1 mm)
  // SKY	하늘상태	맑음(1), 구름많음(3), 흐림(4)
  // UUU	동서바람성분	m/s
  // VVV	남북바람성분	m/s
  // REH	습도	%
  // PTY	강수형태	(초단기) 없음(0), 비(1), 비/눈(2), 눈(3), 빗방울(5), 빗방울눈날림(6), 눈날림(7)
  // LGT	낙뢰	kA(킬로암페어)
  // VEC	풍향	deg
  // WSD	풍속	m/s
  Future<List<ItemSuperFct>> getSuperFctListJson(LatLng latLng, {isLog = false, isChache = false}) async {
    MapAdapter changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);

    final weather = Weather(
        serviceKey: _key,
        pageNo: 1,
        numOfRows: 10000, //기준시간별 항목이 12개이므로 24시간치 데이터를 가져오기 위해 12 * 24
        nx: changeMap.x,
        ny: changeMap.y);

    final List<ItemSuperFct> items = [];

    final json = await SuperFctRepositoryImp(isLog: isLog).getItemListJSON(weather);

    json.map((e) => items.add(e)).toList();

    return items;
  }

  //----------------------------------------------------------
  // 단기 예보 예제 +3일
  //----------------------------------------------------------
  // POP : 강수확률 %
  // PTY : 강수형태 (단기) 없음(0), 비(1), 비/눈(2), 눈(3), 소나기(4)
  // PCP : 1시간 강수량 범주(1mm)
  // REH : 습도
  // SNO : 1시간 신적설
  // SKY	하늘상태	맑음(1), 구름많음(3), 흐림(4)
  // TMP	1시간 기온	℃
  // TMN	일 최저기온	℃
  // TMX	일 최고기온	℃
  // UUU	풍속(동서성분)	m/s
  // VVV	풍속(남북성분)	m/s
  // WAV	파고	M
  // VEC	풍향	deg
  // WSD	풍속	m/s
  Future<List<ItemFct>> getFctListJson(LatLng latLng, {isLog = false, isChache = false}) async {
    lo.g('getFctListJson : ${DateTime.now().subtract(const Duration(hours: 24, minutes: 01, seconds: 01))}');

    MapAdapter changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);

    final weather = Weather(
      serviceKey: _key,
      pageNo: 1,
      numOfRows: 100000,
      nx: changeMap.x,
      ny: changeMap.y,
      // dateTime: DateTime.now().subtract(const Duration(hours: 23, minutes: 59, seconds: 01),),
    );
    final List<ItemFct> items = [];
    final json = await FctRepositoryImp(isLog: isLog).getItemListJSON(weather);

    json.map((e) => items.add(e)).toList();

    return items;
  }

  // 예보버전
  Future<List<ItemFctVersion>> getFctVersionJson(LatLng latLng, {isLog = true}) async {
    final List<ItemFctVersion> items = [];
    final ItemFctVersion item = ItemFctVersion();
    final weather = WeatherVersion(
      serviceKey: _key,
      pageNo: 1,
      numOfRows: 1000000,
      dataType: DataType.json,
    );

    final json = await FctVersionRepositoryImp(isLog: isLog).getItemListJSON(weather);
    json.map((e) => items.add(e)).toList();

    return items;
  }

  //중기 예보 - 육상 상태 정보
  Future<MidLandFcstResponse?> getMidFctJson(LatLng latLng, {isLog = true}) async {
    try {
      // regId 구하기
      String nearestRegId = findNearestRegId(latLng, '1');

      // 육상 정보
      MidLandFcstRequest req = MidLandFcstRequest(
        serviceKey: _key,
        pageNo: 1,
        numOfRows: 1000,
        regId: nearestRegId,
        tmFc: getTmFc(),
      );
      MidlanFctRepo repo = MidlanFctRepo();
      final res = await repo.getMidLandFcst(req);
      return res;
    } catch (e) {
      lo.g(e.toString());
      return null;
    }
  }

  //중기 예보 - 기온 정보 정보
  Future<MidTaResponse?> getMidTaJson(LatLng latLng, {isLog = true}) async {
    try {
      // regId 구하기
      String nearestRegId = findNearestRegId(latLng, '2');

      // 육상 정보
      MidTaRequest req = MidTaRequest(
        serviceKey: _key,
        pageNo: 1,
        numOfRows: 1000,
        regId: nearestRegId,
        tmFc: getTmFc(),
      );
      MidlanFctRepo repo = MidlanFctRepo();
      MidTaResponse res = await repo.getMidTa(req);
      return res;
    } catch (e) {
      lo.g(e.toString());
      return null;
    }
  }

  // 특보 예보 - 기온 정보 정보
  Future<List<WeatherAlert>> getSpecialFctJson(LatLng latLng, {isLog = true}) async {
    try {
      WeatherAlertAPI weatherAlertAPI = WeatherAlertAPI();
      // regId 구하기
      List<WeatherAlert> list = await weatherAlertAPI.getWeatherAlerts();
      return list;
    } catch (e) {
      lo.g(e.toString());
      return [];
    }
  }

  //
}
