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
  static const double _earthR = 50; // 지구(반원) 반지름
  static const double _orbitGap = 15; // 지표~태양궤도 간격
  static const double _stackH = 98; // 아크 영역 높이(컴팩트)
  static const double _earthVisibleFrac = 0.6; // 지구 원의 상단 노출 비율(heightFactor와 동일해야 궤도가 동심)

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
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: _stackH,
                      child: LayoutBuilder(
                        builder: (context, cons) {
                          final double cx = cons.maxWidth / 2;
                          final double r = _earthR + _orbitGap;
                          // 지구는 상단 60%만 노출되므로 원의 실제 중심은 하단보다 위 — 태양·궤도 모두 이 중심 기준(동심원).
                          const double earthCy = _stackH - _earthR * 2 * _earthVisibleFrac + _earthR;
                          final double theta = math.pi * (1 + progress);
                          final Offset sunPos = Offset(cx + r * math.cos(theta), earthCy + r * math.sin(theta));
                          const double sunSize = 26;
                          return Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              // 태양 궤도(선만)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _SunOrbitPainter(
                                    progress: progress,
                                    isDay: isDay,
                                    earthR: _earthR,
                                    orbitGap: _orbitGap,
                                    earthCenterY: earthCy,
                                  ),
                                ),
                              ),
                              // 지구 반원(위성사진 상단 절반)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor: _earthVisibleFrac,
                                    child: SizedBox(
                                      width: _earthR * 2,
                                      height: _earthR * 2,
                                      child: ClipOval(
                                        // 이미지 속 검은 우주(여백)를 잘라내 지구 원반이 원을 가득 채우도록 확대.
                                        child: Transform.scale(
                                          scale: 1.15,
                                          child: Image.asset('assets/images/earth_blue_marble.jpg', fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // 현재 태양(위성사진) — 궤도 위치에 얹음
                              Positioned(
                                left: sunPos.dx - sunSize / 2,
                                top: sunPos.dy - sunSize / 2,
                                child: _sunWidget(sunSize, isDay),
                              ),
                              // 일출/일몰 시각(하단 좌우 — 지평선 끝)
                              Positioned(left: 2, bottom: 0, child: _timeTag(PhosphorIconsFill.sunHorizon, rise, _riseColor)),
                              Positioned(right: 2, bottom: 0, child: _timeTag(PhosphorIconsFill.moonStars, set, _setColor)),
                            ],
                          );
                        },
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

  // 현재 태양 — NASA 태양 위성사진(원형) + 은은한 글로우.
  Widget _sunWidget(double size, bool isDay) {
    final Color glow = isDay ? const Color(0xFFFFD36E) : const Color(0xFFB4C0E0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: glow.withOpacity(0.65), blurRadius: 12, spreadRadius: 1)],
      ),
      child: ClipOval(
        // 이미지 속 검은 우주(여백)를 잘라내 태양 원반이 원을 가득 채우도록 확대.
        child: Transform.scale(
          scale: 1.28,
          child: Image.asset('assets/images/sun_disk.jpg', fit: BoxFit.cover),
        ),
      ),
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
  final double earthCenterY; // 지구 원의 실제 중심 y(상단만 노출되므로 하단보다 위)
  _SunOrbitPainter(
      {required this.progress, required this.isDay, required this.earthR, required this.orbitGap, required this.earthCenterY});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double baseY = earthCenterY; // 지구와 동심원 — 지표~궤도 간격이 전 구간 일정
    final double r = earthR + orbitGap; // 태양 궤도 반지름
    final Rect rect = Rect.fromCircle(center: Offset(cx, baseY), radius: r);
    final double p = progress.clamp(0.0, 1.0);

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

    // 태양은 위성사진(Positioned Image)으로 궤도 위에 얹으므로 여기선 궤도만 그린다.
  }

  @override
  bool shouldRepaint(covariant _SunOrbitPainter old) => old.progress != progress || old.isDay != isDay;
}
