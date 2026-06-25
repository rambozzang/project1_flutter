import 'package:flutter/material.dart';

/// 시간대별 "살아 있는 하늘" 그라데이션 엔진.
///
/// 기존 낮/밤 2색 팔레트의 단조로움을 해결하기 위해,
/// 하루를 9개 키프레임(심야·여명·일출·아침·한낮·오후·노을·땅거미·밤)으로 나누고
/// 현재 시각에 맞춰 두 키프레임을 부드럽게 보간(lerp)한다.
///
/// 각 팔레트는 위(상공)→아래(지평선) 4단계로,
/// 대기 산란을 흉내 내 지평선 쪽에 따뜻한 빛을 둔다.
class SkyGradient {
  SkyGradient._();

  /// (기준 시각, [상공, 상단중간, 하단중간, 지평선]) 키프레임.
  /// 색은 모두 채도를 절제한 자연광 톤 — 네온/형광 배제.
  static const List<_SkyStop> _keyframes = [
    // 심야 — 검정
    _SkyStop(0.0, [Color(0xFF000000), Color(0xFF030305), Color(0xFF060609), Color(0xFF0A0A0D)]),
    // 여명(미명) — 인디고에서 보랏빛, 지평선에 흐릿한 장밋빛 예고
    _SkyStop(5.0, [Color(0xFF0E1733), Color(0xFF293056), Color(0xFF5A3F6B), Color(0xFF9C5E5E)]),
    // 일출 — 차가운 푸름 위로 복숭아빛·황금빛 지평선
    _SkyStop(6.5, [Color(0xFF1C3E72), Color(0xFF55669F), Color(0xFFC77E8C), Color(0xFFF2B065)]),
    // 아침 — 맑은 하늘색, 지평선은 옅은 햇무리
    _SkyStop(8.0, [Color(0xFF235699), Color(0xFF4A82C0), Color(0xFF8FB8E0), Color(0xFFCFE4F4)]),
    // 한낮 — 가장 채도 높은 천정 블루
    _SkyStop(12.0, [Color(0xFF1568C0), Color(0xFF3A8DD6), Color(0xFF79B6E8), Color(0xFFC7E2F6)]),
    // 오후 — 푸름이 살짝 따뜻해지기 시작
    _SkyStop(16.5, [Color(0xFF225FA8), Color(0xFF4A84C2), Color(0xFF9FBAD8), Color(0xFFE6DCB4)]),
    // 노을 — 깊은 블루 위로 보라·자홍·주황의 불타는 지평선
    _SkyStop(18.5, [Color(0xFF15224D), Color(0xFF5A3A78), Color(0xFFB14A7C), Color(0xFFF0823F)]),
    // 땅거미(블루아워) — 검정
    _SkyStop(20.0, [Color(0xFF000000), Color(0xFF030305), Color(0xFF060609), Color(0xFF0A0A0D)]),
    // 밤 — 검정
    _SkyStop(22.0, [Color(0xFF000000), Color(0xFF030305), Color(0xFF060609), Color(0xFF0A0A0D)]),
  ];

  /// 그라데이션 색 멈춤점. 지평선의 따뜻한 빛이 화면 하단 ~22%에 모이도록 압축.
  static const List<double> stops = [0.0, 0.5, 0.78, 1.0];

  static const Alignment begin = Alignment.topCenter;
  static const Alignment end = Alignment.bottomCenter;

  /// 현재 시각에 해당하는 4단계 하늘색을 보간해 반환.
  static List<Color> colorsFor(DateTime time) {
    final double hour = time.hour + time.minute / 60.0;

    // 현재 시각을 감싸는 두 키프레임을 찾는다(자정 wrap-around 포함).
    _SkyStop from = _keyframes.last; // 기본: 밤(22h)
    _SkyStop to = _keyframes.first; // → 심야(다음날 0h)
    double fromHour = from.hour - 24.0; // 22 - 24 = -2 로 환산해 wrap 처리
    double toHour = to.hour; // 0

    for (int i = 0; i < _keyframes.length; i++) {
      final cur = _keyframes[i];
      final nxt = i + 1 < _keyframes.length ? _keyframes[i + 1] : null;
      if (nxt != null && hour >= cur.hour && hour < nxt.hour) {
        from = cur;
        to = nxt;
        fromHour = cur.hour;
        toHour = nxt.hour;
        break;
      }
    }

    final double span = (toHour - fromHour);
    final double t = span == 0 ? 0 : ((hour - fromHour) / span).clamp(0.0, 1.0);

    return List<Color>.generate(
      4,
      (i) => Color.lerp(from.colors[i], to.colors[i], t)!,
    );
  }

  /// 현재 시각의 그라데이션 위젯용 데코레이션.
  static BoxDecoration decoration(DateTime time) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: colorsFor(time),
        stops: stops,
      ),
    );
  }

  /// 지평선 빛이 강한 시간(일출·노을)일수록 1.0에 가까운 "따뜻함" 지표.
  /// 별/달 등 야간 요소의 투명도 제어에 쓸 수 있음.
  static double nightFactor(DateTime time) {
    final double hour = time.hour + time.minute / 60.0;
    // 20시~다음날 5시를 밤(1.0), 7~18시를 낮(0.0)으로 보고 가장자리는 부드럽게.
    if (hour >= 20 || hour < 5) return 1.0;
    if (hour >= 7 && hour < 18) return 0.0;
    if (hour >= 5 && hour < 7) return (7 - hour) / 2.0; // 새벽 페이드아웃
    return (hour - 18) / 2.0; // 저녁 페이드인 (18~20시)
  }
}

class _SkyStop {
  final double hour;
  final List<Color> colors;
  const _SkyStop(this.hour, this.colors);
}
