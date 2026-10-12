import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/weathergogo/map/nation_map_layers.dart';
import 'package:project1/app/weathergogo/map/nation_weather_map_cntr.dart';
import 'package:project1/app/weathergogo/weather_webview.dart';
import 'package:project1/utils/log_utils.dart';

/// 전국 날씨 지도 — 네이버 날씨 지도와 같은 구성.
///
/// - 오른쪽 세로 버튼: 예보 · 영상 · 관측 · 대기질 / 바람 · CCTV / 특보 · 지진태풍 · 제보.
///   누르면 왼쪽으로 하위 메뉴가 펼쳐지고 고른 버튼은 파란색이 된다.
/// - 지도 전체에 연속 색 면 + 흰 알약 값. 왼쪽 위에 세로 색 막대 범례.
/// - 아래에 어두운 시간 막대(예보·강수예측)와 지점 카드(지도를 누른 곳의 값).
class NationWeatherMapPage extends StatefulWidget {
  const NationWeatherMapPage({super.key});

  static void open() => Get.to(() => const NationWeatherMapPage(), transition: Transition.cupertino);

  @override
  State<NationWeatherMapPage> createState() => _NationWeatherMapPageState();
}

const Color _blue = Color(0xFF2B6CF6);
const Color _ink = Color(0xFF222222);
const Color _sub = Color(0xFF767676);
const List<BoxShadow> _shadow = [BoxShadow(color: Color(0x29000000), blurRadius: 6, offset: Offset(0, 1))];

class _NationWeatherMapPageState extends State<NationWeatherMapPage> {
  late final NationWeatherMapCntr c = Get.put(NationWeatherMapCntr());

  /// 지도 키 초기화는 앱에서 한 번이면 된다.
  /// 옛 NaverMapSdk.initialize 는 폐기된 인증 주소로 붙어 거부됐다(2026-10-13) — 새 방식을 쓴다.
  static Future<void>? _sdkReady;

  @override
  void initState() {
    super.initState();
    _sdkReady ??= FlutterNaverMap().init(
      clientId: '1gvb59zfma',
      onAuthFailed: (e) => lo.g('네이버 지도 인증 실패: $e'),
    );
  }

  @override
  void dispose() {
    Get.delete<NationWeatherMapCntr>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        titleSpacing: 0,
        title: const Text('날씨 지도', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFEBEBEB))),
      ),
      body: FutureBuilder<void>(
        future: _sdkReady,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          return Stack(
            children: [
              NaverMap(
                options: const NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(target: NLatLng(36.1, 127.9), zoom: 6.2),
                  minZoom: 5.5,
                  maxZoom: 12,
                  rotationGesturesEnable: false,
                  tiltGesturesEnable: false,
                  // 날씨 색 면이 주인공이다. 바탕의 상점·건물은 줄이고 글씨도 조금 작게.
                  activeLayerGroups: [],
                  symbolScale: 0.9,
                ),
                onMapReady: (controller) => c.attachMap(controller, context),
                onMapTapped: (_, latLng) => c.onMapTapped(latLng),
                onCameraIdle: c.onCameraIdle,
              ),
              Positioned(left: 12, top: 12, child: _legend()),
              Positioned(right: 10, top: 10, bottom: 150, child: _rightRail()),
              _dropdown(),
              Positioned(left: 0, right: 0, bottom: 0, child: _bottomArea()),
              Obx(() => (c.loading.value || c.painting.value)
                  ? const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: LinearProgressIndicator(minHeight: 2, color: _blue, backgroundColor: Colors.transparent),
                    )
                  : const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }

  // ── 왼쪽 위: 세로 색 막대 범례 ─────────────────────────────

  Widget _legend() {
    return Obx(() {
      final l = c.layer.value;
      if (l.group == NationMapGroup.air) return _airLegend(l);
      final ticks = l.ticks;
      final top = ticks.first, bottom = ticks.last;
      return Container(
        padding: const EdgeInsets.fromLTRB(5, 7, 7, 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: _shadow),
        child: Column(
          children: [
            SizedBox(
              height: 112,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [for (var i = 0; i <= 12; i++) l.colorOf(top + (bottom - top) * i / 12).withValues(alpha: 1)],
                      ),
                    ),
                  ),
                  const Gap(4),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final t in ticks)
                        Text(t == t.roundToDouble() ? t.toInt().toString() : t.toString(),
                            style: const TextStyle(fontSize: 9.5, color: _sub, height: 1)),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(4),
            Text(l.unit, style: const TextStyle(fontSize: 9.5, color: _sub, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    });
  }

  Widget _airLegend(NationMapLayer l) {
    final grades = l == NationMapLayer.pm10
        ? const [('좋음', 0.0), ('보통', 50.0), ('나쁨', 100.0), ('매우나쁨', 200.0)]
        : const [('좋음', 0.0), ('보통', 20.0), ('나쁨', 50.0), ('매우나쁨', 100.0)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: _shadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (name, v) in grades)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: l.colorOf(v), shape: BoxShape.circle)),
                const Gap(5),
                Text(name, style: const TextStyle(fontSize: 10.5, color: _ink)),
              ]),
            ),
        ],
      ),
    );
  }

  // ── 오른쪽: 세로 버튼 줄 ──────────────────────────────────

  Widget _rightRail() {
    return Obx(() {
      final l = c.layer.value;
      final menu = c.openMenu.value;
      Widget group(NationMapGroup g) => _RailButton(
            label: g.label,
            caption: l.group == g ? l.label : null,
            active: l.group == g,
            expanded: menu == g,
            onTap: () => c.toggleMenu(g),
          );
      return SingleChildScrollView(
        child: Column(
          children: [
            for (final g in NationMapGroup.values) ...[group(g), const Gap(6)],
            const Gap(4),
            _RailButton(label: '바람', icon: Icons.air_rounded, dark: c.windOn.value, onTap: c.toggleWind),
            const Gap(6),
            _RailButton(label: 'CCTV', icon: Icons.videocam_rounded, dark: c.cctvOn.value, onTap: c.toggleCctv),
            const Gap(10),
            _RailButton(
              label: '특보',
              icon: Icons.warning_amber_rounded,
              active: c.safety.value == SafetyPanel.warning,
              badge: c.warnings.isNotEmpty,
              onTap: () => c.toggleSafety(SafetyPanel.warning),
            ),
            const Gap(6),
            _RailButton(
              label: '지진태풍',
              icon: Icons.public_rounded,
              active: c.safety.value == SafetyPanel.quake,
              onTap: () => c.toggleSafety(SafetyPanel.quake),
            ),
            const Gap(6),
            _RailButton(label: '제보', icon: Icons.photo_camera_outlined, onTap: () => Get.toNamed('/MapPage')),
          ],
        ),
      );
    });
  }

  /// 펼친 하위 메뉴 — 버튼 왼쪽에 흰 카드로.
  Widget _dropdown() {
    return Obx(() {
      final g = c.openMenu.value;
      if (g == null) return const SizedBox.shrink();
      final idx = NationMapGroup.values.indexOf(g);
      final items = <Widget>[];
      if (g == NationMapGroup.nowcast) {
        // 위성·레이더는 영상 재생 화면으로 연다(기상청 영상, 미승인이면 기존 웹뷰).
        items.add(_MenuRow(icon: Icons.satellite_alt_outlined, label: '위성', onTap: () {
          c.closeMenus();
          WeatherMapViewerPage.openSatellite();
        }));
        items.add(_MenuRow(icon: Icons.radar_rounded, label: '레이더', onTap: () {
          c.closeMenus();
          WeatherMapViewerPage.openRadar();
        }));
      }
      for (final l in NationMapLayer.of(g)) {
        items.add(_MenuRow(icon: l.icon, label: l.label, selected: c.layer.value == l, onTap: () => c.selectLayer(l)));
      }
      return Positioned(
        right: 76,
        top: 10.0 + idx * 58,
        child: Container(
          width: 148,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: _shadow),
          child: Column(mainAxisSize: MainAxisSize.min, children: items),
        ),
      );
    });
  }

  // ── 아래: 시간 막대 + 지점 카드 / 안전 정보 ──────────────────

  Widget _bottomArea() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Obx(() {
          final s = c.safety.value;
          if (s != null) return _card(s == SafetyPanel.warning ? _warningList() : _quakeList());
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.cctvHint.value.isNotEmpty) _hintChip(c.cctvHint.value),
              if (c.times.isNotEmpty) _timeBar(),
              const Gap(6),
              _card(_pointCard()),
            ],
          );
        }),
      ),
    );
  }

  Widget _hintChip(String text) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xCC222222), borderRadius: BorderRadius.circular(14)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  Widget _timeBar() {
    final t = c.times;
    final idx = c.timeIndex.value.clamp(0, t.length - 1);
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 4, right: 12),
      decoration: BoxDecoration(color: const Color(0xD9262626), borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: c.togglePlay,
            icon: Icon(c.playing.value ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 24),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF19CE60), borderRadius: BorderRadius.circular(10)),
            child: Text(NationWeatherMapCntr.label(t[idx]),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: const Color(0xFF19CE60),
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                tickMarkShape: SliderTickMarkShape.noTickMark,
              ),
              child: Slider(
                value: idx.toDouble(),
                min: 0,
                max: (t.length - 1).toDouble().clamp(1, 1e9),
                divisions: t.length > 1 ? t.length - 1 : null,
                onChanged: (v) {
                  c.stop();
                  c.timeIndex.value = v.round();
                },
                // 끄는 동안 칸마다 받으면 요청이 쏟아진다. 손을 뗄 때 한 번만 그린다.
                onChangeEnd: (v) => c.selectTime(v.round()),
              ),
            ),
          ),
          Text(NationWeatherMapCntr.dateLabel(t.last), style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: _shadow),
        child: child,
      );

  /// 지점 카드 — 지도를 누른 곳의 값. 아직 안 눌렀으면 무엇을 보고 있는지 알려 준다.
  Widget _pointCard() {
    final l = c.layer.value;
    final p = c.picked.value;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD9D9D9)), borderRadius: BorderRadius.circular(4)),
      child: Text(l.label, style: const TextStyle(fontSize: 11.5, color: _ink, fontWeight: FontWeight.w600)),
    );
    if (p == null) {
      final when = switch (l.group) {
        NationMapGroup.observation => '${NationWeatherMapCntr.label(c.obsTime.value)} 관측',
        NationMapGroup.air => '${c.airTime.value} 측정 · 시도 평균',
        _ => '',
      };
      return Row(children: [
        chip,
        const Gap(8),
        const Expanded(
          child: Text('지도를 누르면 그 지점 날씨를 보여 드려요',
              style: TextStyle(fontSize: 13.5, color: _ink, fontWeight: FontWeight.w600)),
        ),
        if (when.isNotEmpty) Text(when, style: const TextStyle(fontSize: 11, color: _sub)),
      ]);
    }
    final facts = _factsOf(p, l.group);
    return Row(
      children: [
        chip,
        const Gap(10),
        Text(facts.first.$2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _ink, height: 1)),
        const Gap(12),
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 2,
            children: [
              for (final (k, v) in facts.skip(1))
                Text.rich(TextSpan(children: [
                  TextSpan(text: '$k ', style: const TextStyle(fontSize: 12, color: _sub)),
                  TextSpan(text: v, style: const TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w600)),
                ])),
            ],
          ),
        ),
        GestureDetector(onTap: () => c.picked.value = null, child: const Icon(Icons.close_rounded, size: 18, color: _sub)),
      ],
    );
  }

  List<(String, String)> _factsOf(Map<String, dynamic> p, NationMapGroup g) {
    String n(String k, String unit, {int digits = 0}) {
      final v = p[k];
      if (v is! num) return '-';
      return '${v.toStringAsFixed(digits)}$unit';
    }

    return switch (g) {
      NationMapGroup.forecast => [
          ('기온', n('TMP', '°')),
          ('체감', n('FEEL', '°')),
          ('습도', n('REH', '%')),
          ('강수확률', n('POP', '%')),
          ('강수', '${p['PCP'] ?? '-'}'),
          ('풍속', n('WSD', 'm/s', digits: 1)),
        ],
      NationMapGroup.nowcast => [
          ('강수', '${p['RN1'] ?? '-'}'),
          ('기온', n('T1H', '°')),
          ('낙뢰', (p['LGT'] is num && (p['LGT'] as num) > 0) ? '있음' : '없음'),
        ],
      NationMapGroup.observation => [
          ('기온', n('T1H', '°', digits: 1)),
          ('습도', n('REH', '%')),
          ('1시간 강수', n('RN1', 'mm', digits: 1)),
          ('풍속', n('WSD', 'm/s', digits: 1)),
        ],
      NationMapGroup.air => [
          ('${p['sido'] ?? ''}', ''),
          ('미세먼지', n('PM10', '㎍/㎥')),
          ('초미세먼지', n('PM25', '㎍/㎥')),
        ],
    };
  }

  Widget _warningList() {
    final list = c.warnings;
    final header = Row(children: [
      const Text('기상특보', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const Spacer(),
      GestureDetector(onTap: () => c.toggleSafety(SafetyPanel.warning), child: const Icon(Icons.close_rounded, size: 20)),
    ]);
    if (list.isEmpty) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        header,
        const Gap(10),
        const _Notice(text: '지금 발효 중인 기상특보가 없어요'),
      ]);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        const Gap(6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF0F0F0)),
            itemBuilder: (_, i) {
              final w = list[i];
              final name = '${w['wrnNm'] ?? ''}';
              final heavy = name.contains('경보');
              return Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (heavy ? const Color(0xFFE5402F) : const Color(0xFFF5A623)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(name,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: heavy ? const Color(0xFFE5402F) : const Color(0xFFD48806))),
                ),
                const Gap(10),
                Expanded(child: Text('${w['areaNm'] ?? ''}', style: const TextStyle(fontSize: 13.5, color: _ink))),
                Text('${w['status'] ?? ''}', style: const TextStyle(fontSize: 11.5, color: _sub)),
              ]);
            },
          ),
        ),
      ],
    );
  }

  Widget _quakeList() {
    final header = Row(children: [
      const Text('지진 · 태풍', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const Spacer(),
      GestureDetector(onTap: () => c.toggleSafety(SafetyPanel.quake), child: const Icon(Icons.close_rounded, size: 20)),
    ]);
    final rows = <Widget>[
      for (final e in c.earthquakes)
        _InfoRow(
          badge: '지진',
          color: const Color(0xFF8D6E63),
          title: '규모 ${e['mt'] ?? '-'} · ${e['loc'] ?? ''}',
          sub: '${_fmtTm('${e['tmEqk'] ?? e['tmFc'] ?? ''}')}${e['inT'] != null ? ' · 최대진도 ${e['inT']}' : ''}',
        ),
      for (final t in c.typhoons)
        _InfoRow(
          badge: '태풍',
          color: const Color(0xFFD81B60),
          title: '${t['typName'] ?? ''} · ${t['typLoc'] ?? ''}',
          sub: '중심기압 ${t['typPs'] ?? '-'}hPa · 최대풍속 ${t['typWs'] ?? '-'}m/s',
        ),
    ];
    final Widget body;
    if (rows.isNotEmpty) {
      body = ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF0F0F0)),
          itemBuilder: (_, i) => rows[i],
        ),
      );
    } else if (!c.quakeAvailable.value && !c.typhoonAvailable.value) {
      body = const _Notice(text: '지진·태풍 정보를 연결하고 있어요');
    } else {
      body = const _Notice(text: '최근 3일간 지진·태풍 소식이 없어요');
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [header, const Gap(8), body]);
  }

  static String _fmtTm(String t) {
    if (t.length < 12) return t;
    return '${int.parse(t.substring(4, 6))}.${int.parse(t.substring(6, 8))}. ${t.substring(8, 10)}:${t.substring(10, 12)}';
  }
}

/// 오른쪽 버튼 한 칸. 고른 층이 속한 묶음은 파란 바탕에 하위 이름을 함께 적는다
/// (네이버: "예보 / 기온"). 바람·CCTV 처럼 켜고 끄는 건 켜지면 검정 바탕.
class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.label,
    required this.onTap,
    this.caption,
    this.icon,
    this.active = false,
    this.expanded = false,
    this.dark = false,
    this.badge = false,
  });

  final String label;
  final String? caption;
  final IconData? icon;
  final bool active;
  final bool expanded;
  final bool dark;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? _blue : (dark ? _ink : Colors.white);
    final fg = (active || dark) ? Colors.white : _ink;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 52,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), boxShadow: _shadow),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (caption != null)
                  Text(caption!,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.85), height: 1.1)),
                if (icon != null) Icon(icon, size: 18, color: fg),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg, height: 1.2)),
                if (icon == null)
                  Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 14, color: fg.withValues(alpha: 0.8)),
              ],
            ),
          ),
          if (badge)
            const Positioned(
              right: 5,
              top: 5,
              child: CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFE5402F)),
            ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap, this.selected = false});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2)))),
          child: Row(children: [
            Icon(icon, size: 17, color: selected ? _blue : _sub),
            const Gap(8),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? _blue : _ink)),
            ),
            if (selected) const Icon(Icons.check_rounded, size: 17, color: _blue),
          ]),
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF19CE60)),
          const Gap(8),
          Text(text, style: const TextStyle(fontSize: 13.5, color: _ink)),
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.badge, required this.color, required this.title, required this.sub});
  final String badge;
  final Color color;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(badge, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _ink)),
                Text(sub, style: const TextStyle(fontSize: 11.5, color: _sub)),
              ],
            ),
          ),
        ],
      );
}
