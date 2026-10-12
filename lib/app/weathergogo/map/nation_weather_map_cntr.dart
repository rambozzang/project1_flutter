import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:project1/app/search/cctv_page.dart';
import 'package:project1/app/weathergogo/map/heat_raster.dart';
import 'package:project1/app/weathergogo/map/nation_map_layers.dart';
import 'package:project1/repo/cctv/cctv_repo.dart';
import 'package:project1/repo/cctv/data/cctv_res_data.dart';
import 'package:project1/repo/weather_gogo/sources/weather_map_api.dart';
import 'package:project1/utils/log_utils.dart';

/// 안전 정보 패널 — 네이버 날씨 '세이프티' 의 특보·지진·태풍.
enum SafetyPanel { warning, quake }

/// 전국 날씨 지도의 상태.
///
/// 네이버 날씨 지도처럼 **오른쪽 버튼 묶음(예보·영상·관측·대기질)** 에서 층을 고르면
/// 지도 전체에 색 면([HeatRaster])을 깔고 그 위에 흰 알약으로 값을 찍는다. 예보·강수예측은
/// 시각이 여럿이라 아래 시간 막대로 넘긴다.
class NationWeatherMapCntr extends GetxController {
  final WeatherMapApi _api = WeatherMapApi();
  final CctvRepo _cctvRepo = CctvRepo();

  final Rx<NationMapLayer> layer = NationMapLayer.temp.obs;

  /// 펼쳐진 하위 메뉴(null 이면 닫힘).
  final Rx<NationMapGroup?> openMenu = Rx<NationMapGroup?>(null);
  final Rx<SafetyPanel?> safety = Rx<SafetyPanel?>(null);
  final RxBool windOn = false.obs;
  final RxBool cctvOn = false.obs;

  // 시간축(예보 3일 / 강수예측 6시간)
  final RxList<String> forecastTimes = <String>[].obs;
  final RxList<String> nowcastTimes = <String>[].obs;
  final RxInt timeIndex = 0.obs;
  final RxBool playing = false.obs;
  Timer? _player;

  final Map<String, List<Map<String, dynamic>>> _forecastFrames = {};
  final Map<String, List<Map<String, dynamic>>> _nowcastFrames = {};
  List<Map<String, dynamic>> _obsPoints = const [];
  List<Map<String, dynamic>> _airPoints = const [];
  final RxString obsTime = ''.obs;
  final RxString airTime = ''.obs;

  // 안전
  final RxList<Map<String, dynamic>> warnings = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> earthquakes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> typhoons = <Map<String, dynamic>>[].obs;
  final RxBool quakeAvailable = true.obs;
  final RxBool typhoonAvailable = true.obs;

  // CCTV
  List<CctvResData> _cctvs = const [];
  final RxString cctvHint = ''.obs;

  /// 지도를 눌러 고른 지점(아래 카드).
  final Rx<Map<String, dynamic>?> picked = Rx<Map<String, dynamic>?>(null);

  final RxBool loading = true.obs;
  final RxBool painting = false.obs;

  NaverMapController? _map;
  BuildContext? _ctx;
  int _renderSeq = 0;

  /// 색 면 그림은 (층, 시각)마다 한 번만 만든다 — 재생·되감기 때 다시 계산하지 않게.
  final Map<String, NOverlayImage> _rasters = {};

  /// 흰 알약은 글자마다 한 번만 굽는다.
  final Map<String, NOverlayImage> _pills = {};
  NOverlayImage? _arrow;
  NOverlayImage? _cctvIcon;

  // ── 상태 읽기 ─────────────────────────────────────────────

  List<String> get times => switch (layer.value.group) {
        NationMapGroup.forecast => forecastTimes,
        NationMapGroup.nowcast => nowcastTimes,
        _ => const [],
      };

  String get currentTime {
    final t = times;
    return t.isEmpty ? '' : t[timeIndex.value.clamp(0, t.length - 1)];
  }

  List<Map<String, dynamic>> get points => switch (layer.value.group) {
        NationMapGroup.forecast => _forecastFrames[currentTime] ?? const [],
        NationMapGroup.nowcast => _nowcastFrames[currentTime] ?? const [],
        NationMapGroup.observation => _obsPoints,
        NationMapGroup.air => _airPoints,
      };

  /// 바람 화살표는 예보 시각 자료가 있으면 그것을, 아니면 실황을 쓴다.
  List<Map<String, dynamic>> get _windSource =>
      layer.value.group == NationMapGroup.forecast ? points : _obsPoints;

  // ── 수명 ─────────────────────────────────────────────────

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
    final r = await Future.wait([_api.forecastTimes(), _api.nowcastTimes(), _api.now(), _api.air()]);
    forecastTimes.assignAll(r[0] as List<String>);
    nowcastTimes.assignAll(r[1] as List<String>);
    final now = r[2] as Map<String, dynamic>;
    obsTime.value = '${now['obsTime'] ?? ''}';
    _obsPoints = _list(now['points']);
    final air = r[3] as Map<String, dynamic>;
    airTime.value = '${air['dataTime'] ?? ''}';
    _airPoints = _list(air['points']);
    if (forecastTimes.isNotEmpty) await _ensureFrame(NationMapGroup.forecast, forecastTimes.first);
    loading.value = false;
    render();
    unawaited(_loadSafety());
  }

  Future<void> _loadSafety() async {
    final r = await Future.wait([_api.warnings(), _api.earthquakes(), _api.typhoons()]);
    warnings.assignAll((r[0] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    final eqk = r[1] as Map<String, dynamic>;
    final typ = r[2] as Map<String, dynamic>;
    quakeAvailable.value = eqk['available'] != false;
    typhoonAvailable.value = typ['available'] != false;
    earthquakes.assignAll(_list(eqk['items']));
    typhoons.assignAll(_latestTyphoonPositions(_list(typ['items'])));
  }

  // ── 화면에서 부르는 것 ─────────────────────────────────────

  void attachMap(NaverMapController c, BuildContext context) {
    _map = c;
    _ctx = context;
    render();
  }

  void toggleMenu(NationMapGroup g) => openMenu.value = openMenu.value == g ? null : g;

  void closeMenus() => openMenu.value = null;

  Future<void> selectLayer(NationMapLayer l) async {
    final groupChanged = l.group != layer.value.group;
    openMenu.value = null;
    picked.value = null;
    if (groupChanged) {
      stop();
      timeIndex.value = 0;
    }
    layer.value = l;
    if (l.group == NationMapGroup.nowcast && nowcastTimes.isNotEmpty) {
      await _ensureFrame(NationMapGroup.nowcast, currentTime);
    }
    render();
  }

  void toggleSafety(SafetyPanel p) {
    safety.value = safety.value == p ? null : p;
    openMenu.value = null;
    render();
  }

  void toggleWind() {
    windOn.toggle();
    render();
  }

  void toggleCctv() {
    cctvOn.toggle();
    if (cctvOn.value) {
      unawaited(onCameraIdle());
    } else {
      _cctvs = const [];
      cctvHint.value = '';
      render();
    }
  }

  Future<void> selectTime(int i) async {
    final t = times;
    if (t.isEmpty) return;
    timeIndex.value = i.clamp(0, t.length - 1);
    await _ensureFrame(layer.value.group, currentTime);
    render();
    // 다음 두 칸을 미리 받아 둔다 — 막대를 끌거나 재생할 때 끊기지 않게.
    for (final k in [timeIndex.value + 1, timeIndex.value + 2]) {
      if (k < t.length) unawaited(_ensureFrame(layer.value.group, t[k]));
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
    _player = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      final next = timeIndex.value + 1;
      if (next >= times.length) {
        stop();
        return;
      }
      selectTime(next);
    });
  }

  /// 지도를 누르면 가장 가까운 지점(30km 안)의 값을 카드로 보여 준다.
  void onMapTapped(NLatLng at) {
    if (openMenu.value != null) {
      openMenu.value = null;
      return;
    }
    Map<String, dynamic>? best;
    var bestKm = 30.0;
    for (final p in points) {
      final lat = _d(p['lat']), lon = _d(p['lon']);
      if (lat == null || lon == null) continue;
      final km = _km(at.latitude, at.longitude, lat, lon);
      if (km < bestKm) {
        bestKm = km;
        best = p;
      }
    }
    picked.value = best;
  }

  /// CCTV 는 보이는 영역만 받는다. 너무 넓게 보면 수백 개가 쏟아져 확대를 요구한다.
  Future<void> onCameraIdle() async {
    final map = _map;
    if (!cctvOn.value || map == null) return;
    final pos = await map.getCameraPosition();
    if (pos.zoom < 9) {
      _cctvs = const [];
      cctvHint.value = '지도를 확대하면 CCTV가 보여요';
      render();
      return;
    }
    cctvHint.value = '';
    final b = await map.getContentBounds();
    final sw = ll.LatLng(b.southWest.latitude, b.southWest.longitude);
    final ne = ll.LatLng(b.northEast.latitude, b.northEast.longitude);
    try {
      final r = await Future.wait([
        _cctvRepo.fetchCctv(sw, ne, pos.target.latitude, pos.target.longitude, type: 'ex'),
        _cctvRepo.fetchCctv(sw, ne, pos.target.latitude, pos.target.longitude, type: 'its'),
      ]);
      _cctvs = [...r[0], ...r[1]].take(150).toList();
    } catch (e) {
      lo.g('CCTV 조회 실패: $e');
      _cctvs = const [];
    }
    render();
  }

  // ── 지도 그리기 ──────────────────────────────────────────

  Future<void> render() async {
    final map = _map;
    final ctx = _ctx;
    if (map == null || ctx == null || !ctx.mounted) return;
    final seq = ++_renderSeq;
    painting.value = true;
    final sw = Stopwatch()..start();

    final Set<NAddableOverlay> overlays = {};
    final l = layer.value;
    final pts = points;

    // 1) 색 면
    if (l.paintsField && pts.isNotEmpty) {
      final key = '${l.name}|${l.group == NationMapGroup.observation ? obsTime.value : currentTime}';
      var img = _rasters[key];
      img ??= await HeatRaster.build(
        points: [
          for (final p in pts)
            if (_d(p['lat']) != null && l.value(p) != null) (_d(p['lat'])!, _d(p['lon'])!, l.value(p)!)
        ],
        stops: [for (final (v, c) in l.stops) (v, c.toARGB32())],
        sparse: l.sparse,
      );
      if (img != null) {
        _rasters[key] = img;
        overlays.add(NGroundOverlay(id: 'field', bounds: HeatRaster.bounds, image: img));
      }
    }
    final tField = sw.elapsedMilliseconds;
    if (seq != _renderSeq || !ctx.mounted) return;

    // 2) 값 알약
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final text = l.text(p);
      final lat = _d(p['lat']), lon = _d(p['lon']);
      if (text == null || lat == null || lon == null) continue;
      final air = l.group == NationMapGroup.air;
      final bg = air ? l.colorOf(l.value(p) ?? 0) : Colors.white;
      final icon = await _pill(text, bg, air ? Colors.white : const Color(0xFF222222), ctx);
      if (icon == null) return;
      overlays.add(NMarker(
        id: 'v$i',
        position: NLatLng(lat, lon),
        icon: icon,
        size: _sizeFor(text),
        anchor: const NPoint(0.5, 0.5),
        // 대기질은 17개 시도뿐이라 겹쳐도 다 보여 준다(서울이 인천·경기에 가려 사라졌다).
        isHideCollidedMarkers: !air,
        isHideCollidedSymbols: true,
      ));
    }

    // 3) 바람 화살표 — 바람이 불어 가는 쪽을 가리킨다(풍향 VEC 는 불어오는 쪽).
    if (windOn.value) {
      _arrow ??= await NOverlayImage.fromWidget(
        context: ctx,
        size: const Size(16, 16),
        widget: const Icon(Icons.navigation_rounded, size: 16, color: Color(0xFF1B3A6B)),
      );
      final src = _windSource;
      for (var i = 0; i < src.length; i++) {
        final p = src[i];
        final lat = _d(p['lat']), lon = _d(p['lon']), vec = _d(p['VEC']), wsd = _d(p['WSD']);
        if (lat == null || lon == null || vec == null || (wsd ?? 0) < 0.5) continue;
        overlays.add(NMarker(
          id: 'w$i',
          // 값 알약과 겹치지 않게 살짝 위로 띄운다.
          position: NLatLng(lat + 0.06, lon),
          icon: _arrow!,
          size: const NSize(16, 16),
          angle: (vec + 180) % 360,
          isFlat: true,
          isHideCollidedMarkers: true,
        ));
      }
    }

    // 4) 지진·태풍
    if (safety.value == SafetyPanel.quake) {
      for (var i = 0; i < earthquakes.length; i++) {
        final e = earthquakes[i];
        final lat = _d(e['lat']), lon = _d(e['lon']);
        if (lat == null || lon == null) continue;
        final label = '지진 ${e['mt'] ?? ''}';
        final icon = await _pill(label, const Color(0xFF6D4C41), Colors.white, ctx);
        if (icon != null) {
          overlays.add(NMarker(id: 'q$i', position: NLatLng(lat, lon), icon: icon, size: _sizeFor(label)));
        }
      }
      for (var i = 0; i < typhoons.length; i++) {
        final t = typhoons[i];
        final lat = _d(t['typLat']), lon = _d(t['typLon']);
        if (lat == null || lon == null) continue;
        final label = '🌀 ${t['typName'] ?? '태풍'}';
        final icon = await _pill(label, const Color(0xFFD81B60), Colors.white, ctx);
        if (icon != null) {
          overlays.add(NMarker(id: 't$i', position: NLatLng(lat, lon), icon: icon, size: _sizeFor(label)));
        }
      }
    }

    // 5) CCTV
    if (cctvOn.value && _cctvs.isNotEmpty) {
      _cctvIcon ??= await NOverlayImage.fromWidget(
        context: ctx,
        size: const Size(26, 26),
        widget: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.videocam_rounded, size: 14, color: Colors.white),
        ),
      );
      for (var i = 0; i < _cctvs.length; i++) {
        final c = _cctvs[i];
        final lat = double.tryParse('${c.coordy}'), lon = double.tryParse('${c.coordx}');
        if (lat == null || lon == null) continue;
        final m = NMarker(id: 'c$i', position: NLatLng(lat, lon), icon: _cctvIcon!, size: const NSize(26, 26));
        m.setOnTapListener((_) {
          final ctx2 = _ctx;
          if (ctx2 != null && ctx2.mounted) CctvPageBottomSheet().open(ctx2, c);
        });
        overlays.add(m);
      }
    }

    final tPills = sw.elapsedMilliseconds;
    if (seq != _renderSeq) return;
    try {
      await map.clearOverlays();
      if (overlays.isNotEmpty) await map.addOverlayAll(overlays);
    } catch (e) {
      lo.g('전국 지도 그리기 실패: $e');
    }
    // 그리는 데 걸린 시간 — 느리다는 말이 나오면 이 기록부터 본다.
    lo.g('[날씨지도] ${l.name} 색면 ${tField}ms · 알약 ${tPills - tField}ms · 지도반영 ${sw.elapsedMilliseconds - tPills}ms');
    if (seq == _renderSeq) painting.value = false;
  }

  static NSize _sizeFor(String text) {
    var units = 0.0;
    for (final r in text.runes) {
      if (r == 0xFE0F) continue;
      units += r > 0x2000 ? 1.9 : (r > 0x7F ? 1.6 : 1.0);
    }
    return NSize((units * 6.8 + 16).clamp(30, 130).roundToDouble(), 22);
  }

  /// 값 알약. 처음엔 지도 엔진 캡션으로 숫자를 얹었는데 캡션 글꼴을 지도 서버에서 받는
  /// 구조라 지도 인증이 안 되면 숫자가 통째로 사라졌다. 그림에 직접 굽는다.
  Future<NOverlayImage?> _pill(String text, Color bg, Color fg, BuildContext ctx) async {
    final key = '${bg.toARGB32()}_${fg.toARGB32()}_$text';
    final hit = _pills[key];
    if (hit != null) return hit;
    if (!ctx.mounted) return null;
    final size = _sizeFor(text);
    final img = await NOverlayImage.fromWidget(
      context: ctx,
      size: size,
      widget: Container(
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size.height / 2),
          border: Border.all(color: const Color(0x1F000000), width: 0.8),
        ),
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            height: 1.0,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
    _pills[key] = img;
    return img;
  }

  // ── 자료 ─────────────────────────────────────────────────

  Future<void> _ensureFrame(NationMapGroup g, String time) async {
    if (time.isEmpty) return;
    if (g == NationMapGroup.forecast && !_forecastFrames.containsKey(time)) {
      _forecastFrames[time] = _list((await _api.forecast(time))['points']);
    } else if (g == NationMapGroup.nowcast && !_nowcastFrames.containsKey(time)) {
      _nowcastFrames[time] = _list((await _api.nowcast(time))['points']);
    }
  }

  static List<Map<String, dynamic>> _list(Object? p) {
    if (p is! List) return const [];
    return p.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// 같은 태풍이 발표 시각마다 여러 줄로 온다. 태풍마다 가장 최근 위치만 남긴다.
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

  static double _km(double a1, double o1, double a2, double o2) {
    final dx = (o2 - o1) * 111.32 * math.cos(a1 * math.pi / 180);
    final dy = (a2 - a1) * 110.57;
    return math.sqrt(dx * dx + dy * dy);
  }

  static const _weekday = ['월', '화', '수', '목', '금', '토', '일'];

  /// "202610131500" → "화 15:00"
  static String label(String t) {
    if (t.length < 12) return t;
    final d = DateTime(int.parse(t.substring(0, 4)), int.parse(t.substring(4, 6)), int.parse(t.substring(6, 8)));
    return '${_weekday[d.weekday - 1]} ${t.substring(8, 10)}:${t.substring(10, 12)}';
  }

  /// "202610131500" → "10.13."
  static String dateLabel(String t) =>
      t.length < 8 ? '' : '${int.parse(t.substring(4, 6))}.${int.parse(t.substring(6, 8))}.';
}
