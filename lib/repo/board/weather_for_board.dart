import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weathergogo/cntr/data/current_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/location_service.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/board/data/board_save_weather_data.dart';
import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_repo.dart';
import 'package:project1/utils/log_utils.dart';

/// 영상 게시용 날씨 수집기.
///
/// 화면에서 미리 날씨를 가져오느라 기다리지 않고,
/// 게시(파일 업로드) 시점에 업로드와 "병렬"로 호출되어
/// 위치·날씨·미세먼지를 모아 [BoardSaveWeatherData]로 돌려준다.
/// 어떤 단계가 실패해도 기본값으로 채워 게시를 막지 않는다.
class WeatherForBoard {
  WeatherForBoard._();

  static Future<BoardSaveWeatherData> fetch() async {
    final vo = BoardSaveWeatherData()
      ..boardId = 0
      ..city = ''
      ..country = ''
      ..tempMax = ''
      ..tempMin = ''
      ..location = '대한민국'
      ..lat = '1'
      ..lon = '1'
      ..currentTemp = '0'
      ..humidity = '1'
      ..speed = '1'
      ..sky = '1'
      ..rain = '0'
      ..weatherInfo = '맑음'
      ..mist10 = '0'
      ..mist25 = '0';

    final cntr = Get.isRegistered<WeatherGogoCntr>() ? Get.find<WeatherGogoCntr>() : null;

    try {
      // 1. 현재 위치
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      final location = LatLng(position.latitude, position.longitude);
      vo.lat = location.latitude.toString();
      vo.lon = location.longitude.toString();

      final locationService = LocationService();

      // 2. 지명 (실패 시 컨트롤러 캐시로 보정)
      var (sido, name) = await locationService.getLocalName(location);
      if (name == null || name.isEmpty) {
        name = cntr?.currentLocation.value.name;
      }
      if (sido == null || sido.isEmpty) {
        sido = cntr?.currentLocation.value.addr?.split(' ').first;
      }
      if (name != null && name.isNotEmpty) vo.location = name;

      // 3. 미세먼지
      try {
        if (sido != null && sido.isNotEmpty) {
          final mist = await locationService.getMistData(sido);
          if (mist != null) {
            vo.mist10 = mist.mist10Grade.toString();
            vo.mist25 = mist.mist25Grade.toString();
          }
        }
      } catch (e) {
        lo.g('WeatherForBoard 미세먼지 실패: $e');
      }

      // 4. 날씨 (기본값은 홈 화면 캐시, 가능하면 현위치 초단기예보로 갱신)
      CurrentWeatherData w = cntr?.currentWeather.value ?? CurrentWeatherData();
      try {
        final List<ItemSuperFct> fct = await WeatherGogoRepo().getSuperFctListJson(location);
        if (fct.isNotEmpty) {
          final d = fct.first.fcstDate.toString();
          final t = fct.first.fcstTime.toString();
          for (final item in fct) {
            if (item.fcstDate.toString() == d && item.fcstTime.toString() == t) {
              switch (item.category) {
                case 'T1H':
                  w.temp = item.fcstValue;
                  break;
                case 'PTY':
                  w.rain = item.fcstValue;
                  break;
                case 'SKY':
                  w.sky = item.fcstValue;
                  break;
                case 'REH':
                  w.humidity = item.fcstValue;
                  break;
                case 'WSD':
                  w.speed = item.fcstValue;
                  break;
              }
            }
          }
        }
      } catch (e) {
        lo.g('WeatherForBoard 초단기예보 실패(캐시 사용): $e');
      }

      w.description = WeatherDataProcessor.instance.combineWeatherCondition(w.sky.toString(), w.rain.toString());

      vo.currentTemp = w.temp ?? '0';
      vo.humidity = w.humidity?.toString() ?? '1';
      vo.speed = w.speed?.toString() ?? '1';
      vo.sky = w.sky?.toString() ?? '1';
      vo.rain = w.rain?.toString() ?? '0';
      vo.weatherInfo = w.description ?? '맑음';
    } catch (e) {
      lo.g('WeatherForBoard.fetch 실패(기본값 게시): $e');
    }

    return vo;
  }
}
