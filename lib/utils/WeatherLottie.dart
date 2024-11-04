import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WeatherLottie {
  static const String _assetPath = 'assets/lottie/';

  static const String backgroundAsset = '${_assetPath}background.json';
  static const String dayBgAsset = '${_assetPath}day_bg.json';
  static const String dayMostlyCloudyAsset = '${_assetPath}day_mostly_cloudy.json';
  static const String dayCloudyAsset = '${_assetPath}day_cloudy.json';
  static const String dayCloudy1Asset = '${_assetPath}day_cloudy1.json';
  static const String dayRainAsset = '${_assetPath}day_rain.json';
  static const String daySnowAsset = '${_assetPath}day_snow.json';
  static const String nightDayCloudyAsset = '${_assetPath}night_day_cloudy.json';
  static const String nightDayMostlyCloudyAsset = '${_assetPath}night_day_mostly_cloudy.json';
  static const String nightDayRainAsset = '${_assetPath}night_day_rain.json';
  static const String nightDaySnowAsset = '${_assetPath}night_day_snow.json';
  static const String nightSunAsset = '${_assetPath}night_sun.json';
  static const String rainAsset = '${_assetPath}rain.json';
  static const String stormAsset = '${_assetPath}storm.json';
  static const String sunAsset = '${_assetPath}sun.json';
  static const String sun1Asset = '${_assetPath}sun1.json';
  static const String windAsset = '${_assetPath}wind.json';
  static const String loadingWeatherAsset = '${_assetPath}loading_weather.json';
  static const String locationAsset = '${_assetPath}location.json';
  static const String locationNotFoundAsset = '${_assetPath}location_not_found.json';
  static const String locationServiceAsset = '${_assetPath}location_service.json';
  static const String noInternetAsset = '${_assetPath}no_internet.json';
  static const String failureAsset = '${_assetPath}faliure.json';

  static Widget background() => Lottie.asset(backgroundAsset, fit: BoxFit.cover);
  static Widget dayBg() => Lottie.asset(dayBgAsset, fit: BoxFit.cover);
  static Widget dayMostlyCloudy() => Lottie.asset(dayMostlyCloudyAsset);
  static Widget dayCloudy() => Lottie.asset(dayCloudyAsset);
  static Widget dayCloudy1() => Lottie.asset(dayCloudy1Asset);
  static Widget dayRain() => Lottie.asset(dayRainAsset);
  static Widget daySnow() => Lottie.asset(daySnowAsset);
  static Widget nightDayCloudy() => Lottie.asset(nightDayCloudyAsset);
  static Widget nightDayMostlyCloudy() => Lottie.asset(nightDayMostlyCloudyAsset);
  static Widget nightDayRain() => Lottie.asset(nightDayRainAsset);
  static Widget nightDaySnow() => Lottie.asset(nightDaySnowAsset);
  static Widget nightSun() => Lottie.asset(nightSunAsset);
  static Widget rain() => Lottie.asset(rainAsset);
  static Widget storm() => Lottie.asset(stormAsset);
  static Widget sun() => Lottie.asset(sunAsset);
  static Widget sun1() => Lottie.asset(sun1Asset);
  static Widget wind() => Lottie.asset(windAsset);
  static Widget loadingWeather() => Lottie.asset(loadingWeatherAsset);
  static Widget location() => Lottie.asset(locationAsset);
  static Widget locationNotFound() => Lottie.asset(locationNotFoundAsset);
  static Widget locationService() => Lottie.asset(locationServiceAsset);
  static Widget noInternet() => Lottie.asset(noInternetAsset);
  static Widget failure() => Lottie.asset(failureAsset);

  static bool _isNight() {
    int hour = DateTime.now().hour;
    return hour >= 19 || hour < 6;
  }

  static Widget getWeatherAnimation(String weatherCondition) {
    bool isNight = _isNight();
    switch (weatherCondition.toLowerCase()) {
      case 'sun':
        return isNight ? nightSun() : sun();
      case 'cloudy':
        return isNight ? nightDayCloudy() : dayCloudy();
      case 'mostly_cloudy':
        return isNight ? nightDayMostlyCloudy() : dayMostlyCloudy();
      case 'rain':
        return isNight ? nightDayRain() : dayRain();
      case 'snow':
        return isNight ? nightDaySnow() : daySnow();
      case 'storm':
        return storm();
      case 'wind':
        return wind();
      default:
        return isNight ? nightSun() : sun(); // 기본값으로 맑은 날씨 반환
    }
  }

  // 성능을 위해 사전 로딩
  static Future<void> precacheAllAnimations(BuildContext context) async {
    await Future.wait([
      _precacheAnimation(context, backgroundAsset),
      _precacheAnimation(context, dayBgAsset),
      _precacheAnimation(context, dayMostlyCloudyAsset),
      _precacheAnimation(context, dayCloudyAsset),
      _precacheAnimation(context, dayCloudy1Asset),
      _precacheAnimation(context, dayRainAsset),
      _precacheAnimation(context, daySnowAsset),
      _precacheAnimation(context, nightDayCloudyAsset),
      _precacheAnimation(context, nightDayMostlyCloudyAsset),
      _precacheAnimation(context, nightDayRainAsset),
      _precacheAnimation(context, nightDaySnowAsset),
      _precacheAnimation(context, nightSunAsset),
      _precacheAnimation(context, rainAsset),
      _precacheAnimation(context, stormAsset),
      _precacheAnimation(context, sunAsset),
      _precacheAnimation(context, sun1Asset),
      _precacheAnimation(context, windAsset),
      _precacheAnimation(context, loadingWeatherAsset),
      _precacheAnimation(context, locationAsset),
      _precacheAnimation(context, locationNotFoundAsset),
      _precacheAnimation(context, locationServiceAsset),
      _precacheAnimation(context, noInternetAsset),
      _precacheAnimation(context, failureAsset),
    ]);
  }

  static Future<void> _precacheAnimation(BuildContext context, String asset) async {
    final provider = AssetLottie(asset);
    await provider.load();
  }
}
