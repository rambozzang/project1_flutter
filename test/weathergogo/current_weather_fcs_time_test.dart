import 'package:flutter_test/flutter_test.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';

/// 화면의 '발표시각'(currentWeather.fcsTime) 출처 검증.
///
/// 배경(2026-07-30): 발표시각이 하루 종일 23:30으로 표시되는 신고가 있었다.
/// 원인은 compareFcsTime이 여러 API의 baseTime 중 '숫자가 큰 쪽'을 취한 것이었다.
/// 초단기예보 발표시각은 HH30이라 23:30~00:44에 들어온 "2330"이 이후 값(0130~2230)보다
/// 항상 커서 고착됐고, 자정 보정은 새 값이 0100 미만일 때만 동작해 하루 한 시간만 풀렸다.
/// 게다가 스냅샷으로 저장돼 앱 재시작 후에도 남았다.
///
/// 수정: 발표시각은 초단기실황(superNct)의 baseTime만 사용한다.
/// 화면에 함께 뜨는 기온·습도·풍향이 모두 실황 값이므로 의미상으로도 이쪽이 맞다.
void main() {
  final processor = WeatherDataProcessor.instance;

  ItemSuperNct item(String category, String value,
          {String baseDate = '20260730', String baseTime = '0900'}) =>
      ItemSuperNct(
        baseDate: baseDate,
        baseTime: baseTime,
        category: category,
        nx: 60,
        ny: 127,
        obsrValue: value,
      );

  test('발표시각은 실황 응답의 baseTime을 그대로 쓴다', () {
    final result = processor.parsingSuperNct([
      item('T1H', '27.3'),
      item('REH', '65'),
      item('WSD', '1.4'),
    ]);

    expect(result.fcsTime, '0900');
    expect(result.fcstDate, '20260730');
  });

  test('실황 발표시각은 항상 정시(HH00)라 화면에 :30이 찍히지 않는다', () {
    // 초단기실황은 매시 정각 발표 → HH00. HH30은 초단기예보의 발표시각이며
    // 이 값이 발표시각으로 흘러들어오면 안 된다.
    for (final hh in ['0000', '0900', '2300']) {
      final result = processor.parsingSuperNct([item('T1H', '20.0', baseTime: hh)]);
      expect(result.fcsTime, hh);
      expect(result.fcsTime!.substring(2, 4), '00',
          reason: '실황 발표시각의 분은 항상 00이어야 한다');
    }
  });

  test('자정 직후 실황(0000)도 그대로 반영된다 — 전날 2330으로 되돌아가지 않는다', () {
    // 회귀 방지의 핵심: 예전 로직은 max(2330, 0000)을 고르며 2330을 유지했다.
    final result = processor.parsingSuperNct(
        [item('T1H', '18.5', baseDate: '20260731', baseTime: '0000')]);

    expect(result.fcsTime, '0000');
    expect(result.fcstDate, '20260731');
  });
}
