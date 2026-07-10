import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/utils/utils.dart';

/// 날씨 메인 — 미세/초미세 먼지 상세 모달.
/// AirKorea API(백엔드 경유) 원본 데이터를 시각적으로 풍부하게 보여준다.
/// 원형 게이지 + 등급 카드 + 오염물질 그리드 + 기준표 + 건강 조언.
class DustDetailModal extends StatelessWidget {
  const DustDetailModal({
    super.key,
    required this.mistData,
    this.locationName = '현재 위치',
  });

  final MistData mistData;
  final String locationName;

  static void show(
    BuildContext context,
    MistData? mistData, {
    String? pm10,
    String? pm25,
    String? pm10Grade,
    String? pm25Grade,
    String locationName = '현재 위치',
  }) {
    final effective = mistData ??
        _createFallback(
          pm10: pm10,
          pm25: pm25,
          pm10Grade: pm10Grade,
          pm25Grade: pm25Grade,
        );
    if (effective == null || effective.items == null || effective.items!.isEmpty) {
      Utils.alert('미세먼지 상세 정보를 불러오지 못했습니다.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DustDetailModal(
        mistData: effective,
        locationName: locationName,
      ),
    );
  }

  static MistData? _createFallback({
    String? pm10,
    String? pm25,
    String? pm10Grade,
    String? pm25Grade,
  }) {
    if ((pm10 == null || pm10.isEmpty) && (pm25 == null || pm25.isEmpty)) {
      return null;
    }
    return MistData(
      items: [
        MistItemData(
          pm10Value: pm10,
          pm25Value: pm25,
          pm10Grade: _gradeCode(pm10Grade),
          pm25Grade: _gradeCode(pm25Grade),
        ),
      ],
    );
  }

  static String? _gradeCode(String? grade) {
    return switch (grade) {
      '좋음' => '1',
      '보통' => '2',
      '나쁨' => '3',
      '매우나쁨' => '4',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final item = mistData.items?.firstOrNull;
    final statusGrade = _worstGrade(item);
    final statusColor = _colorForGrade(statusGrade);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFF141A33),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // 상단 상태색 앰비언트 글로우 — 대기질 등급을 색으로 즉시 전달('살아있는 하늘' 톤과 연결).
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            height: 340,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.30),
                      statusColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 핸들
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, locationName, item?.dataTime, statusGrade, statusColor),
                        const SizedBox(height: 22),
                        _buildMainGauges(item),
                        const SizedBox(height: 26),
                        _buildKhaiCard(item),
                        const SizedBox(height: 20),
                        _buildPollutantGrid(item),
                        const SizedBox(height: 26),
                        _buildStandardTable(),
                        const SizedBox(height: 22),
                        _buildHealthTip(item),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String locationName, String? dataTime,
      String statusGrade, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const PhosphorIcon(PhosphorIconsFill.mapPin, color: Colors.white54, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                locationName,
                style: semiboldText.copyWith(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: PhosphorIcon(PhosphorIconsFill.x, color: Colors.white54, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 히어로 — 최악 등급을 큰 글자로 즉시 인지 + 한 줄 설명
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              statusGrade,
              style: TextStyle(
                fontSize: 40,
                height: 1.0,
                fontWeight: FontWeight.w800,
                color: statusColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _statusHeadline(statusGrade),
                  style: lightText.copyWith(
                      fontSize: 13, height: 1.35, color: Colors.white.withValues(alpha: 0.82)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          dataTime != null ? '측정 $dataTime 기준' : '측정시간 -',
          style: lightText.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  // 최악(높은) 등급을 대표 상태로 — pm10/pm25 등급 중 나쁜 쪽.
  String _worstGrade(MistItemData? item) {
    final g10 = int.tryParse(item?.pm10Grade ?? '') ?? 0;
    final g25 = int.tryParse(item?.pm25Grade ?? '') ?? 0;
    final worst = math.max(g10, g25);
    return _gradeText(worst == 0 ? null : worst.toString());
  }

  String _statusHeadline(String grade) {
    return switch (grade) {
      '좋음' => '공기가 아주 깨끗해요.\n야외 활동을 즐기기 좋아요.',
      '보통' => '무난한 대기질이에요.\n민감군은 컨디션을 살펴보세요.',
      '나쁨' => '공기가 좋지 않아요.\n외출 시 마스크를 챙기세요.',
      '매우나쁨' => '대기질이 매우 나빠요.\n실외 활동을 자제하세요.',
      _ => '측정 정보를 확인해 보세요.',
    };
  }

  Widget _buildMainGauges(MistItemData? item) {
    final pm10Value = _parse(item?.pm10Value);
    final pm25Value = _parse(item?.pm25Value);
    final pm10Grade = _gradeText(item?.pm10Grade);
    final pm25Grade = _gradeText(item?.pm25Grade);

    return Row(
      children: [
        Expanded(
          child: _circularGauge(
            label: '미세먼지',
            value: pm10Value,
            max: 150,
            grade: pm10Grade,
            unit: '㎍/㎥',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _circularGauge(
            label: '초미세먼지',
            value: pm25Value,
            max: 75,
            grade: pm25Grade,
            unit: '㎍/㎥',
          ),
        ),
      ],
    );
  }

  Widget _buildKhaiCard(MistItemData? item) {
    final value = _parse(item?.khaiValue);
    final grade = _gradeText(item?.khaiGrade);
    final color = _colorForValue(value, khaiBreaks);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(PhosphorIconsFill.wind, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('통합대기환경지수', style: mediumText.copyWith(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '${value >= 0 ? value.toStringAsFixed(0) : '-'}  $grade',
                  style: boldText.copyWith(fontSize: 20, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantGrid(MistItemData? item) {
    final pollutants = [
      _Pollutant('오존', item?.o3Value, item?.o3Grade, 'ppm'),
      _Pollutant('이산화질소', item?.no2Value, item?.no2Grade, 'ppm'),
      _Pollutant('아황산가스', item?.so2Value, item?.so2Grade, 'ppm'),
      _Pollutant('일산화탄소', item?.coValue, item?.coGrade, 'ppm'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('상세 오염 물질', style: semiboldText.copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: pollutants.map((p) => _pollutantCard(p)).toList(),
        ),
      ],
    );
  }

  Widget _pollutantCard(_Pollutant p) {
    final value = _parse(p.value);
    final grade = _gradeText(p.grade);
    final color = _colorForGrade(grade);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(p.name, style: lightText.copyWith(fontSize: 12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value >= 0 ? value.toStringAsFixed(3) : '-',
                style: boldText.copyWith(fontSize: 17),
              ),
              const SizedBox(width: 4),
              Text(p.unit, style: lightText.copyWith(fontSize: 10, color: Colors.white54)),
            ],
          ),
          Text(
            grade,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardTable() {
    final rows = [
      _StandardRow('좋음', '0~30', '0~15', '0~50', const Color(0xFF2196F3)),
      _StandardRow('보통', '31~80', '16~35', '51~100', const Color(0xFF00BCD4)),
      _StandardRow('나쁨', '81~150', '36~75', '101~250', const Color(0xFFFF9800)),
      _StandardRow('매우나쁨', '151~', '76~', '251~', const Color(0xFFF44336)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('대기질 기준표', style: semiboldText.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 3, child: Text('등급', style: lightText.copyWith(fontSize: 11, color: Colors.white54))),
              Expanded(flex: 3, child: Text('미세먼지', style: lightText.copyWith(fontSize: 11, color: Colors.white54))),
              Expanded(flex: 3, child: Text('초미세먼지', style: lightText.copyWith(fontSize: 11, color: Colors.white54))),
              Expanded(flex: 3, child: Text('통합지수', style: lightText.copyWith(fontSize: 11, color: Colors.white54))),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          r.grade,
                          style: TextStyle(fontSize: 12, color: r.color, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 3, child: Text(r.pm10, style: lightText.copyWith(fontSize: 12))),
                Expanded(flex: 3, child: Text(r.pm25, style: lightText.copyWith(fontSize: 12))),
                Expanded(flex: 3, child: Text(r.khai, style: lightText.copyWith(fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHealthTip(MistItemData? item) {
    final pm10 = _parse(item?.pm10Value);
    final pm25 = _parse(item?.pm25Value);
    final worst = math.max(pm10 >= 0 ? pm10 / 150 : 0, pm25 >= 0 ? pm25 / 75 : 0);
    final tip = worst > 0.66
        ? '실외 활동을 자제하고 마스크를 착용하세요. 창문을 닫아 실내 공기를 정화하세요.'
        : worst > 0.33
            ? '민감군은 실외 활동 시 마스크를 착용하고, 장시간 야외 활동을 줄이세요.'
            : '오늘은 공기가 깨끗합니다. 가벼운 실외 활동을 즐기기 좋아요.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PhosphorIcon(PhosphorIconsFill.heart, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: lightText.copyWith(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularGauge({
    required String label,
    required double value,
    required int max,
    required String grade,
    required String unit,
  }) {
    final ratio = value >= 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final color = _colorForValue(value, label == '초미세먼지' ? pm25Breaks : pm10Breaks);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(label, style: mediumText.copyWith(fontSize: 14)),
          const SizedBox(height: 14),
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _GaugePainter(ratio: ratio, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value >= 0 ? value.toStringAsFixed(0) : '-',
                      style: boldText.copyWith(fontSize: 26, color: color),
                    ),
                    Text(unit, style: lightText.copyWith(fontSize: 10, color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              grade,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  double _parse(String? value) {
    if (value == null) return -1;
    return double.tryParse(value) ?? -1;
  }

  String _gradeText(String? gradeCode) {
    switch (gradeCode) {
      case '1':
        return '좋음';
      case '2':
        return '보통';
      case '3':
        return '나쁨';
      case '4':
        return '매우나쁨';
      default:
        return '-';
    }
  }

  Color _colorForGrade(String grade) {
    return switch (grade) {
      '좋음' => const Color(0xFF2196F3),
      '보통' => const Color(0xFF00BCD4),
      '나쁨' => const Color(0xFFFF9800),
      '매우나쁨' => const Color(0xFFF44336),
      _ => Colors.white54,
    };
  }

  Color _colorForValue(double value, List<double> breaks) {
    if (value < 0) return Colors.white54;
    final colors = [const Color(0xFF2196F3), const Color(0xFF00BCD4), const Color(0xFFFFEB3B), const Color(0xFFF44336)];
    for (int i = 0; i < breaks.length; i++) {
      if (value <= breaks[i]) {
        if (i == 0) return colors[0];
        final prev = breaks[i - 1];
        final t = ((value - prev) / (breaks[i] - prev)).clamp(0.0, 1.0);
        return Color.lerp(colors[i - 1], colors[i], t)!;
      }
    }
    return colors.last;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const pm10Breaks = [30.0, 80.0, 150.0];
const pm25Breaks = [15.0, 35.0, 75.0];
const khaiBreaks = [50.0, 100.0, 250.0];

class _GaugePainter extends CustomPainter {
  final double ratio;
  final Color color;

  _GaugePainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);

    // 배경 아크
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi * 0.75, math.pi * 1.5, false, bgPaint);

    // 글로우 — 채움 아크 아래 은은한 빛으로 상태색을 강조
    if (ratio > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(rect, math.pi * 0.75, math.pi * 1.5 * ratio, false, glowPaint);
    }

    // 채움 아크
    final fillPaint = Paint()
      ..shader = SweepGradient(
        startAngle: math.pi * 0.75,
        endAngle: math.pi * 0.75 + math.pi * 1.5,
        colors: [color, color.withValues(alpha: 0.6)],
        stops: const [0.0, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi * 0.75, math.pi * 1.5 * ratio, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Pollutant {
  final String name;
  final String? value;
  final String? grade;
  final String unit;
  _Pollutant(this.name, this.value, this.grade, this.unit);
}

class _StandardRow {
  final String grade;
  final String pm10;
  final String pm25;
  final String khai;
  final Color color;
  _StandardRow(this.grade, this.pm10, this.pm25, this.khai, this.color);
}
