import 'package:flutter_test/flutter_test.dart';
import 'package:project1/app/weathergogo/cntr/data/daily_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/data/hourly_weather_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/services/weather_forecast_composer.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/midland_fct/midlan_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/midta_fct/midta_fct_res.dart';

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

  test('일별 조립은 날짜가 겹치면 단기예보를 우선한다', () {
    final result = composer.composeDaily(
      shortTerm: [daily('20260716')],
      midTerm: [
        SevenDayWeather(
          fcstDate: '20260716',
          morning: DayWeatherData(minTemp: '99'),
          afternoon: DayWeatherData(maxTemp: '30'),
        ),
        daily('20260720'),
      ],
      now: now,
      lat: 37.5,
      lon: 127.0,
      cityName: '역삼동',
    );

    expect(result.map((e) => e.fcstDate), ['20260716', '20260720']);
    expect(result.first.morning.minTemp, '20');
  });

  test('중기예보 일별은 오늘+4일부터 7일치로 단기예보와 빈틈없이 이어진다', () {
    final land = MidLandFcstResponse(
      regId: '11B00000',
      rnSt4Am: 40,
      rnSt4Pm: 50,
      rnSt5Am: 10,
      rnSt5Pm: 20,
      rnSt6Am: 10,
      rnSt6Pm: 20,
      rnSt7Am: 10,
      rnSt7Pm: 20,
      rnSt8: 30,
      rnSt9: 30,
      rnSt10: 30,
      wf4Am: '맑음',
      wf4Pm: '구름많음',
      wf5Am: '맑음',
      wf5Pm: '맑음',
      wf6Am: '맑음',
      wf6Pm: '맑음',
      wf7Am: '흐림',
      wf7Pm: '흐림',
      wf8: '흐림',
      wf9: '흐림',
      wf10: '흐림',
    );
    final ta = MidTaResponse(
      regId: '11B10101',
      taMin4: 23,
      taMin4Low: 22,
      taMin4High: 24,
      taMax4: 31,
      taMax4Low: 30,
      taMax4High: 32,
      taMin5: 24,
      taMin5Low: 23,
      taMin5High: 25,
      taMax5: 32,
      taMax5Low: 31,
      taMax5High: 33,
      taMin6: 24,
      taMin6Low: 23,
      taMin6High: 25,
      taMax6: 32,
      taMax6Low: 31,
      taMax6High: 33,
      taMin7: 24,
      taMin7Low: 23,
      taMin7High: 25,
      taMax7: 32,
      taMax7Low: 31,
      taMax7High: 33,
      taMin8: 24,
      taMin8Low: 23,
      taMin8High: 25,
      taMax8: 32,
      taMax8Low: 31,
      taMax8High: 33,
      taMin9: 24,
      taMin9Low: 23,
      taMin9High: 25,
      taMax9: 32,
      taMax9Low: 31,
      taMax9High: 33,
      taMin10: 24,
      taMin10Low: 23,
      taMin10High: 25,
      taMax10: 33,
      taMax10Low: 32,
      taMax10High: 34,
    );

    final result = WeatherDataProcessor.instance
        .processMidTermForecast(land, ta, now: DateTime(2026, 7, 19, 18, 45));

    expect(result.map((e) => e.fcstDate), [
      '20260723',
      '20260724',
      '20260725',
      '20260726',
      '20260727',
      '20260728',
      '20260729',
    ]);
    expect(result.first.morning.minTemp, '23');
    expect(result.first.afternoon.maxTemp, '31');
    expect(result.first.morning.skyDesc, '맑음');
    expect(result.first.morning.rainPo, '40');
    expect(result.last.afternoon.maxTemp, '33');
  });
}
