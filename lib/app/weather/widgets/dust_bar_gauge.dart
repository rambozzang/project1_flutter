import 'package:flutter/material.dart';

/// 미세/초미세 수치를 배경 없이 얇은 가로 바로 표시.
/// 하늘 그라데이션 위에 바로 얹히므로 텍스트 섀도우 + 바 그림자로 가독성을 확보한다.
/// [value]는 API에서 오는 문자열 수치('-', '통신장애' 등 포함 가능).
/// [grade]는 '좋음'/'보통'/'나쁨'/'매우나쁨' 중 하나 — 바 채움색이 등급을 따라간다.
/// [max]는 바 100% 기준 수치.
class DustBarGauge extends StatelessWidget {
  final String label;
  final String? value;
  final String? grade;
  final int max;

  const DustBarGauge({
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
    // 낮은 농도('좋음')에서도 색 조각이 보이도록 최소 6% 채움.
    final ratio = parsed == null ? 0.0 : (parsed / max).clamp(0.06, 1.0);
    final color = _dustColor(grade, ratio);
    final displayGrade = grade ?? '-';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              // 밝은 하늘 위에서도 또렷하게 — 촘촘한 진한 윤곽 그림자 + 은은한 확산 그림자 이중 halo.
              // (크기는 그대로 두고 대비만 끌어올린다. 특히 '좋음'의 파란 글자가 파란 하늘에 묻히던 문제 완화)
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 2),
                Shadow(color: Colors.black54, blurRadius: 6),
              ],
            ),
            children: [
              TextSpan(text: '$label ', style: TextStyle(color: Colors.white.withValues(alpha: 0.95))),
              TextSpan(
                text: displayValue,
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: ' $displayGrade',
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 등급색 채움 가로 바 — 트랙은 반투명 흰색, 밝은 배경 대비용 옅은 그림자.
        Container(
          width: 84,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(3),
            // 밝은 배경에서 바 경계가 사라지지 않도록 얇은 진한 윤곽 + 옅은 그림자(크기 변화 없음).
            border: Border.all(color: Colors.black.withValues(alpha: 0.18), width: 0.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 3, offset: const Offset(0, 1)),
            ],
          ),
          child: parsed == null
              ? null
              : Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

Color _dustColor(String? grade, double ratio) {
  if (grade == null) return Colors.white70;
  // 미세/초미세 농도 비율에 따라 파란색(좋음) → 노란색 → 빨간색(나쁨)으로 연속 변화.
  const blue = Color(0xFF2196F3);
  const yellow = Color(0xFFFFEB3B);
  const red = Color(0xFFF44336);
  final t = ratio.clamp(0.0, 1.0);
  if (t <= 0.5) {
    return Color.lerp(blue, yellow, t * 2)!;
  }
  return Color.lerp(yellow, red, (t - 0.5) * 2)!;
}
