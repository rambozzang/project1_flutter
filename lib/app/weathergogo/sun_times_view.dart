import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/sun_times.dart';

/// 주간예보 아래 — 오늘 일출·일몰을 '작은 지구 반원(위성사진) + 태양 궤도'로 컴팩트 표현.
/// 탭하면 7일 일출·일몰 리스트가 모달로 뜬다. (위·경도 로컬 계산, 외부 API 없음)
class SunTimesView extends StatelessWidget {
  const SunTimesView({super.key});

  static const Color _riseColor = Color(0xFFFFC066); // 일출
  static const Color _setColor = Color(0xFF9FB6FF); // 일몰
  static const double _earthR = 52; // 지구(반원) 반지름
  static const double _orbitGap = 15; // 지표~태양궤도 간격
  static const double _stackH = 90; // 아크 영역 높이(컴팩트)

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
      final String rise = intl.DateFormat('HH:mm').format(sun.sunrise!);
      final String set = intl.DateFormat('HH:mm').format(sun.sunset!);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            _buildHeader(),
            const SizedBox(height: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showWeekModal(context, lat, lng, base),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 1, 10, 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.09)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: _stackH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          // 태양 궤도 + 현재 태양(글로우/광선)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _SunOrbitPainter(
                                progress: progress,
                                isDay: isDay,
                                earthR: _earthR,
                                orbitGap: _orbitGap,
                              ),
                            ),
                          ),
                          // 지구 반원(위성사진 상단 절반)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.topCenter,
                                heightFactor: 0.55,
                                child: SizedBox(
                                  width: _earthR * 2.2,
                                  height: _earthR * 2.2,
                                  child: ClipOval(
                                    child: Image.asset('assets/images/earth_blue_marble.jpg', fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 일출/일몰 시각(하단 좌우 — 지평선 끝)
                          Positioned(left: 2, bottom: 0, child: _timeTag(PhosphorIconsFill.sunHorizon, rise, _riseColor)),
                          Positioned(right: 2, bottom: 0, child: _timeTag(PhosphorIconsFill.moonStars, set, _setColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('7일 일출·일몰',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w500)),
                        Icon(Icons.chevron_right, size: 14, color: Colors.white.withOpacity(0.55)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
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
          PhosphorIcon(PhosphorIconsRegular.sunHorizon, color: Colors.white, size: 20),
          SizedBox(width: 5),
          Text('일출 · 일몰', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _timeTag(IconData icon, String time, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(
          time,
          style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
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
          _timeTag(PhosphorIconsFill.sunHorizon, rise, _riseColor),
          const SizedBox(width: 22),
          _timeTag(PhosphorIconsFill.moonStars, set, _setColor),
        ],
      ),
    );
  }
}

/// 지구 반원 위로 태양 궤도(반원)와 현재 태양/달 위치를 그린다.
class _SunOrbitPainter extends CustomPainter {
  final double progress; // 0(일출)~1(일몰)
  final bool isDay;
  final double earthR;
  final double orbitGap;
  _SunOrbitPainter({required this.progress, required this.isDay, required this.earthR, required this.orbitGap});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double baseY = size.height; // 지구 중심 = 하단(반원)
    final double r = earthR + orbitGap; // 태양 궤도 반지름
    final Rect rect = Rect.fromCircle(center: Offset(cx, baseY), radius: r);
    final double p = progress.clamp(0.0, 1.0);
    final Color sunColor = isDay ? const Color(0xFFFFD36E) : const Color(0xFFB4C0E0);

    // 궤도 배경.
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // 지나온 낮 부분(일출→현재).
    if (p > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * p,
        false,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFFFFB65C), Color(0xFFFFE49A), Color(0xFF9FB6FF)]).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // 현재 태양/달.
    final double theta = math.pi * (1 + p);
    final Offset pos = Offset(cx + r * math.cos(theta), baseY + r * math.sin(theta));
    canvas.drawCircle(
      pos,
      13,
      Paint()
        ..color = sunColor.withOpacity(isDay ? 0.5 : 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawCircle(
      pos,
      7,
      Paint()..shader = RadialGradient(colors: [Colors.white, sunColor]).createShader(Rect.fromCircle(center: pos, radius: 7)),
    );
    if (isDay) {
      final Paint ray = Paint()
        ..color = sunColor.withOpacity(0.85)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final double a = i * math.pi / 4;
        canvas.drawLine(pos + Offset(math.cos(a), math.sin(a)) * 10, pos + Offset(math.cos(a), math.sin(a)) * 13.5, ray);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SunOrbitPainter old) => old.progress != progress || old.isDay != isDay;
}
