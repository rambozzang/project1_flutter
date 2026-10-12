import 'package:flutter/material.dart';

/// 전국 날씨 지도에서 고를 수 있는 층(무엇을 칠할지).
///
/// 값 → (알약 색, 알약 글자) 를 정한다. 색 구간은 기상청·네이버가 쓰는 관례(기온은
/// 파랑→빨강, 강수는 옅은 하늘→짙은 남색)를 따라 처음 보는 사람도 바로 읽히게 했다.
enum NationMapLayer {
  // 예보(단기예보)
  temp('기온', 'TMP', forecast: true),
  pop('강수확률', 'POP', forecast: true),
  pcp('강수량', 'PCP_MM', forecast: true, skipZero: true),
  humid('습도', 'REH', forecast: true),
  wind('풍속', 'WSD', forecast: true),
  snow('적설', 'SNO_CM', forecast: true, skipZero: true),
  // 관측(초단기실황)
  obsTemp('기온', 'T1H'),
  obsRain('1시간 강수', 'RN1', skipZero: true),
  obsHumid('습도', 'REH'),
  obsWind('풍속', 'WSD');

  const NationMapLayer(this.label, this.key, {this.forecast = false, this.skipZero = false});

  final String label;

  /// 백엔드 응답에서 꺼낼 값 이름.
  final String key;
  final bool forecast;

  /// 0 인 곳은 찍지 않는다 — 비·눈은 "오는 곳"만 보여야 읽힌다. 230곳 전부에
  /// "0mm" 알약을 깔면 정작 비가 오는 곳이 묻힌다.
  final bool skipZero;

  static List<NationMapLayer> get forecastLayers => values.where((e) => e.forecast).toList();
  static List<NationMapLayer> get observationLayers => values.where((e) => !e.forecast).toList();

  /// 지도에 찍을 글자. null 이면 이 지점은 건너뛴다.
  String? text(Map<String, dynamic> p) {
    final v = _num(p[key]);
    if (v == null) return null;
    if (skipZero && v <= 0) return null;
    switch (this) {
      case NationMapLayer.temp:
        return '${_sky(p)}${v.round()}°';
      case NationMapLayer.obsTemp:
        return '${_ptyOnly(p)}${v.toStringAsFixed(v.abs() < 10 ? 1 : 0)}°';
      case NationMapLayer.pop:
      case NationMapLayer.humid:
      case NationMapLayer.obsHumid:
        return '${v.round()}%';
      case NationMapLayer.pcp:
        // 백엔드가 "1mm 미만" 을 0.5 로 준다.
        return v < 1 ? '~1mm' : '${_trim(v)}mm';
      case NationMapLayer.obsRain:
        return '${_trim(v)}mm';
      case NationMapLayer.snow:
        return v < 1 ? '~1cm' : '${_trim(v)}cm';
      case NationMapLayer.wind:
      case NationMapLayer.obsWind:
        return '${v.toStringAsFixed(1)}㎧';
    }
  }

  /// 알약 색.
  Color color(Map<String, dynamic> p) {
    final v = _num(p[key]) ?? 0;
    switch (this) {
      case NationMapLayer.temp:
      case NationMapLayer.obsTemp:
        if (v >= 33) return const Color(0xFFB71C1C);
        if (v >= 28) return const Color(0xFFE53935);
        if (v >= 23) return const Color(0xFFF57C00);
        if (v >= 18) return const Color(0xFFF9A825);
        if (v >= 12) return const Color(0xFF43A047);
        if (v >= 5) return const Color(0xFF00897B);
        if (v >= 0) return const Color(0xFF1E88E5);
        if (v >= -10) return const Color(0xFF3949AB);
        return const Color(0xFF311B92);
      case NationMapLayer.pop:
        if (v >= 80) return const Color(0xFF0D47A1);
        if (v >= 60) return const Color(0xFF1565C0);
        if (v >= 40) return const Color(0xFF1E88E5);
        if (v >= 20) return const Color(0xFF64B5F6);
        return const Color(0xFF90A4AE);
      case NationMapLayer.pcp:
      case NationMapLayer.obsRain:
        if (v >= 30) return const Color(0xFF4A148C);
        if (v >= 10) return const Color(0xFF0D47A1);
        if (v >= 3) return const Color(0xFF1565C0);
        if (v >= 1) return const Color(0xFF1E88E5);
        return const Color(0xFF42A5F5);
      case NationMapLayer.humid:
      case NationMapLayer.obsHumid:
        if (v >= 90) return const Color(0xFF01579B);
        if (v >= 70) return const Color(0xFF0288D1);
        if (v >= 50) return const Color(0xFF26A69A);
        if (v >= 30) return const Color(0xFFFFA000);
        return const Color(0xFFE65100);
      case NationMapLayer.wind:
      case NationMapLayer.obsWind:
        if (v >= 14) return const Color(0xFFC62828);
        if (v >= 9) return const Color(0xFFEF6C00);
        if (v >= 4) return const Color(0xFFF9A825);
        return const Color(0xFF43A047);
      case NationMapLayer.snow:
        if (v >= 5) return const Color(0xFF4527A0);
        if (v >= 1) return const Color(0xFF5E35B1);
        return const Color(0xFF7E57C2);
    }
  }

  /// 범례 — (설명, 색) 몇 개.
  List<(String, Color)> get legend {
    switch (this) {
      case NationMapLayer.temp:
      case NationMapLayer.obsTemp:
        return const [
          ('-10↓', Color(0xFF311B92)), ('0', Color(0xFF1E88E5)), ('5', Color(0xFF00897B)),
          ('12', Color(0xFF43A047)), ('18', Color(0xFFF9A825)), ('23', Color(0xFFF57C00)),
          ('28', Color(0xFFE53935)), ('33↑', Color(0xFFB71C1C)),
        ];
      case NationMapLayer.pop:
        return const [
          ('~20%', Color(0xFF90A4AE)), ('20', Color(0xFF64B5F6)), ('40', Color(0xFF1E88E5)),
          ('60', Color(0xFF1565C0)), ('80↑', Color(0xFF0D47A1)),
        ];
      case NationMapLayer.pcp:
      case NationMapLayer.obsRain:
        return const [
          ('~1mm', Color(0xFF42A5F5)), ('1', Color(0xFF1E88E5)), ('3', Color(0xFF1565C0)),
          ('10', Color(0xFF0D47A1)), ('30↑', Color(0xFF4A148C)),
        ];
      case NationMapLayer.humid:
      case NationMapLayer.obsHumid:
        return const [
          ('~30%', Color(0xFFE65100)), ('30', Color(0xFFFFA000)), ('50', Color(0xFF26A69A)),
          ('70', Color(0xFF0288D1)), ('90↑', Color(0xFF01579B)),
        ];
      case NationMapLayer.wind:
      case NationMapLayer.obsWind:
        return const [
          ('~4㎧', Color(0xFF43A047)), ('4', Color(0xFFF9A825)), ('9', Color(0xFFEF6C00)), ('14↑', Color(0xFFC62828)),
        ];
      case NationMapLayer.snow:
        return const [('~1cm', Color(0xFF7E57C2)), ('1', Color(0xFF5E35B1)), ('5↑', Color(0xFF4527A0))];
    }
  }

  static double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// 예보 기온 앞에 하늘 그림 — 비·눈이 오면 그쪽을 우선한다.
  static String _sky(Map<String, dynamic> p) {
    final pty = _num(p['PTY'])?.round() ?? 0;
    if (pty != 0) return _ptyEmoji(pty);
    switch (_num(p['SKY'])?.round()) {
      case 1:
        return '☀️';
      case 3:
        return '⛅';
      case 4:
        return '☁️';
    }
    return '';
  }

  /// 실황에는 하늘 상태가 없다. 비·눈이 올 때만 표시한다.
  static String _ptyOnly(Map<String, dynamic> p) {
    final pty = _num(p['PTY'])?.round() ?? 0;
    return pty == 0 ? '' : _ptyEmoji(pty);
  }

  // 초단기실황: 1 비, 2 비/눈, 3 눈, 5 빗방울, 6 빗방울눈날림, 7 눈날림
  // 단기예보:   1 비, 2 비/눈, 3 눈, 4 소나기
  static String _ptyEmoji(int pty) {
    switch (pty) {
      case 2:
      case 6:
        return '🌨️';
      case 3:
      case 7:
        return '❄️';
      case 4:
        return '🌦️';
      default:
        return '🌧️';
    }
  }
}
