import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';
import 'package:project1/app/weathergogo/map/nation_map_layers.dart';
import 'package:project1/repo/weather_gogo/sources/weather_map_api.dart';
import 'package:project1/utils/log_utils.dart';

/// 전국 날씨 지도 화면의 상태.
///
/// 탭 4개 — 0 예보 · 1 관측 · 2 특보 · 3 지진·태풍.
/// 예보는 시각마다 230개 지점이 와서, 한 번 받은 시각은 [_frames] 에 들고 있다가 재생·
/// 되돌리기 때 다시 받지 않는다.
class NationWeatherMapCntr extends GetxController {
  final WeatherMapApi _api = WeatherMapApi();

  final RxInt tab = 0.obs;
  final Rx<NationMapLayer> layer = NationMapLayer.temp.obs;

  // 예보
  final RxList<String> times = <String>[].obs;
  final RxInt timeIndex = 0.obs;
  final RxBool playing = false.obs;
  final Map<String, List<Map<String, dynamic>>> _frames = {};
  Timer? _player;

  // 관측
  final RxString obsTime = ''.obs;
  List<Map<String, dynamic>> _nowPoints = const [];

  // 특보·지진·태풍
  final RxList<Map<String, dynamic>> warnings = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> earthquakes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> typhoons = <Map<String, dynamic>>[].obs;

  /// 기상청 서비스가 아직 활용 신청 전이면 false — 화면에 그렇게 알린다.
  final RxBool quakeAvailable = true.obs;
  final RxBool typhoonAvailable = true.obs;

  final RxBool loading = true.obs;

  /// 지금 지도에 찍힌 지점 수 — 0 이면 "비 오는 곳 없음" 같은 안내를 띄운다.
  final RxInt shownCount = 0.obs;

  NaverMapController? _map;
  BuildContext? _ctx;

  /// 알약 그림은 색·크기별로 한 번만 굽는다. 숫자는 지도 엔진이 캡션으로 그린다 —
  /// 230개를 매 시각 위젯→그림으로 구우면 첫 화면이 몇 초씩 걸린다.
  final Map<String, NOverlayImage> _pills = {};

  int _renderSeq = 0;

  @override
  void onInit() {
    super.onInit();
    _loadInitial();
  }

  @override
  void onClose() {
    _player?.cancel();
    super.onClose();
  }

  Future<void> _loadInitial() async {
    final results = await Future.wait([_api.forecastTimes(), _api.now()]);
    final t = results[0] as List<String>;
    final now = results[1] as Map<String, dynamic>;
    times.assignAll(t);
    obsTime.value = (now['obsTime'] ?? '').toString();
    _nowPoints = _points(now);
    if (t.isNotEmpty) await _ensureFrame(t.first);
    loading.value = false;
    render();
    // 나머지는 뒤에서 받아 둔다(탭을 바꿀 때 기다리지 않게).
    unawaited(_loadSafety());
  }

  Future<void> _loadSafety() async {
    final res = await Future.wait([_api.warnings(), _api.earthquakes(), _api.typhoons()]);
    warnings.assignAll((res[0] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    final eqk = res[1] as Map<String, dynamic>;
    final typ = res[2] as Map<String, dynamic>;
    quakeAvailable.value = eqk['available'] != false;
    typhoonAvailable.value = typ['available'] != false;
    earthquakes.assignAll(_items(eqk));
    typhoons.assignAll(_latestTyphoonPositions(_items(typ)));
    if (tab.value >= 2) render();
  }

  // ── 화면에서 부르는 것 ─────────────────────────────────────

  void attachMap(NaverMapController c, BuildContext context) {
    _map = c;
    _ctx = context;
    render();
  }

  void selectTab(int i) {
    if (tab.value == i) return;
    stop();
    tab.value = i;
    if (i == 0 && !layer.value.forecast) layer.value = NationMapLayer.temp;
    if (i == 1 && layer.value.forecast) layer.value = NationMapLayer.obsTemp;
    render();
  }

  void selectLayer(NationMapLayer l) {
    layer.value = l;
    render();
  }

  Future<void> selectTime(int i) async {
    if (times.isEmpty) return;
    timeIndex.value = i.clamp(0, times.length - 1);
    await _ensureFrame(times[timeIndex.value]);
    render();
    // 다음 두 칸을 미리 받아 둔다 — 막대를 끌거나 재생할 때 끊기지 않게.
    for (final k in [timeIndex.value + 1, timeIndex.value + 2]) {
      if (k < times.length) unawaited(_ensureFrame(times[k]));
    }
  }

  void togglePlay() => playing.value ? stop() : _play();

  void stop() {
    playing.value = false;
    _player?.cancel();
    _player = null;
  }

  void _play() {
    if (times.length < 2) return;
    playing.value = true;
    _player?.cancel();
    _player = Timer.periodic(const Duration(milliseconds: 900), (_) {
      final next = timeIndex.value + 1;
      if (next >= times.length) {
        stop();
        return;
      }
      selectTime(next);
    });
  }

  // ── 지도 그리기 ──────────────────────────────────────────

  Future<void> render() async {
    final map = _map;
    final ctx = _ctx;
    if (map == null || ctx == null || !ctx.mounted) return;
    final seq = ++_renderSeq;

    final Set<NAddableOverlay> overlays = {};
    switch (tab.value) {
      case 0:
      case 1:
        final points = tab.value == 0
            ? (_frames[times.isEmpty ? '' : times[timeIndex.value]] ?? const [])
            : _nowPoints;
        overlays.addAll(await _valueMarkers(points, ctx));
      case 3:
        overlays.addAll(await _quakeAndTyphoonMarkers(ctx));
      default:
        break;  // 특보는 목록으로 보여 준다(지역 경계 자료가 없어 지도에 칠하지 않는다)
    }
    // 그리는 사이 다른 층·시각으로 바뀌었으면 이 결과는 버린다(재생 중 앞뒤 섞임 방지).
    if (seq != _renderSeq) return;
    try {
      await map.clearOverlays(type: NOverlayType.marker);
      if (overlays.isNotEmpty) await map.addOverlayAll(overlays);
    } catch (e) {
      lo.g('전국 지도 그리기 실패: $e');
    }
    shownCount.value = overlays.length;
  }

  Future<List<NMarker>> _valueMarkers(List<Map<String, dynamic>> points, BuildContext ctx) async {
    final l = layer.value;
    final markers = <NMarker>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final text = l.text(p);
      final lat = (p['lat'] as num?)?.toDouble();
      final lon = (p['lon'] as num?)?.toDouble();
      if (text == null || lat == null || lon == null) continue;
      final color = l.color(p);
      final size = _sizeFor(text);
      final icon = await _pill(color, size, ctx, text);
      if (icon == null || !ctx.mounted) break;
      markers.add(NMarker(
        id: 'v$i',
        position: NLatLng(lat, lon),
        icon: icon,
        size: size,
        anchor: const NPoint(0.5, 0.5),
        // 줌을 빼면 지점이 몰린다 — 겹치는 건 지도가 알아서 숨긴다.
        isHideCollidedMarkers: true,
        isHideCollidedSymbols: true,
      ));
    }
    return markers;
  }

  Future<List<NMarker>> _quakeAndTyphoonMarkers(BuildContext ctx) async {
    final markers = <NMarker>[];
    for (var i = 0; i < earthquakes.length; i++) {
      final e = earthquakes[i];
      final lat = _d(e['lat']);
      final lon = _d(e['lon']);
      if (lat == null || lon == null) continue;
      final label = '지진 ${e['mt'] ?? ''}';
      final size = _sizeFor(label);
      final icon = await _pill(const Color(0xFF6D4C41), size, ctx, label);
      if (icon == null) break;
      markers.add(NMarker(id: 'q$i', position: NLatLng(lat, lon), icon: icon, size: size, anchor: const NPoint(0.5, 0.5)));
    }
    for (var i = 0; i < typhoons.length; i++) {
      final t = typhoons[i];
      final lat = _d(t['typLat']);
      final lon = _d(t['typLon']);
      if (lat == null || lon == null) continue;
      final label = '🌀 ${t['typName'] ?? '태풍'}';
      final size = _sizeFor(label);
      final icon = await _pill(const Color(0xFFD81B60), size, ctx, label);
      if (icon == null) break;
      markers.add(NMarker(id: 't$i', position: NLatLng(lat, lon), icon: icon, size: size, anchor: const NPoint(0.5, 0.5)));
    }
    return markers;
  }

  /// 글자 길이에 맞춘 알약 크기. 하늘 그림(이모지)은 글자 두 칸 폭으로 친다.
  static NSize _sizeFor(String text) {
    var units = 0.0;
    for (final r in text.runes) {
      if (r == 0xFE0F) continue;           // 이모지 변형 표시는 폭이 없다
      units += r > 0x2000 ? 1.9 : (r > 0x7F ? 1.6 : 1.0);
    }
    return NSize((units * 6.6 + 14).clamp(34, 120).roundToDouble(), 22);
  }

  /// 값이 적힌 알약 그림. (색·글자)마다 한 번만 굽고 재사용한다.
  ///
  /// 처음엔 숫자를 지도 엔진 캡션으로 얹었는데, 캡션 글꼴을 지도 서버에서 받아 그리는
  /// 구조라 지도 인증이 안 되면 숫자가 통째로 사라졌다(2026-10-13 시뮬레이터). 그림에
  /// 직접 구우면 지도 상태와 무관하게 보인다. 기온은 서로 다른 값이 수십 개라 첫 시각만
  /// 조금 걸리고 이후 시각은 대부분 재사용된다.
  Future<NOverlayImage?> _pill(Color color, NSize size, BuildContext ctx, String text) async {
    final key = '${color.toARGB32()}_$text';
    final hit = _pills[key];
    if (hit != null) return hit;
    if (!ctx.mounted) return null;
    final img = await NOverlayImage.fromWidget(
      context: ctx,
      size: size,
      widget: Container(
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size.height / 2),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Text(
          text,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            height: 1.0,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
    _pills[key] = img;
    return img;
  }

  // ── 자료 ─────────────────────────────────────────────────

  Future<void> _ensureFrame(String time) async {
    if (_frames.containsKey(time)) return;
    final res = await _api.forecast(time);
    _frames[time] = _points(res);
  }

  static List<Map<String, dynamic>> _points(Map<String, dynamic> res) {
    final p = res['points'];
    if (p is! List) return const [];
    return p.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static List<Map<String, dynamic>> _items(Map<String, dynamic> res) {
    final p = res['items'];
    if (p is! List) return const [];
    return p.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// 태풍 정보는 같은 태풍이 발표 시각마다 여러 줄로 온다. 태풍마다 가장 최근 위치만 남긴다.
  static List<Map<String, dynamic>> _latestTyphoonPositions(List<Map<String, dynamic>> items) {
    final Map<String, Map<String, dynamic>> latest = {};
    for (final it in items) {
      final id = '${it['typSeq'] ?? it['typName'] ?? ''}';
      final prev = latest[id];
      if (prev == null || '${it['typTm'] ?? it['tmFc'] ?? ''}'.compareTo('${prev['typTm'] ?? prev['tmFc'] ?? ''}') > 0) {
        latest[id] = it;
      }
    }
    return latest.values.toList();
  }

  static double? _d(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  /// "202610131500" → "13일 15시"
  static String label(String t) {
    if (t.length < 10) return t;
    return '${int.parse(t.substring(6, 8))}일 ${t.substring(8, 10)}시';
  }
}
