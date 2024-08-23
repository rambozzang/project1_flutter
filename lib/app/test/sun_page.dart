import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;

class SunlightAnimationPage extends StatefulWidget {
  @override
  _SunlightAnimationPageState createState() => _SunlightAnimationPageState();
}

class _SunlightAnimationPageState extends State<SunlightAnimationPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: DiagonalSunlightPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class DiagonalSunlightPainter extends CustomPainter {
  final double animationValue;

  DiagonalSunlightPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final sunPosition = Offset(size.width * 0.2, -size.height * 0.1);
    final rayCount = 10;
    final maxRayWidth = size.width * 0.4;
    final rayAngle = pi / 6; // 30도

    for (int i = 0; i < rayCount; i++) {
      final t = (i / (rayCount - 1) + animationValue) % 1.0;
      final rayWidth = maxRayWidth * t;

      final startAngle = -rayAngle / 2 + rayAngle * i / (rayCount - 1);
      final endAngle = startAngle + rayAngle / (rayCount - 1);

      final path = Path()
        ..moveTo(sunPosition.dx, sunPosition.dy)
        ..lineTo(
          sunPosition.dx + cos(startAngle) * size.height * 2,
          sunPosition.dy + sin(startAngle) * size.height * 2,
        )
        ..lineTo(
          sunPosition.dx + cos(endAngle) * size.height * 2,
          sunPosition.dy + sin(endAngle) * size.height * 2,
        )
        ..close();

      final paint = Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.8, -1.0),
          radius: 1.5,
          colors: [
            Color(0xFFFFD700).withOpacity(0.7 * (1 - t)), // 금색
            Color(0xFFFFA500).withOpacity(0.5 * (1 - t)), // 주황색
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
