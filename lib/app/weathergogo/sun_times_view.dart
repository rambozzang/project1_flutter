import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/sun_times.dart';

/// 주간예보 아래 — 오늘 일출·일몰을 반달(돔) 아크로 표현하고 현재 태양 위치를 표시.
/// 탭하면 7일 일출·일몰 리스트가 모달로 뜬다. (위·경도 로컬 계산, 외부 API 없음)
class SunTimesView extends StatelessWidget {
  const SunTimesView({super.key});

  static const Color _riseColor = Color(0xFFFFC066); // 일출 — 따뜻한 오렌지
  static const Color _setColor = Color(0xFF9FB6FF); // 일몰 — 보랏빛 블루

  @override
  Widget build(BuildContext context) {
    final cntr = Get.find<WeatherGogoCntr>();
    return Obx(() {
      final latLng = cntr.currentLocation.value.latLng;
      if (latLng.latitude.abs() < 0.001 && latLng.longitude.abs() < 0.001) {
        return const SizedBox.shrink();
      }
      final double lat = latLng.latitude;
      final double lng = latLng.longitude;
      final DateTime nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
      final DateTime base = DateTime(nowKst.year, nowKst.month, nowKst.day);
      final SunTimes sun = computeSunTimes(lat, lng, base);
      if (!sun.hasData) return const SizedBox.shrink();

      final int riseM = sun.sunrise!.hour * 60 + sun.sunrise!.minute;
      final int setM = sun.sunset!.hour * 60 + sun.sunset!.minute;
      final int nowM = nowKst.hour * 60 + nowKst.minute;
      final double progress = (setM > riseM) ? ((nowM - riseM) / (setM - riseM)).clamp(0.0, 1.0) : 0.0;
      final bool isDay = nowM >= riseM && nowM <= setM;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showWeekModal(context, lat, lng, base),
              child: _buildArcCard(sun, progress, isDay, setM - riseM),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIconsRegular.sunHorizon, color: Colors.white, size: 22),
          SizedBox(width: 5),
          Text('일출 · 일몰', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildArcCard(SunTimes sun, double progress, bool isDay, int dayMin) {
    final String rise = intl.DateFormat('HH:mm').format(sun.sunrise!);
    final String set = intl.DateFormat('HH:mm').format(sun.sunset!);
    final String dayLen = '${dayMin ~/ 60}시간 ${dayMin % 60}분';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 2.5,
            child: CustomPaint(painter: _SunArcPainter(progress: progress, isDay: isDay)),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _endLabel(PhosphorIconsFill.sunHorizon, '일출', rise, _riseColor, CrossAxisAlignment.start),
              Expanded(
                child: Column(
                  children: [
                    Text('낮 길이', style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.55))),
                    const SizedBox(height: 2),
                    Text(dayLen, style: const TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              _endLabel(PhosphorIconsFill.moonStars, '일몰', set, _setColor, CrossAxisAlignment.end),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('7일 일출·일몰 보기', style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500)),
              Icon(Icons.chevron_right, size: 15, color: Colors.white.withOpacity(0.6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _endLabel(IconData icon, String label, String time, Color color, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, color: color, size: 15),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  // ── 7일 모달 ────────────────────────────────────────────────────────────
  void _showWeekModal(BuildContext context, double lat, double lng, DateTime base) {
    final List<DateTime> days = List.generate(7, (i) => base.add(Duration(days: i)));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121834),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Row(
                    children: [
                      PhosphorIcon(PhosphorIconsRegular.sunHorizon, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('7일 일출 · 일몰', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Column(
                    children: [
                      for (final d in days) _weekRow(d, computeSunTimes(lat, lng, d), d.day == base.day),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _weekRow(DateTime date, SunTimes sun, bool isToday) {
    final String dateLabel = isToday ? '오늘' : intl.DateFormat('dd(E)', 'ko').format(date);
    final String rise = sun.sunrise != null ? intl.DateFormat('HH:mm').format(sun.sunrise!) : '--:--';
    final String set = sun.sunset != null ? intl.DateFormat('HH:mm').format(sun.sunset!) : '--:--';
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isToday ? Colors.white.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(dateLabel,
                style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: isToday ? FontWeight.bold : FontWeight.w500)),
          ),
          const Spacer(),
          _chip(PhosphorIconsFill.sunHorizon, rise, _riseColor),
          const SizedBox(width: 22),
          _chip(PhosphorIconsFill.moonStars, set, _setColor),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String time, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, color: color, size: 16),
        const SizedBox(width: 5),
        Text(time,
            style: TextStyle(fontSize: 14.5, color: color, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

/// 반달(돔) 아크 + 현재 태양(또는 달) 위치를 화려하게 그린다.
class _SunArcPainter extends CustomPainter {
  final double progress; // 0(일출)~1(일몰)
  final bool isDay;
  _SunArcPainter({required this.progress, required this.isDay});

  @override
  void paint(Canvas canvas, Size size) {
    final double horizonY = size.height * 0.9;
    final double cx = size.width / 2;
    final double r = math.min(size.width / 2 - 18, horizonY - 10);
    final Offset center = Offset(cx, horizonY);
    final Rect arcRect = Rect.fromCircle(center: center, radius: r);
    final double p = progress.clamp(0.0, 1.0);

    final Color sunColor = isDay ? const Color(0xFFFFD36E) : const Color(0xFFB4C0E0);

    // 돔 내부 은은한 채움(따뜻한 빛이 위에서 아래로 사라짐).
    final Path dome = Path()
      ..addArc(arcRect, math.pi, math.pi)
      ..lineTo(cx - r, horizonY)
      ..close();
    canvas.drawPath(
      dome,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sunColor.withOpacity(0.16), Colors.transparent],
        ).createShader(Rect.fromLTWH(cx - r, horizonY - r, r * 2, r)),
    );

    // 배경 아크(전체 경로).
    canvas.drawArc(
      arcRect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // 지나온 낮 부분(일출→현재) 그라디언트 아크.
    if (p > 0) {
      canvas.drawArc(
        arcRect,
        math.pi,
        math.pi * p,
        false,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFB65C), Color(0xFFFFE49A), Color(0xFF9FB6FF)],
          ).createShader(arcRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // 지평선.
    canvas.drawLine(
      Offset(6, horizonY),
      Offset(size.width - 6, horizonY),
      Paint()
        ..color = Colors.white.withOpacity(0.22)
        ..strokeWidth = 1.2,
    );

    // 현재 태양/달 위치 (돔 위: θ = π(1+p)).
    final double theta = math.pi * (1 + p);
    final Offset pos = Offset(cx + r * math.cos(theta), horizonY + r * math.sin(theta));

    // 글로우.
    canvas.drawCircle(
      pos,
      18,
      Paint()
        ..color = sunColor.withOpacity(isDay ? 0.55 : 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
    );
    // 본체(라디얼 그라디언트).
    canvas.drawCircle(
      pos,
      8.5,
      Paint()
        ..shader = RadialGradient(colors: [Colors.white, sunColor])
            .createShader(Rect.fromCircle(center: pos, radius: 8.5)),
    );
    // 태양 광선(낮에만).
    if (isDay) {
      final ray = Paint()
        ..color = sunColor.withOpacity(0.85)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final double a = i * math.pi / 4;
        final Offset s = pos + Offset(math.cos(a), math.sin(a)) * 12;
        final Offset e = pos + Offset(math.cos(a), math.sin(a)) * 16;
        canvas.drawLine(s, e, ray);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter old) => old.progress != progress || old.isDay != isDay;
}
