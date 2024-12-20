import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/weather/data/weather_view_data.dart';
import 'package:project1/repo/weather_gogo/models/request/weather_cache_req.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project1/repo/weather_gogo/adapter/adapter_map.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/fct_version/fct_version_model.dart';
import 'package:project1/repo/weather_gogo/models/response/midland_fct/midlan_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/midta_fct/midta_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_repo.dart';
import 'package:project1/utils/log_utils.dart';

/// 날씨 예보 유형을 정의하는 열거형
enum ForecastType {
  superNctYesterDay, // 어제 24시간
  superNct, // 초단기실황
  superFct, // 초단기예보
  fct, // 단기예보
  midFctLand, // 중기예보(육상)
  midTa, // 중기예보(기온)
  weatherAlert, // 새로운 기상 특보 타입 추가
  mistInfo
}

// 초단기실황: 매시 40분 이후 업데이트
// 초단기예보: 매시 45분 이후 업데이트
// 단기예보: 02:10, 05:10, 08:10, 11:10, 14:10, 17:10, 20:10, 23:10 업데이트
// 중기예보: 06:00, 18:00 업데이트

/// 날씨 데이터 캐싱을 관리하는 클래스
class WeatherCache {
  static const String _keyPrefix = 'weather_cache_';

  final WeatherGogoRepo wrepo = WeatherGogoRepo();

  /// 날씨 데이터를 캐시에 저장
  Future<void> saveWeatherData<T>(LatLng latLng, ForecastType type, T data) async {
    try {
      MapAdapter changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);
      final location = '${changeMap.x}_${changeMap.y}';
      // final prefs = await SharedPreferences.getInstance();
      // 캐쉬 전체 삭제
      // await prefs.clear();
      final key = _getCacheKey(location, type);
      // final cacheData1 = {
      //   "data": _dataToJson(data),
      //   "timestamp": DateTime.now().toIso8601String(),
      // };
      final cacheData1 = jsonEncode({
        "data": json.decode(_dataToJson(data)),
        "timestamp": DateTime.now().toIso8601String(),
      });

      DateTime expiresAt = _calculateExpiresAt(type);

      WeatherCacheReq req = WeatherCacheReq(
        cacheKey: key,
        forecastType: type.toString(),
        cacheData: cacheData1,
        contentType: 'application/json',
        loX: changeMap.x.toString(),
        loY: changeMap.y.toString(),
        expiresAt: expiresAt,
      );
      late var stopwatch;
      stopwatch = Stopwatch()..start();
      ResData resData = await wrepo.saveWeatherCacheData(req);
      if (resData.code != '00') {
        lo.g('saveWeatherCacheData() resData.data : ${resData.data}');
      }
      lo.g('saveWeatherCacheData time: $type  ${stopwatch.elapsedMilliseconds}ms');
      stopwatch.stop();
    } catch (e) {
      lo.g('Error saving weather data to cache: $e');
    }
  }

  /// 캐시에서 날씨 데이터 검색
  Future<T?> getWeatherData<T>(LatLng latLng, ForecastType type) async {
    try {
      MapAdapter changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);
      final location = '${changeMap.x}_${changeMap.y}';
      final key = _getCacheKey(location, type);

      ResData resData = await wrepo.getWeatherCacheData(key);

      if (resData.code == '00') {
        var rawString = resData.data['cacheData'];
        final decodedJson = json.decode(rawString);
        final cachedTime = DateTime.parse(decodedJson['timestamp']);
        final decodedData = decodedJson['data'];
        // lo.g('[CACHING] 캐시에서 데이터 로드 : ${cachedTime.toString()} : ${type.toString()}');
        return _convertData<T>(decodedData);
      }
      return null;
    } catch (e) {
      lo.g('Error retrieving weather data from cache: $e');
      return null;
    }
    return null;
  }

  /// 데이터를 JSON 문자열로 변환
  String _dataToJson<T>(T data) {
    if (data is List) {
      return jsonEncode(data.map((e) => e is Map ? e : e.toJson()).toList());
    } else if (data is Map) {
      return jsonEncode(data);
    } else if (data is MidLandFcstResponse) {
      return jsonEncode(data.toJson());
    } else if (data is MidTaResponse) {
      return jsonEncode(data.toJson());
    } else if (data is MistViewData) {
      return jsonEncode(data.toJson());
    } else {
      throw ArgumentError('Unsupported type for JSON conversion: ${data.runtimeType}');
    }
  }

  /// JSON 데이터를 원하는 타입으로 변환
  T _convertData<T>(dynamic data) {
    if (T == List<ItemSuperNct>) {
      return (data as List).map((item) => ItemSuperNct.fromJson(item)).toList() as T;
    } else if (T == List<ItemSuperFct>) {
      return (data as List).map((item) => ItemSuperFct.fromJson(item)).toList() as T;
    } else if (T == List<ItemFct>) {
      return (data as List).map((item) => ItemFct.fromJson(item)).toList() as T;
    } else if (T == MidLandFcstResponse) {
      return MidLandFcstResponse.fromJson(data!) as T;
    } else if (T == MidTaResponse) {
      return MidTaResponse.fromJson(data!) as T;
    } else if (T == List<ItemFctVersion>) {
      return (data as List).map((item) => ItemFctVersion.fromJson(item)).toList() as T;
    } else if (T == MistViewData) {
      return MistViewData.fromJson(data) as T;
    }
    throw ArgumentError('Unsupported type: $T');
  }

  /// 캐시 키 생성
  String _getCacheKey(String location, ForecastType type) {
    return '${_keyPrefix}${type.toString()}_$location';
  }

  /// 캐시 유효성 검사
  bool _isCacheValid(DateTime cachedTime, ForecastType type) {
    final now = DateTime.now();
    final nextUpdateTime = _getNextUpdateTime(cachedTime, type);
    return now.isBefore(nextUpdateTime);
  }

  /// 다음 업데이트 시간 계산
  DateTime _getNextUpdateTime(DateTime cachedTime, ForecastType type) {
    switch (type) {
      case ForecastType.superNctYesterDay:
        return _getNextHourlyUpdateTime(cachedTime, 40);
      case ForecastType.superNct:
        return _getNextSuperNctUpdateTime(cachedTime);
      case ForecastType.superFct:
        return _getNextSuperFctUpdateTime(cachedTime);
      case ForecastType.fct:
        return _getNextFctUpdateTime(cachedTime);
      case ForecastType.midFctLand:
      case ForecastType.midTa:
        return _getNextMidFctUpdateTime(cachedTime);
      case ForecastType.weatherAlert:
        return _getNextWeatherAlertUpdateTime(cachedTime);
      case ForecastType.mistInfo:
        return _getNextMistInfoUpdateTime(cachedTime);
    }
  }

  DateTime _getNextWeatherAlertUpdateTime(DateTime cachedTime) {
    // 기상 특보는 수시로 업데이트될 수 있으므로, 30분마다 갱신하도록 설정
    return cachedTime.add(const Duration(minutes: 30));
  }

  DateTime _getNextHourlyUpdateTime(DateTime cachedTime, int minute) {
    var nextUpdate = DateTime(cachedTime.year, cachedTime.month, cachedTime.day, cachedTime.hour, minute);
    if (cachedTime.minute >= minute) {
      nextUpdate = nextUpdate.add(const Duration(hours: 1));
    }
    return nextUpdate;
  }

  DateTime _getNextSuperNctUpdateTime(DateTime cachedTime) {
    // 초단기실황: 매시 40분 이후 업데이트
    return _getNextHourlyUpdateTime(cachedTime, 40);
  }

  DateTime _getNextSuperFctUpdateTime(DateTime cachedTime) {
    // 초단기예보: 매시 45분 이후 업데이트
    return _getNextHourlyUpdateTime(cachedTime, 45);
  }

  DateTime _getNextMistInfoUpdateTime(DateTime cachedTime) {
    // 미세먼지: 매시 5분 이후 업데이트
    return _getNextHourlyUpdateTime(cachedTime, 5);
  }

  DateTime _getNextFctUpdateTime(DateTime cachedTime) {
    // 단기예보: 02:10, 05:10, 08:10, 11:10, 14:10, 17:10, 20:10, 23:10 업데이트
    var updateHours = [2, 5, 8, 11, 14, 17, 20, 23];
    var nextHour = updateHours.firstWhere((hour) => hour > cachedTime.hour, orElse: () => updateHours.first);

    var nextUpdate = DateTime(cachedTime.year, cachedTime.month, cachedTime.day, nextHour, 10);
    if (nextHour <= cachedTime.hour && cachedTime.minute >= 10) {
      nextUpdate = nextUpdate.add(const Duration(days: 1));
    }
    return nextUpdate;
  }

  DateTime _getNextMidFctUpdateTime(DateTime cachedTime) {
    // 중기예보: 06:00, 18:00 업데이트
    var updateHours = [6, 18];
    var nextHour = updateHours.firstWhere((hour) => hour > cachedTime.hour, orElse: () => updateHours.first);

    var nextUpdate = DateTime(cachedTime.year, cachedTime.month, cachedTime.day, nextHour);
    if (nextHour <= cachedTime.hour) {
      nextUpdate = nextUpdate.add(const Duration(days: 1));
    }
    return nextUpdate;
  }

  /// expiresAt 계산
  DateTime _calculateExpiresAt(ForecastType type) {
    final now = DateTime.now();
    switch (type) {
      case ForecastType.superNctYesterDay:
      case ForecastType.superNct:
        return _getNextHourlyUpdateTime(now, 40);
      case ForecastType.superFct:
        return _getNextHourlyUpdateTime(now, 45);
      case ForecastType.fct:
        return _getNextFctUpdateTime(now);
      case ForecastType.midFctLand:
      case ForecastType.midTa:
        return _getNextMidFctUpdateTime(now);
      case ForecastType.weatherAlert:
        return now.add(const Duration(minutes: 30));
      case ForecastType.mistInfo:
        return _getNextMistInfoUpdateTime(now);
    }
  }
}

/// 날씨 서비스 클래스
class WeatherService {
  final WeatherCache _cache = WeatherCache();
  final WeatherGogoRepo _repo = WeatherGogoRepo();

  /// 날씨 데이터 조회 (캐시 확인 후 필요시 API 호출)
  Future<T> getWeatherData<T>(LatLng location, ForecastType type, {String? param1}) async {
    try {
      // 캐시 확인
      final cachedData = await _cache.getWeatherData<T>(location, type);
      if (cachedData != null) {
        // lo.g('[CACHING] 캐시에서 데이터 로드 : ${type.toString()}');
        return cachedData;
      }

      // compute 호출
      // RootIsolateToken 생성
      final RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
      // API 호출 및 데이터 처리는 백그라운드 Isolate에서 수행
      final result = await compute(
        _callWeatherAPI<T>,
        _FetchParams(location, type, rootIsolateToken),
      );

      // API 호출
      // final result = await _callWeatherAPI2<T>(location, type);
      // if (result == null || result is List && result.isEmpty) {
      //   throw Exception('Api 호출 결과값이 Null 입니다. ');
      // }

      lo.g('[CACHING] API에서 데이터 로드 : ${type.toString()}');

      if (result == null || result is List && result.isEmpty) {
        throw Exception('Api 호출 결과값이 Null 입니다. ');
      }

      if (type == ForecastType.superNctYesterDay) {
        result as List<ItemSuperNct>;
        if (result.length > 21) {
          _cache.saveWeatherData<T>(location, type, result);
        }
      } else {
        // 새 데이터 캐싱
        _cache.saveWeatherData<T>(location, type, result);
      }

      return result;
    } catch (e) {
      lo.e('Error getWeatherData() data for ${type.toString()}: $e');
      rethrow;
    }
  }

  /// 날씨 API 호출
  Future<T> _callWeatherAPI<T>(_FetchParams params) async {
    final location = params.location;
    final type = params.type;
    // 백그라운드 Isolate에서 플랫폼 채널 초기화
    BackgroundIsolateBinaryMessenger.ensureInitialized(params.rootIsolateToken);

    switch (type) {
      case ForecastType.superNctYesterDay:
        return await _repo.getYesterDayJson(location, isLog: true, isChache: false) as T;
      case ForecastType.superNct:
        return await _repo.getSuperNctListJson(location, isLog: true, isChache: false) as T;
      case ForecastType.superFct:
        return await _repo.getSuperFctListJson(location, isLog: true, isChache: false) as T;
      case ForecastType.fct:
        return await _repo.getFctListJson(location, isLog: true, isChache: false) as T;
      case ForecastType.midFctLand:
        return await _repo.getMidFctJson(location, isLog: true) as T;
      case ForecastType.midTa:
        return await _repo.getMidTaJson(location, isLog: true) as T;
      case ForecastType.weatherAlert:
        return await _repo.getSpecialAlertJson(location, isLog: true) as T;
      // case ForecastType.mistInfo:
      //   return await _repo.getSpecialFctJson(location, isLog: true) as T;
      default:
        throw ArgumentError('Invalid forecast type: $type');
    }
  }

  /// 날씨 API 호출
  Future<T> _callWeatherAPI2<T>(LatLng location, ForecastType type) async {
    switch (type) {
      case ForecastType.superNctYesterDay:
        return await _repo.getYesterDayJson(location, isLog: true, isChache: false) as T;
      case ForecastType.superNct:
        return await _repo.getSuperNctListJson(location, isLog: true, isChache: false) as T;
      case ForecastType.superFct:
        return await _repo.getSuperFctListJson(location, isLog: true, isChache: false) as T;
      case ForecastType.fct:
        return await _repo.getFctListJson(location, isLog: true, isChache: false) as T;
      case ForecastType.midFctLand:
        return await _repo.getMidFctJson(location, isLog: true) as T;
      case ForecastType.midTa:
        return await _repo.getMidTaJson(location, isLog: true) as T;
      case ForecastType.weatherAlert:
        return await _repo.getSpecialAlertJson(location, isLog: true) as T;
      // case ForecastType.mistInfo:
      //   return await _repo.getSpecialFctJson(location, isLog: true) as T;
      default:
        throw ArgumentError('Invalid forecast type: $type');
    }
  }
}

class _FetchParams {
  final LatLng location;
  final ForecastType type;
  final RootIsolateToken rootIsolateToken;

  _FetchParams(this.location, this.type, this.rootIsolateToken);
}


// 어제 날ㅆ 가져오기 경우의수




