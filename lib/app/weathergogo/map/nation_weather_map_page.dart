import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/weathergogo/map/nation_map_layers.dart';
import 'package:project1/app/weathergogo/map/nation_weather_map_cntr.dart';
import 'package:project1/utils/log_utils.dart';

/// 전국 날씨 지도 — 예보 · 관측 · 특보 · 지진·태풍.
///
/// 바탕은 앱이 이미 쓰는 네이버 지도다(검색의 지도 화면과 같은 키). 한글 지명·도로·
/// 고해상도 줌이 다 돼서, 예전에 무료 지구 사진을 바탕으로 깔았다가 "어디가 어딘지
/// 모르겠다"는 평을 받은 문제(2026-09-22)가 없다.
class NationWeatherMapPage extends StatefulWidget {
  const NationWeatherMapPage({super.key});

  static void open() => Get.to(() => const NationWeatherMapPage(), transition: Transition.cupertino);

  @override
  State<NationWeatherMapPage> createState() => _NationWeatherMapPageState();
}

class _NationWeatherMapPageState extends State<NationWeatherMapPage> {
  late final NationWeatherMapCntr c = Get.put(NationWeatherMapCntr());

  /// 지도 키 초기화는 앱에서 한 번만 하면 된다. 검색 지도에서 이미 했어도 다시 불러도 무해하다.
  static Future<void>? _sdkReady;

  @override
  void initState() {
    super.initState();
    // 옛 NaverMapSdk.initialize 는 옛 네이버 클라우드 지도 주소로 인증해 "not authorized"
    // 로 거부됐다(2026-10-13 시뮬레이터 기록). 새 인증(FlutterNaverMap.init)을 쓴다.
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
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('전국 날씨 지도', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(44), child: _tabs()),
      ),
      body: FutureBuilder<void>(
        future: _sdkReady,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              NaverMap(
                options: const NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(target: NLatLng(36.2, 127.8), zoom: 6.3),
                  minZoom: 5,
                  maxZoom: 12,
                  rotationGesturesEnable: false,
                  tiltGesturesEnable: false,
                  // 날씨 값이 주인공이다. 지도 바탕의 상점·건물 표시는 줄인다.
                  activeLayerGroups: [NLayerGroup.building],
                  symbolScale: 0.85,
                ),
                onMapReady: (controller) => c.attachMap(controller, context),
              ),
              Positioned(left: 0, right: 0, top: 0, child: _layerChips()),
              Obx(() => c.loading.value
                  ? const Center(child: CircularProgressIndicator())
                  : const SizedBox.shrink()),
              Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(top: false, child: _bottom())),
            ],
          );
        },
      ),
    );
  }

  // ── 위: 탭 + 층 ───────────────────────────────────────────

  Widget _tabs() {
    const labels = ['예보', '관측', '특보', '지진·태풍'];
    return Obx(() => Row(
          children: List.generate(labels.length, (i) {
            final on = c.tab.value == i;
            return Expanded(
              child: InkWell(
                onTap: () => c.selectTab(i),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: on ? Colors.black87 : Colors.black12, width: on ? 2 : 1),
                    ),
                  ),
                  child: Text(labels[i],
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                          color: on ? Colors.black87 : Colors.black45)),
                ),
              ),
            );
          }),
        ));
  }

  Widget _layerChips() {
    return Obx(() {
      final tab = c.tab.value;
      if (tab > 1) return const SizedBox.shrink();
      final layers = tab == 0 ? NationMapLayer.forecastLayers : NationMapLayer.observationLayers;
      final selected = c.layer.value;
      return SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          itemCount: layers.length,
          separatorBuilder: (_, __) => const Gap(6),
          itemBuilder: (_, i) {
            final l = layers[i];
            final on = l == selected;
            return GestureDetector(
              onTap: () => c.selectLayer(l),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? Colors.black87 : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))],
                ),
                child: Text(l.label,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: on ? Colors.white : Colors.black87)),
              ),
            );
          },
        ),
      );
    });
  }

  // ── 아래: 탭마다 다른 패널 ─────────────────────────────────

  Widget _bottom() {
    return Obx(() {
      switch (c.tab.value) {
        case 0:
          return _panel(Column(mainAxisSize: MainAxisSize.min, children: [_legend(), _emptyHint(), _timeBar()]));
        case 1:
          return _panel(Column(mainAxisSize: MainAxisSize.min, children: [
            _legend(),
            _emptyHint(),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                c.obsTime.value.isEmpty ? '' : '${NationWeatherMapCntr.label(c.obsTime.value)} 관측 · 기상청 초단기실황',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ]));
        case 2:
          return _panel(_warningList());
        default:
          return _panel(_quakeTyphoonList());
      }
    });
  }

  Widget _panel(Widget child) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _legend() {
    final items = c.layer.value.legend;
    return Row(
      children: [
        for (final (label, color) in items) ...[
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const Gap(3),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.black54))),
          const Gap(7),
        ],
      ],
    );
  }

  /// 비·눈 층에서 찍을 곳이 하나도 없으면 빈 지도가 "고장" 처럼 보인다. 이유를 적는다.
  Widget _emptyHint() {
    if (c.loading.value || c.shownCount.value > 0 || !c.layer.value.skipZero) return const SizedBox.shrink();
    final what = c.layer.value == NationMapLayer.snow ? '눈' : '비';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text('이 시각 전국에 $what 소식이 없어요', style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
    );
  }

  Widget _timeBar() {
    final n = c.times.length;
    if (n == 0) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text('예보를 불러오지 못했어요', style: TextStyle(fontSize: 12.5)),
      );
    }
    final idx = c.timeIndex.value.clamp(0, n - 1);
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: c.togglePlay,
          icon: Icon(c.playing.value ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 32),
        ),
        Expanded(
          child: Slider(
            value: idx.toDouble(),
            min: 0,
            max: (n - 1).toDouble(),
            divisions: n > 1 ? n - 1 : null,
            onChanged: (v) {
              c.stop();
              c.timeIndex.value = v.round();
            },
            // 끄는 동안 매 칸마다 받으면 요청이 쏟아진다. 손을 뗄 때 한 번만 그린다.
            onChangeEnd: (v) => c.selectTime(v.round()),
          ),
        ),
        SizedBox(
          width: 74,
          child: Text(NationWeatherMapCntr.label(c.times[idx]),
              textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _warningList() {
    final list = c.warnings;
    if (list.isEmpty) {
      return const _Notice(icon: '✅', title: '지금 발효 중인 기상특보가 없어요', sub: '기상청 특보 · 5분마다 확인');
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 14),
        itemBuilder: (_, i) {
          final w = list[i];
          final name = '${w['wrnNm'] ?? ''}';
          final heavy = name.contains('경보');
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: heavy ? const Color(0xFFD32F2F) : const Color(0xFFF9A825),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(name, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const Gap(10),
              Expanded(child: Text('${w['areaNm'] ?? ''}', style: const TextStyle(fontSize: 13.5))),
              Text('${w['status'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          );
        },
      ),
    );
  }

  Widget _quakeTyphoonList() {
    final rows = <Widget>[];
    for (final e in c.earthquakes) {
      rows.add(_InfoRow(
        badge: '지진',
        color: const Color(0xFF6D4C41),
        title: '규모 ${e['mt'] ?? '-'} · ${e['loc'] ?? ''}',
        sub: '${_fmtTm('${e['tmEqk'] ?? e['tmFc'] ?? ''}')}${e['inT'] != null ? ' · 최대진도 ${e['inT']}' : ''}',
      ));
    }
    for (final t in c.typhoons) {
      rows.add(_InfoRow(
        badge: '태풍',
        color: const Color(0xFFD81B60),
        title: '${t['typName'] ?? ''} · ${t['typLoc'] ?? ''}',
        sub: '중심기압 ${t['typPs'] ?? '-'}hPa · 최대풍속 ${t['typWs'] ?? '-'}㎧ · ${t['typDir'] ?? ''} ${t['typSp'] ?? ''}㎞/h',
      ));
    }
    if (rows.isEmpty) {
      if (!c.quakeAvailable.value && !c.typhoonAvailable.value) {
        return const _Notice(icon: '⏳', title: '지진·태풍 정보를 준비하고 있어요', sub: '기상청 서비스 연결 대기 중');
      }
      return const _Notice(icon: '✅', title: '최근 3일간 지진·태풍 소식이 없어요', sub: '기상청 지진·태풍 통보');
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 14),
        itemBuilder: (_, i) => rows[i],
      ),
    );
  }

  static String _fmtTm(String t) {
    if (t.length < 12) return t;
    return '${int.parse(t.substring(4, 6))}월 ${int.parse(t.substring(6, 8))}일 ${t.substring(8, 10)}:${t.substring(10, 12)}';
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.sub});
  final String icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(sub, style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
              ],
            ),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(badge, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(sub, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
              ],
            ),
          ),
        ],
      );
}
