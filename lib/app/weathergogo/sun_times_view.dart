import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/sun_times.dart';

/// 주간예보 아래 — 날짜별 일출·일몰 리니어 리스트.
/// 위·경도 + 날짜로 로컬 계산(외부 API 없음). 오늘 포함 7일.
class SunTimesView extends StatelessWidget {
  const SunTimesView({super.key});

  static const Color _riseColor = Color(0xFFFFC978); // 일출 — 따뜻한 오렌지
  static const Color _setColor = Color(0xFF9FB6FF); // 일몰 — 보랏빛 블루

  @override
  Widget build(BuildContext context) {
    final cntr = Get.find<WeatherGogoCntr>();
    return Obx(() {
      final latLng = cntr.currentLocation.value.latLng;
      // 위치 미확정(기본 0,0)이면 표시 안 함.
      if (latLng.latitude.abs() < 0.001 && latLng.longitude.abs() < 0.001) {
        return const SizedBox.shrink();
      }
      final double lat = latLng.latitude;
      final double lng = latLng.longitude;
      final DateTime now = DateTime.now();
      final DateTime base = DateTime(now.year, now.month, now.day);
      final List<DateTime> days = List.generate(7, (i) => base.add(Duration(days: i)));

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 10),
            for (final d in days) _buildRow(d, computeSunTimes(lat, lng, d), d.day == base.day),
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

  Widget _buildRow(DateTime date, SunTimes sun, bool isToday) {
    final String dateLabel = intl.DateFormat('dd(E)', 'ko').format(date);
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
            child: Text(
              isToday ? '오늘' : dateLabel,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          _timeChip(PhosphorIconsFill.sunHorizon, rise, _riseColor),
          const SizedBox(width: 22),
          _timeChip(PhosphorIconsFill.moonStars, set, _setColor),
        ],
      ),
    );
  }

  Widget _timeChip(IconData icon, String time, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, color: color, size: 16),
        const SizedBox(width: 5),
        Text(
          time,
          style: TextStyle(
            fontSize: 14.5,
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
