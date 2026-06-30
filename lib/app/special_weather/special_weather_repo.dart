import 'package:project1/app/special_weather/data/special_weather_data.dart';

/// 기상 특보 repository.
/// 현재는 mock 데이터를 제공하며, 백엔드 API가 준비되면 네트워크 호출로 교체한다.
class SpecialWeatherRepo {
  static final List<SpecialWeatherData> _mock = [
    SpecialWeatherData(
      id: '1',
      title: '폭염주의보',
      category: '폭염',
      level: '주의보',
      region: '서울 전역, 인천, 경기 남부, 충청 북부',
      content: '기상청은 서울 전역과 인천, 경기 남부, 충청 북부에 폭염주의보를 발효했습니다. '
          '낮 동안 체감온도가 35도 이상으로 오르는 곳이 많겠습니다. '
          '야외 활동을 자제하고 충분한 수분 섭취와 휴식을 취하시기 바랍니다.',
      issuedAt: DateTime(2026, 6, 30, 9, 0),
      source: '기상청',
      actionTip: '물 자주 마시기, 야외 활동 자제, 쿨센터 이용',
    ),
    SpecialWeatherData(
      id: '2',
      title: '호우경보',
      category: '호우',
      level: '경보',
      region: '부산, 울산, 경상 남부 해안',
      content: '많은 비가 내리면서 저지대 침수와 산사태 위험이 크게 높아지고 있습니다. '
          '하천이나 산간 계곡 접근을 피하고, 재난 문자와 기상 정보를 수시로 확인하세요.',
      issuedAt: DateTime(2026, 6, 29, 18, 30),
      liftedAt: DateTime(2026, 6, 30, 6, 0),
      source: '기상청',
      actionTip: '저지대 대피, 하천 접근 금지, 산사태 주의',
    ),
  ];

  Future<List<SpecialWeatherData>> fetchList() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_mock);
  }

  Future<SpecialWeatherData?> fetchById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _mock.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
