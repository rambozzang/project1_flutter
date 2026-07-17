import 'package:flutter_test/flutter_test.dart';
import 'package:project1/app/weathergogo/cntr/data/daily_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/data/hourly_weather_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/services/weather_forecast_composer.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';

void main() {
  const composer = WeatherForecastComposer();
  final now = DateTime(2026, 7, 15, 15, 30);

  HourlyWeatherData hourly(DateTime date, double temp) =>
      HourlyWeatherData(temp: temp, sky: '1', rain: '0', date: date);

  SevenDayWeather daily(String date) => SevenDayWeather(
        fcstDate: date,
        morning: DayWeatherData(minTemp: '20'),
        afternoon: DayWeatherData(maxTemp: '30'),
      );

  test('겹치는 시간은 HTTP 완료 순서가 아니라 초단기예보를 우선한다', () {
    final result = composer.composeHourly(
      superShortTerm: [hourly(DateTime(2026, 7, 15, 16), 24)],
      shortTerm: [
        hourly(DateTime(2026, 7, 15, 14), 22),
        hourly(DateTime(2026, 7, 15, 16), 25),
        hourly(DateTime(2026, 7, 15, 17), 26),
      ],
      now: now,
    );

    expect(result.map((e) => e.date.hour), [16, 17]);
    expect(result.first.temp, 24);
  });

  test('어제 관측은 최대 6시간 이내의 직전 값으로 예보 축에 맞춘다', () {
    final result = composer.alignYesterday(
      forecast: [hourly(DateTime(2026, 7, 15, 16), 24)],
      observations: [hourly(DateTime(2026, 7, 14, 14), 21)],
    );

    expect(result, hasLength(1));
    expect(result.single.temp, 21);
    expect(result.single.date, DateTime(2026, 7, 14, 16));
  });

  test('일별 조립은 오늘만 제거하고 최종 지역명을 일괄 반영한다', () {
    final result = composer.composeDaily(
      shortTerm: [daily('20260715'), daily('20260716')],
      midTerm: [daily('20260720')],
      now: now,
      lat: 37.5,
      lon: 127.0,
      cityName: '역삼동',
    );

    expect(result.map((e) => e.fcstDate), ['20260716', '20260720']);
    expect(result.every((e) => e.cityName == '역삼동'), isTrue);
    expect(result.every((e) => e.lat == 37.5 && e.lon == 127.0), isTrue);
  });

  test('오늘 최고최저는 오늘 관측, 예보, 현재값만 합산한다', () {
    final result = composer.todayRange(
      observations: [
        hourly(DateTime(2026, 7, 15, 9), 21),
        hourly(DateTime(2026, 7, 14, 9), 5),
      ],
      forecast: [hourly(DateTime(2026, 7, 15, 18), 29)],
      currentTemperature: 25,
      now: now,
    );

    expect(result, [21, 29]);
  });

  test('현재 강수확률은 원본 배열 순서와 무관하게 가장 이른 예보를 선택한다', () {
    const later = ItemFct(
      category: 'POP',
      fcstDate: '20260715',
      fcstTime: '1800',
      fcstValue: '70',
    );
    const earlier = ItemFct(
      category: 'POP',
      fcstDate: '20260715',
      fcstTime: '1600',
      fcstValue: '30',
    );

    expect(
      WeatherDataProcessor.instance
          .findCurrentRainProbability([later, earlier]),
      '30',
    );
  });

  test('단기예보는 기존 규칙대로 조회 시각에서 5시간 이후만 사용한다', () {
    const beforeCutoff = ItemFct(
      category: 'TMP',
      fcstDate: '20260715',
      fcstTime: '2000',
      fcstValue: '25',
    );
    const afterCutoff = ItemFct(
      category: 'TMP',
      fcstDate: '20260715',
      fcstTime: '2100',
      fcstValue: '24',
    );

    final result = WeatherDataProcessor.instance.processShortTermForecast(
      [beforeCutoff, afterCutoff],
      now: now,
    );

    expect(result.map((e) => e.date.hour), [21]);
  });

  test('PTY가 POP 뒤에 와도 강수확률을 강수형태 코드로 덮지 않는다', () {
    const pop = ItemFct(
      category: 'POP',
      fcstDate: '20260715',
      fcstTime: '2100',
      fcstValue: '60',
    );
    const pty = ItemFct(
      category: 'PTY',
      fcstDate: '20260715',
      fcstTime: '2100',
      fcstValue: '1',
    );

    final result = WeatherDataProcessor.instance.processShortTermForecast(
      [pop, pty],
      now: now,
    );

    expect(result.single.rain, '1');
    expect(result.single.rainPo, '60');
  });
}
