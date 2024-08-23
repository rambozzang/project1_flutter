// painters/snow_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:project1/app/test/snow/Snowflake.dart';

class SnowPainter extends CustomPainter {
  final List<Snowflake> snowflakes;
  final double animation;
  final double windStrength;

  SnowPainter(this.snowflakes, this.animation) : windStrength = math.sin(animation * 2 * math.pi) * 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    for (var snowflake in snowflakes) {
      snowflake.fall(size.height, size.width, animation, windStrength);

      final paint = Paint()
        ..color = Colors.white.withOpacity(snowflake.opacity)
        ..style = PaintingStyle.fill;

      Path path = Path()
        ..addOval(Rect.fromCircle(center: Offset(snowflake.x, snowflake.y), radius: snowflake.size))
        ..addOval(Rect.fromCircle(center: Offset(snowflake.x - snowflake.size, snowflake.y), radius: snowflake.size * 0.7))
        ..addOval(Rect.fromCircle(center: Offset(snowflake.x + snowflake.size, snowflake.y), radius: snowflake.size * 0.7))
        ..addOval(Rect.fromCircle(center: Offset(snowflake.x, snowflake.y - snowflake.size), radius: snowflake.size * 0.7))
        ..addOval(Rect.fromCircle(center: Offset(snowflake.x, snowflake.y + snowflake.size), radius: snowflake.size * 0.7));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
