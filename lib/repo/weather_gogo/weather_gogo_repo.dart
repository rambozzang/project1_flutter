import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/repo/weather_gogo/adapter/adapter_map.dart';
import 'package:project1/repo/weather_gogo/interface/imp_fct_repository.dart';
import 'package:project1/repo/weather_gogo/interface/imp_super_fct_repository.dart';
import 'package:project1/repo/weather_gogo/interface/imp_super_nct_repository.dart';
import 'package:project1/repo/weather_gogo/models/request/weather.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/utils/log_utils.dart';

// https://www.data.go.kr/iim/api/selectAPIAcountView.do
// https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst?serviceKey=CeGmiV26lUPH9guq1Lca6UA25Al%2FaZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur%2Bt2iPaL%2FLtEQdZebg%3D%3D&pageNo=1&numOfRows=1000&dataType=JSON&base_date=20240702&base_time=1314&nx=55&ny=127
// 하루 10000 번 제한
/*

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

  // Texst
  // Future<List<ItemSuperNct>> getYesterDayInfo() async {

  //   /getVilageFcst

  //   final json = await SuperNctRepositoryImp(isLog: isLog).getItemListJSON(weather);

  //   json.map((e) => items.add(e)).toList();

  //   return items;
  // }
  // 초단기 실황조회
  //  X축이 Longitude, Y축이 Latitude
  Future<List<ItemSuperNct>> getYesterDayJson(LatLng latLng, {isLog = false, isChache = false}) async {
    lo.g("################ 1:  ${latLng.longitude} ${latLng.latitude}");

    //위경도를 기상청 좌료로 변경
    //  제주도 126.54587355630036 33.379777816446165 - > nx: 54, ny: 36
    //  서울역 126.970606917394 37.5546788388674 ->  nx: 61, ny: 127
    MapAdapter changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);

    Weather weather = Weather(
      serviceKey: _key,
      pageNo: 1,
      numOfRows: 100,
      nx: changeMap.x,
      ny: changeMap.y,
    );

    final List<ItemSuperNct> items = [];
    final json = await SuperNctRepositoryImp(isLog: isLog).getYesterDayJson(weather, isChache);

    json.map((e) => items.add(e)).toList();

    return items;
  }

  // 초단기 실황조회
  Future<List<ItemSuperNct>> getSuperNctListJson(LatLng latLng, {isLog = false, isChache = false}) async {
    MapAdapter _changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);
    final weather = Weather(
      serviceKey: _key,
      pageNo: 1,
      numOfRows: 100,
      nx: _changeMap.x,
      ny: _changeMap.y,
      dateTime: DateTime.now().subtract(const Duration(hours: 23, minutes: 59, seconds: 01)),
    );
    final List<ItemSuperNct> items = [];
    final json = await SuperNctRepositoryImp(isLog: isLog).getItemListJSON(weather);

    json.map((e) => items.add(e)).toList();

    return items;
  }

  // ### 단기 예보 예제
  Future<List<ItemFct>> getFctListJson({isLog = true}) async {
    lo.g('getFctListJson : ${DateTime.now().subtract(const Duration(hours: 24, minutes: 01, seconds: 01))}');

    final weather = Weather(
      serviceKey: _key,
      pageNo: 1,
      numOfRows: 10,
      dateTime: DateTime.now().subtract(const Duration(hours: 23, minutes: 59, seconds: 01)),
    );
    final List<ItemFct> items = [];
    final json = await FctRepositoryImp(isLog: isLog).getItemListJSON(weather);

    json.map((e) => items.add(e)).toList();

    return items;
  }

  Future<List<ItemSuperFct>> getSuperFctListJson({isLog = false}) async {
    final weather = Weather(
      serviceKey: _key,
    );

    final List<ItemSuperFct> items = [];

    final json = await SuperFctRepositoryImp(isLog: isLog).getItemListJSON(weather);

    json.map((e) => items.add(e)).toList();

    return items;
  }
}
