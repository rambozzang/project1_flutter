import 'package:flutter/material.dart';
import 'dart:math' as math;

class EnhancedSunlightEffect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: EnhancedSunlightPainter(),
      size: Size.infinite,
    );
  }
}

class EnhancedSunlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.9, size.height * 0.1);
    final endPoint = Offset(size.width * 0.2, size.height * 0.9);
    final angle = (endPoint - center).direction;

    // Main sun glow
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));

    canvas.drawCircle(center, size.width * 0.5, sunPaint);

    // Sun rays
    final rayPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final rayAngle = angle - math.pi / 2 + (math.pi / 6 * i);
      final startPoint = center;
      final endPoint = Offset(center.dx + math.cos(rayAngle) * size.width, center.dy + math.sin(rayAngle) * size.width);
      canvas.drawLine(startPoint, endPoint, rayPaint);
    }

    // Lens flares
    final flareCount = 6;
    final colors = [
      Colors.blue.withOpacity(0.3),
      Colors.purple.withOpacity(0.3),
      Colors.pink.withOpacity(0.3),
      Colors.orange.withOpacity(0.3),
      Colors.yellow.withOpacity(0.3),
      Colors.green.withOpacity(0.3),
    ];

    for (int i = 0; i < flareCount; i++) {
      final t = i / (flareCount - 1);
      final flareCenter = Offset.lerp(center, endPoint, t)!;
      final flareRadius = lerpDouble(size.width * 0.25, size.width * 0.05, t)!;
      final flareOpacity = lerpDouble(0.8, 0.2, t)!;

      final flarePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = colors[i].withOpacity(flareOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

      final flarePath = Path()..addOval(Rect.fromCircle(center: flareCenter, radius: flareRadius));

      canvas.drawPath(flarePath, flarePaint);

      // Inner glow
      final innerGlowPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            colors[i].withOpacity(flareOpacity * 0.5),
            colors[i].withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: flareCenter, radius: flareRadius));

      canvas.drawCircle(flareCenter, flareRadius * 0.9, innerGlowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

// Usage example
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blue[900], // Dark blue background
        child: EnhancedSunlightEffect(),
      ),
    );
  }
}
