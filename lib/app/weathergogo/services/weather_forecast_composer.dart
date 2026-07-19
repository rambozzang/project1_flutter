import 'package:project1/app/weathergogo/cntr/data/daily_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/data/hourly_weather_data.dart';

/// 여러 백엔드 응답을 날씨 메인 화면의 결정적인 시간축으로 조립한다.
///
/// 네트워크와 GetX에 의존하지 않는 순수 로직으로 유지해 발표 시각 경계,
/// 누락 관측치, API 응답 순서에 따른 회귀를 단위 테스트할 수 있게 한다.
class WeatherForecastComposer {
  const WeatherForecastComposer();

  List<HourlyWeatherData> composeHourly({
    required List<HourlyWeatherData> superShortTerm,
    required List<HourlyWeatherData> shortTerm,
    required DateTime now,
    int limit = 24,
  }) {
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);
    final byHour = <DateTime, HourlyWeatherData>{};

    // 먼 시간대의 단기예보를 먼저 넣고, 겹치는 가까운 시간대는 더 최신인
    // 초단기예보로 덮는다. HTTP 완료 순서와 무관하게 같은 결과가 된다.
    for (final item in [...shortTerm, ...superShortTerm]) {
      final hour = DateTime(
          item.date.year, item.date.month, item.date.day, item.date.hour);
      if (!hour.isBefore(currentHour)) byHour[hour] = item;
    }

    final result = byHour.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result.take(limit).toList();
  }

  List<SevenDayWeather> composeDaily({
    required List<SevenDayWeather> shortTerm,
    required List<SevenDayWeather> midTerm,
    required DateTime now,
    required double lat,
    required double lon,
    required String? cityName,
  }) {
    final today = _dateKey(now);
    // 날짜가 겹치면 더 정확한 단기예보가 남는다(중기를 먼저 깔고 단기로 덮는다).
    // 23시 발표 단기예보는 4일차까지 제공되는 시각대가 있어 중기 D+4와 겹칠 수 있다.
    final byDate = <String, SevenDayWeather>{};
    for (final item in midTerm) {
      final key = item.fcstDate;
      if (key != null) byDate[key] = item;
    }
    for (final item in shortTerm) {
      final key = item.fcstDate;
      if (key == null || key == today) continue;
      byDate[key] = item;
    }
    final result = byDate.values.toList();
    for (final item in result) {
      item
        ..lat = lat
        ..lon = lon
        ..cityName = cityName;
    }
    result.sort((a, b) => (a.fcstDate ?? '').compareTo(b.fcstDate ?? ''));
    return result;
  }

  List<HourlyWeatherData> alignYesterday({
    required List<HourlyWeatherData> forecast,
    required List<HourlyWeatherData> observations,
    int limit = 24,
    Duration tolerance = const Duration(hours: 6),
  }) {
    if (forecast.isEmpty || observations.isEmpty) return [];
    final sorted = observations.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final aligned = <HourlyWeatherData>[];
    final span = forecast.length < limit ? forecast.length : limit;

    for (var i = 0; i < span; i++) {
      final target = forecast[i].date.subtract(const Duration(days: 1));
      final observation = findAtOrBefore(sorted, target, tolerance: tolerance);
      aligned.add(observation == null
          ? HourlyWeatherData(
              temp: double.infinity, sky: '', rain: '', date: target)
          : HourlyWeatherData(
              temp: observation.temp,
              sky: observation.sky,
              rain: observation.rain,
              rainPo: observation.rainPo,
              date: target,
            ));
    }
    while (aligned.isNotEmpty && !aligned.last.temp.isFinite) {
      aligned.removeLast();
    }
    return aligned;
  }

  HourlyWeatherData? findAtOrBefore(
    List<HourlyWeatherData> sortedObservations,
    DateTime target, {
    Duration tolerance = const Duration(hours: 6),
  }) {
    HourlyWeatherData? candidate;
    for (final item in sortedObservations) {
      if (item.date.isAfter(target)) break;
      candidate = item;
    }
    if (candidate == null || target.difference(candidate.date) > tolerance) {
      return null;
    }
    return candidate;
  }

  double? yesterdayDifference({
    required double? currentTemperature,
    required List<HourlyWeatherData> observations,
    required DateTime now,
  }) {
    if (currentTemperature == null || observations.isEmpty) return null;
    final sorted = observations.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final yesterday =
        findAtOrBefore(sorted, now.subtract(const Duration(hours: 24)));
    if (yesterday == null) return null;
    return double.parse(
        (currentTemperature - yesterday.temp).toStringAsFixed(1));
  }

  List<double>? todayRange({
    required List<HourlyWeatherData> observations,
    required List<HourlyWeatherData> forecast,
    required double? currentTemperature,
    required DateTime now,
  }) {
    bool isToday(DateTime value) =>
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    final values = <double>[
      ...observations.where((e) => isToday(e.date)).map((e) => e.temp),
      ...forecast.where((e) => isToday(e.date)).map((e) => e.temp),
      if (currentTemperature != null) currentTemperature,
    ].where((value) => value.isFinite).toList();
    if (values.isEmpty) return null;
    values.sort();
    return [values.first, values.last];
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';
}
