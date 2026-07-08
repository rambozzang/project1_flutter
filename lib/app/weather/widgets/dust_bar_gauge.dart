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
    final color = _dustColor(grade);
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
              shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
            ),
            children: [
              TextSpan(text: '$label ', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
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
            color: Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 3, offset: const Offset(0, 1)),
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
