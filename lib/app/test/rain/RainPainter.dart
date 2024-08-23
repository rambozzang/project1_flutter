import 'package:flutter/material.dart';
import 'package:project1/app/test/rain/RainDrop.dart';

class RainPainter extends CustomPainter {
  final List<RainDrop> rainDrops;
  final double animation;

  RainPainter(this.rainDrops, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (var rain in rainDrops) {
      rain.fall(size.height);
      canvas.drawLine(
        Offset(rain.x, rain.y),
        Offset(rain.x, rain.y + rain.length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
