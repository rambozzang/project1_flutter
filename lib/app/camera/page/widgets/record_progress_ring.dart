import 'dart:math';

import 'package:flutter/material.dart';

/// 촬영(셔터) 버튼 테두리를 따라 도는 녹화 진행 링.
///
/// 예전 촬영 화면(`animated_bar.dart`의 RecordingProgressIndicator)이 쓰던
/// 타이머 게이지를 현재 셔터 디자인(76px 원 + 흰 테두리 4.5px)에 맞춰 다시 그린 것.
/// 진행 0일 때는 기존 흰 테두리와 같은 모양이라 대기↔녹화 전환이 자연스럽다.
class RecordProgressRingPainter extends CustomPainter {
  RecordProgressRingPainter({
    required this.progress,
    this.strokeWidth = 4.5,
  });

  /// 0.0 ~ 1.0 (경과시간 / 제한시간)
  final double progress;
  final double strokeWidth;

  /// 진행 구간 색 — 시작(안전) → 끝(임박)으로 갈수록 붉게.
  static const List<Color> _progressColors = [
    Color(0xFF4CD964), // 시작: 그린
    Color(0xFFFFD54F), // 중반: 옐로우
    Color(0xFFFF9500), // 후반: 오렌지
    Color(0xFFFF3B30), // 종료 직전: 레드
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = (min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final double value = progress.clamp(0.0, 1.0);

    // 트랙(남은 시간) — 기존 흰 테두리보다 살짝 옅게
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (value <= 0) return;

    // 12시 방향에서 시작해 시계방향으로 채운다.
    const double startAngle = -pi / 2;
    final double sweepAngle = 2 * pi * value;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: [..._progressColors, Color(0xFF4CD964)], // 한 바퀴 이음새 제거
          startAngle: startAngle,
          endAngle: startAngle + 2 * pi,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // 진행 head 표시 — 어디까지 왔는지 눈에 바로 들어오게
    final double headAngle = startAngle + sweepAngle;
    final Offset head = Offset(
      center.dx + radius * cos(headAngle),
      center.dy + radius * sin(headAngle),
    );
    canvas.drawCircle(head, strokeWidth * 0.62, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(RecordProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.strokeWidth != strokeWidth;
}
