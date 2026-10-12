import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 흩어진 지점 값으로 **지도 전체에 까는 색 면** 그림을 만든다.
///
/// 네이버 날씨 지도는 지점마다 숫자만 찍는 게 아니라 그 사이를 이어 색 면을 깐다.
/// 우리도 230개 지점 값을 거리 가중 평균(IDW)으로 이어서 그림 한 장을 만들고, 지도의
/// 지상 오버레이로 얹는다.
///
/// - 지점에서 멀어지면(바다 한가운데·국경 너머) 서서히 투명해진다. 육지 경계 자료가
///   없어서, "가장 가까운 지점까지 거리"를 육지 판정 대신 쓴다.
/// - 계산은 별도 아이솔레이트에서 한다(약 9만 화소 × 230 지점).
class HeatRaster {
  HeatRaster._();

  /// 남한 + 주변 바다. 지상 오버레이가 이 범위에 그림을 늘여 붙인다.
  static const double south = 32.8, north = 38.9, west = 124.3, east = 131.2;
  // 지도가 늘여 붙이면서 부드럽게 보간하므로 이 정도 해상도면 충분하다.
  static const int width = 220;
  static const int height = 250;

  static NLatLngBounds get bounds => const NLatLngBounds(
      southWest: NLatLng(south, west), northEast: NLatLng(north, east));

  /// @param points  (위도, 경도, 값)
  /// @param stops   (값, ARGB) 오름차순
  /// @param sparse  0 이하를 투명으로
  static Future<NOverlayImage?> build({
    required List<(double, double, double)> points,
    required List<(double, int)> stops,
    required bool sparse,
    double opacity = 0.72,
  }) async {
    if (points.length < 3) return null;
    final rgba = await compute(_paint, _Job(points, stops, sparse, opacity));
    final png = await _encodePng(rgba);
    if (png == null) return null;
    return NOverlayImage.fromByteArray(png);
  }

  static Future<Uint8List?> _encodePng(Uint8List rgba) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        rgba, width, height, ui.PixelFormat.rgba8888, completer.complete);
    final image = await completer.future;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}

class _Job {
  const _Job(this.points, this.stops, this.sparse, this.opacity);
  final List<(double, double, double)> points;
  final List<(double, int)> stops;
  final bool sparse;
  final double opacity;
}

double _mercY(double lat) =>
    math.log(math.tan(math.pi / 4 + lat * math.pi / 360));

Uint8List _paint(_Job job) {
  const w = HeatRaster.width, h = HeatRaster.height;
  final out = Uint8List(w * h * 4);
  final yTop = _mercY(HeatRaster.north), yBot = _mercY(HeatRaster.south);
  final n = job.points.length;
  final lats = Float64List(n), lons = Float64List(n), vals = Float64List(n);
  for (var i = 0; i < n; i++) {
    lats[i] = job.points[i].$1;
    lons[i] = job.points[i].$2;
    vals[i] = job.points[i].$3;
  }

  // 지점을 0.5° 칸에 나눠 담는다. 화소마다 230개 전부와 거리를 재면 디버그 실행에서
  // 첫 그림이 20초 걸렸다(2026-10-13). 주변 3×3 칸(약 ±80km)만 보면 충분하다 —
  // 그보다 먼 지점은 거리 4제곱 가중치라 결과에 거의 영향이 없다.
  const cell = 0.5;
  final buckets = <int, List<int>>{};
  int keyOf(int cy, int cx) => cy * 1000 + cx;
  for (var i = 0; i < n; i++) {
    buckets
        .putIfAbsent(
            keyOf((lats[i] / cell).floor(), (lons[i] / cell).floor()), () => [])
        .add(i);
  }

  // 가장 가까운 지점이 이 거리(km) 안이면 그대로, 바깥으로 갈수록 투명해진다.
  // 처음 16/30km 로 잡았더니 지점 간격이 넓은 강원·경북 산간에서 색이 끊겨 얼룩졌다
  // (2026-10-13 시뮬레이터). 지점 사이가 대략 20~35km 라 그보다 넉넉히 잡는다.
  const fullKm = 30.0, zeroKm = 48.0;
  final baseAlpha = (job.opacity * 255).round();

  for (var r = 0; r < h; r++) {
    // 지상 오버레이는 메르카토르로 늘어나므로 행마다 위도를 메르카토르 역변환으로 구한다.
    final y = yTop - (r + 0.5) / h * (yTop - yBot);
    final lat = (2 * math.atan(math.exp(y)) - math.pi / 2) * 180 / math.pi;
    final kx = 111.32 * math.cos(lat * math.pi / 180);
    for (var c = 0; c < w; c++) {
      final lon =
          HeatRaster.west + (c + 0.5) / w * (HeatRaster.east - HeatRaster.west);
      var sw = 0.0, sv = 0.0, nearest = double.infinity;
      final cy = (lat / cell).floor(), cx = (lon / cell).floor();
      for (var by = cy - 1; by <= cy + 1; by++) {
        for (var bx = cx - 1; bx <= cx + 1; bx++) {
          final list = buckets[keyOf(by, bx)];
          if (list == null) continue;
          for (final i in list) {
            final dx = (lons[i] - lon) * kx, dy = (lats[i] - lat) * 110.57;
            final d2 =
                dx * dx + dy * dy + 4.0; // +4: 지점 바로 위에서 무한대 방지(약 2km 완충)
            if (d2 < nearest) nearest = d2;
            final wgt = 1.0 / (d2 * d2); // 거리의 4제곱 — 가까운 지점이 더 강하게 이긴다
            sw += wgt;
            sv += wgt * vals[i];
          }
        }
      }
      if (sw == 0) continue; // 주변에 지점이 하나도 없다(바다·국경 밖)
      final dist = math.sqrt(nearest);
      if (dist >= zeroKm) continue;
      final v = sv / sw;
      if (job.sparse && v < 0.1) continue;
      final argb = _color(job.stops, v);
      final fade =
          dist <= fullKm ? 1.0 : 1.0 - (dist - fullKm) / (zeroKm - fullKm);
      final o = (r * w + c) * 4;
      out[o] = (argb >> 16) & 0xFF;
      out[o + 1] = (argb >> 8) & 0xFF;
      out[o + 2] = argb & 0xFF;
      out[o + 3] = (baseAlpha * fade).round();
    }
  }
  return out;
}

int _color(List<(double, int)> stops, double v) {
  if (v <= stops.first.$1) return stops.first.$2;
  for (var i = 1; i < stops.length; i++) {
    if (v <= stops[i].$1) {
      final a = stops[i - 1], b = stops[i];
      final t = ((v - a.$1) / (b.$1 - a.$1)).clamp(0.0, 1.0);
      int mix(int s) => (((a.$2 >> s) & 0xFF) +
              ((((b.$2 >> s) & 0xFF) - ((a.$2 >> s) & 0xFF)) * t))
          .round();
      return (0xFF << 24) | (mix(16) << 16) | (mix(8) << 8) | mix(0);
    }
  }
  return stops.last.$2;
}
