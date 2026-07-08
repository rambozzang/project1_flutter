import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 초미세/미세먼지 수치를 작은 반원 게이지로 표시.
/// [value]는 API에서 오는 문자열 수치('-', '통신장애' 등 포함 가능).
/// [grade]는 '좋음'/'보통'/'나쁨'/'매우나쁨' 중 하나.
/// [max]는 게이지 100% 기준 수치.
class DustHalfGauge extends StatelessWidget {
  final String label;
  final String? value;
  final String? grade;
  final int max;

  const DustHalfGauge({
    super.key,
    required this.label,
    this.value,
    this.grade,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = int.tryParse(value ?? '');
    final displayValue = parsed?.toString() ?? '-';
    final ratio = parsed == null ? 0.0 : (parsed / max).clamp(0.0, 1.0);
    final color = _dustColor(grade);
    final displayGrade = grade ?? '-';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 46,
          height: 23,
          child: CustomPaint(
            painter: _HalfGaugePainter(ratio: ratio, color: color),
          ),
        ),
        const SizedBox(height: 3),
        // 옅은 글래스 캡슐 위 표시 — 흰 텍스트 + 등급색 강조 + 섀도우로
        // 밝은 하늘 배경에서도 대비를 보장한다.
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
            ),
            children: [
              TextSpan(text: '$label ', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
              TextSpan(
                text: displayValue,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' · ',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: displayGrade,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HalfGaugePainter extends CustomPainter {
  final double ratio;
  final Color color;

  _HalfGaugePainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.height * 0.36;
    final arcRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height),
      width: size.width,
      height: size.height * 2,
    );

    const startAngle = math.pi;
    const totalSweep = math.pi;

    // 배경 트랙 — 옅은 글래스 캡슐 위에서도 보이도록 흰색 계열
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, startAngle, totalSweep, false, trackPaint);

    if (ratio <= 0) return;

    // 등급색 글로우 효과
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(arcRect, startAngle, totalSweep * ratio, false, glowPaint);

    // 등급색 솔리드 전경 호
    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, startAngle, totalSweep * ratio, false, foregroundPaint);

    // 끝단 인디케이터 점
    final tipAngle = startAngle + totalSweep * ratio;
    final rx = arcRect.width / 2;
    final ry = arcRect.height / 2;
    final tipX = arcRect.center.dx + rx * math.cos(tipAngle);
    final tipY = arcRect.center.dy + ry * math.sin(tipAngle);

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.42, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _HalfGaugePainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.color != color;
  }
}

Color _dustColor(String? grade) {
  switch (grade) {
    case '좋음':
      return const Color(0xFF29B6F6);
    case '보통':
      return const Color(0xFF66BB6A);
    case '나쁨':
      return const Color(0xFFFFA726);
    case '매우나쁨':
      return const Color(0xFFFF5252);
    default:
      return Colors.white70;
  }
}
