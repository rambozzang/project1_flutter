import 'dart:convert';
import 'package:latlong2/latlong.dart';
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
  midTa // 중기예보(기온)
}

/// 날씨 데이터 캐싱을 관리하는 클래스
class WeatherCache {
  static const String _keyPrefix = 'weather_cache_';

  /// 날씨 데이터를 캐시에 저장
  Future<void> saveWeatherData<T>(LatLng latLng, ForecastType type, T data) async {
    try {
      MapAdapter changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);
      final location = '${changeMap.x}_${changeMap.y}';
      final prefs = await SharedPreferences.getInstance();
      // 캐쉬 전체 삭제
      // await prefs.clear();
      final key = _getCacheKey(location, type);
      final cacheData = {
        'data': _dataToJson(data),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(key, jsonEncode(cacheData));
    } catch (e) {
      lo.g('Error saving weather data to cache: $e');
    }
  }

  /// 캐시에서 날씨 데이터 검색
  Future<T?> getWeatherData<T>(LatLng latLng, ForecastType type) async {
    try {
      MapAdapter changeMap = MapAdapter.changeMap(latLng.longitude, latLng.latitude);
      final location = '${changeMap.x}_${changeMap.y}';
      final prefs = await SharedPreferences.getInstance();
      // await prefs.clear();
      final key = _getCacheKey(location, type);
      final cachedJson = prefs.getString(key);

      if (cachedJson != null) {
        final cachedData = jsonDecode(cachedJson);
        final cachedTime = DateTime.parse(cachedData['timestamp']);
        lo.g('[CACHING] 캐시에서 데이터 로드 cachedTime: ${cachedTime.toString()}');
        if (_isCacheValid(cachedTime, type)) {
          final decodedData = jsonDecode(cachedData['data']);
          return _convertData<T>(decodedData);
        }
      }
    } catch (e) {
      lo.g('Error retrieving weather data from cache: $e');
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
      case ForecastType.superNct:
        return _getNextHourlyUpdateTime(cachedTime, 40);
      case ForecastType.superFct:
        return _getNextHourlyUpdateTime(cachedTime, 45);
      case ForecastType.fct:
        return _getNextSpecificHourUpdateTime(cachedTime, [2, 5, 8, 11, 14, 17, 20, 23]);
      case ForecastType.midFctLand:
      case ForecastType.midTa:
        return _getNextSpecificHourUpdateTime(cachedTime, [6, 18]);
    }
  }

  DateTime _getNextHourlyUpdateTime(DateTime cachedTime, int minute) {
    var nextUpdate = DateTime(cachedTime.year, cachedTime.month, cachedTime.day, cachedTime.hour, minute);
    if (cachedTime.minute >= minute) {
      nextUpdate = nextUpdate.add(const Duration(hours: 1));
    }
    return nextUpdate;
  }

  DateTime _getNextSpecificHourUpdateTime(DateTime cachedTime, List<int> updateHours) {
    var nextHour = updateHours.firstWhere((hour) => hour > cachedTime.hour, orElse: () => updateHours.first);
    if (nextHour <= cachedTime.hour) {
      return DateTime(cachedTime.year, cachedTime.month, cachedTime.day + 1, nextHour);
    }
    return DateTime(cachedTime.year, cachedTime.month, cachedTime.day, nextHour);
  }
}

/// 날씨 서비스 클래스
class WeatherService {
  final WeatherCache _cache = WeatherCache();
  final WeatherGogoRepo _repo = WeatherGogoRepo();

  /// 날씨 데이터 조회 (캐시 확인 후 필요시 API 호출)
  Future<T> getWeatherData<T>(LatLng location, ForecastType type) async {
    try {
      // 캐시 확인
      final cachedData = await _cache.getWeatherData<T>(location, type);
      if (cachedData != null) {
        lo.g('[CACHING] 캐시에서 데이터 로드: ${type.toString()}');
        return cachedData;
      }

      // API 호출
      lo.g('[CACHING] API에서 데이터 로드: ${type.toString()}');
      final result = await _callWeatherAPI<T>(location, type);
      // 새 데이터 캐싱
      await _cache.saveWeatherData<T>(location, type, result);

      return result;
    } catch (e) {
      lo.g('Error fetching weather data for ${type.toString()}: $e');
      rethrow;
    }
  }

  /// 날씨 API 호출
  Future<T> _callWeatherAPI<T>(LatLng location, ForecastType type) async {
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
      default:
        throw ArgumentError('Invalid forecast type: $type');
    }
  }
}
