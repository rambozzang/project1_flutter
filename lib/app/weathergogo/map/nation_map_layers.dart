import 'package:flutter/material.dart';

/// 지도 오른쪽 버튼 묶음 — 네이버 날씨 지도의 '예보 · 영상 · 관측 · 대기질' 과 같은 구성.
enum NationMapGroup {
  forecast('예보'),
  nowcast('영상'),
  observation('관측'),
  air('대기질');

  const NationMapGroup(this.label);
  final String label;
}

/// 지도에 칠할 수 있는 층.
///
/// 색은 **구간별 단색이 아니라 연속 색 띠**([stops])로 칠한다. 230개 지점 값을 이어 붙여
/// 지도 전체에 색 면을 깔아야 네이버처럼 "어디가 덥고 추운지" 한눈에 읽힌다 — 점마다 색
/// 알약만 흩어 두면 지도가 얼룩덜룩해 보였다(2026-10-13).
enum NationMapLayer {
  // 예보(단기예보 3일)
  temp(NationMapGroup.forecast, '기온', 'TMP', Icons.thermostat_rounded, '°C', _tempStops),
  feel(NationMapGroup.forecast, '체감', 'FEEL', Icons.accessibility_new_rounded, '°C', _tempStops),
  pcp(NationMapGroup.forecast, '강수', 'PCP_MM', Icons.umbrella_rounded, 'mm', _rainStops, sparse: true),
  snow(NationMapGroup.forecast, '적설', 'SNO_CM', Icons.ac_unit_rounded, 'cm', _snowStops, sparse: true),
  humid(NationMapGroup.forecast, '습도', 'REH', Icons.water_drop_outlined, '%', _humidStops),
  wind(NationMapGroup.forecast, '풍속', 'WSD', Icons.air_rounded, 'm/s', _windStops),
  wave(NationMapGroup.forecast, '바다', 'WAV', Icons.waves_rounded, 'm', _waveStops, sparse: true),
  // 영상 › 강수예측(초단기예보 6시간)
  nowRain(NationMapGroup.nowcast, '강수예측', 'RN1_MM', Icons.grain_rounded, 'mm', _rainStops, sparse: true),
  lightning(NationMapGroup.nowcast, '낙뢰예측', 'LGT', Icons.flash_on_rounded, 'kA', _lgtStops, sparse: true),
  // 관측(초단기실황)
  obsTemp(NationMapGroup.observation, '기온', 'T1H', Icons.thermostat_rounded, '°C', _tempStops),
  obsRain(NationMapGroup.observation, '1H 강수', 'RN1', Icons.umbrella_rounded, 'mm', _rainStops, sparse: true),
  obsHumid(NationMapGroup.observation, '습도', 'REH', Icons.water_drop_outlined, '%', _humidStops),
  obsWind(NationMapGroup.observation, '풍속', 'WSD', Icons.air_rounded, 'm/s', _windStops),
  // 대기질(시도 평균)
  pm10(NationMapGroup.air, '미세먼지', 'PM10', Icons.blur_on_rounded, '㎍/㎥', _pm10Stops),
  pm25(NationMapGroup.air, '초미세먼지', 'PM25', Icons.blur_circular_rounded, '㎍/㎥', _pm25Stops);

  const NationMapLayer(this.group, this.label, this.key, this.icon, this.unit, this.stops, {this.sparse = false});

  final NationMapGroup group;
  final String label;

  /// 백엔드 응답에서 꺼낼 값 이름.
  final String key;
  final IconData icon;
  final String unit;

  /// (값, 색) — 오름차순. 사이 값은 섞어서 칠한다.
  final List<(double, Color)> stops;

  /// 비·눈·파도·낙뢰처럼 "없는 곳이 대부분" 인 층. 0 인 곳은 칠하지도, 글자를 찍지도 않는다.
  final bool sparse;

  static List<NationMapLayer> of(NationMapGroup g) => values.where((e) => e.group == g).toList();

  /// 대기질은 17개 시도 평균이라 면으로 이으면 경계가 뭉개진다. 글자만 찍는다.
  bool get paintsField => group != NationMapGroup.air && this != lightning;

  double? value(Map<String, dynamic> p) {
    final v = p[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// 연속 색. sparse 층에서 0 이하면 투명.
  Color colorOf(double v) {
    if (sparse && v <= 0) return Colors.transparent;
    if (v <= stops.first.$1) return stops.first.$2;
    for (var i = 1; i < stops.length; i++) {
      final (b, cb) = stops[i];
      if (v <= b) {
        final (a, ca) = stops[i - 1];
        return Color.lerp(ca, cb, (v - a) / (b - a))!;
      }
    }
    return stops.last.$2;
  }

  /// 지도에 찍을 글자(흰 알약 안). null 이면 이 지점은 건너뛴다.
  String? text(Map<String, dynamic> p) {
    final v = value(p);
    if (v == null) return null;
    if (sparse && v <= 0) return null;
    switch (this) {
      case NationMapLayer.temp:
      case NationMapLayer.feel:
      case NationMapLayer.obsTemp:
        return '${v.round()}°';
      case NationMapLayer.humid:
      case NationMapLayer.obsHumid:
        return '${v.round()}%';
      case NationMapLayer.pcp:
      case NationMapLayer.nowRain:
        return v < 1 ? '~1' : _trim(v);
      case NationMapLayer.obsRain:
      case NationMapLayer.snow:
        return _trim(v);
      case NationMapLayer.wind:
      case NationMapLayer.obsWind:
      case NationMapLayer.wave:
        return v.toStringAsFixed(1);
      case NationMapLayer.lightning:
        return '⚡';
      case NationMapLayer.pm10:
      case NationMapLayer.pm25:
        return '${p['sido'] ?? ''} ${v.round()}';
    }
  }

  /// 범례 막대에 적을 눈금(위가 큰 값).
  List<double> get ticks {
    switch (this) {
      case NationMapLayer.temp:
      case NationMapLayer.feel:
      case NationMapLayer.obsTemp:
        return const [30, 20, 10, 0, -10];
      case NationMapLayer.pcp:
      case NationMapLayer.nowRain:
      case NationMapLayer.obsRain:
        return const [50, 20, 10, 5, 1];
      case NationMapLayer.snow:
        return const [10, 5, 3, 1];
      case NationMapLayer.humid:
      case NationMapLayer.obsHumid:
        return const [100, 80, 60, 40, 20];
      case NationMapLayer.wind:
      case NationMapLayer.obsWind:
        return const [14, 9, 4, 0];
      case NationMapLayer.wave:
        return const [4, 3, 2, 1, 0.5];
      case NationMapLayer.lightning:
        return const [100, 50, 10];
      case NationMapLayer.pm10:
        return const [150, 80, 30];
      case NationMapLayer.pm25:
        return const [75, 35, 15];
    }
  }

  static String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

// ── 색 띠 ─ 네이버·기상청 지도 관례를 따랐다 ──────────────────────

const List<(double, Color)> _tempStops = [
  // 네이버 날씨 지도와 맞췄다 — 20℃ 언저리가 주황빛 노랑, 10℃ 초록, 0℃ 파랑.
  (-15, Color(0xFF3F2C8C)), (-5, Color(0xFF3B6FD8)), (3, Color(0xFF55B6E8)), (9, Color(0xFF6ACB9E)),
  (14, Color(0xFFB7DE6A)), (18, Color(0xFFF4D04A)), (23, Color(0xFFF4A23B)), (28, Color(0xFFE8582F)), (33, Color(0xFFB0222A)),
];
const List<(double, Color)> _rainStops = [
  (0.1, Color(0xFF9ED8F7)), (1, Color(0xFF5BB5F0)), (5, Color(0xFF2E7FE0)), (10, Color(0xFF2350C2)),
  (20, Color(0xFF6B3FC8)), (50, Color(0xFFB02FB0)),
];
const List<(double, Color)> _snowStops = [
  (0.1, Color(0xFFD6E4FF)), (1, Color(0xFFA9C2F5)), (3, Color(0xFF7E98E6)), (5, Color(0xFF6A6FD4)), (10, Color(0xFF5B3FB8)),
];
const List<(double, Color)> _humidStops = [
  (20, Color(0xFFE9B36A)), (40, Color(0xFFE6D98C)), (60, Color(0xFF8FD3B6)), (80, Color(0xFF4FA9DA)), (100, Color(0xFF2B63B8)),
];
const List<(double, Color)> _windStops = [
  (0, Color(0xFFB7E3C8)), (4, Color(0xFF8CCF7A)), (9, Color(0xFFF2C54B)), (14, Color(0xFFE8703A)), (20, Color(0xFFB3262E)),
];
const List<(double, Color)> _waveStops = [
  (0.1, Color(0xFFBFE6F5)), (0.5, Color(0xFF7FC8EC)), (1, Color(0xFF3D9BE0)), (2, Color(0xFF2A5FC4)), (4, Color(0xFF5A2FB0)),
];
const List<(double, Color)> _lgtStops = [
  (1, Color(0xFFFFD54F)), (50, Color(0xFFFF8F00)), (100, Color(0xFFD84315)),
];
const List<(double, Color)> _pm10Stops = [
  (0, Color(0xFF3D8BFD)), (30, Color(0xFF3D8BFD)), (31, Color(0xFF2BB36B)), (80, Color(0xFF2BB36B)),
  (81, Color(0xFFF59A1B)), (150, Color(0xFFF59A1B)), (151, Color(0xFFE5402F)),
];
const List<(double, Color)> _pm25Stops = [
  (0, Color(0xFF3D8BFD)), (15, Color(0xFF3D8BFD)), (16, Color(0xFF2BB36B)), (35, Color(0xFF2BB36B)),
  (36, Color(0xFFF59A1B)), (75, Color(0xFFF59A1B)), (76, Color(0xFFE5402F)),
];
