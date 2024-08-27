import 'dart:math' as math;
import 'package:flutter/material.dart';

class SunRay {
  late double angle;
  late double length;
  late double speed;
  late double opacity;

  SunRay() {
    reset();
  }

  void reset() {
    angle = math.Random().nextDouble() * 2 * math.pi;
    length = math.Random().nextDouble() * 50 + 100; // 100-150 사이의 길이
    speed = math.Random().nextDouble() * 0.03 + 0.01; // 0.01-0.04 사이의 속도
    opacity = math.Random().nextDouble() * 0.4 + 0.2; // 0.2-0.6 사이의 투명도
  }

  void move() {
    angle += speed;
    if (angle > 2 * math.pi) {
      angle -= 2 * math.pi;
    }
    opacity = 0.2 + 0.4 * math.sin(angle); // 투명도 변화 추가
  }
}

class LensFlare {
  late Offset position;
  late double size;
  late Color color;

  LensFlare(Offset sunPosition, Size screenSize) {
    reset(sunPosition, screenSize);
  }

  void reset(Offset sunPosition, Size screenSize) {
    double distance = math.Random().nextDouble() * 200 + 100;
    double angle = math.Random().nextDouble() * 2 * math.pi;
    position = Offset(
      sunPosition.dx + distance * math.cos(angle),
      sunPosition.dy + distance * math.sin(angle),
    );
    size = math.Random().nextDouble() * 20 + 5;
    color = [Colors.blue, Colors.green, Colors.orange, Colors.purple][math.Random().nextInt(4)].withOpacity(0.3);
  }
}

class EnhancedSunnyPainter extends CustomPainter {
  final List<SunRay> sunRays;
  final List<LensFlare> lensFlares;
  final double animation;

  EnhancedSunnyPainter(this.sunRays, this.lensFlares, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 4);

    // 하늘 그리기
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // 태양 글로우 효과
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Color(0xFFFFD700).withOpacity(0.6), Color(0xFFFFD700).withOpacity(0)],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 100));
    canvas.drawCircle(center, 100, glowPaint);

    // 태양 그리기
    final sunPaint = Paint()
      ..color = Color(0xFFFDB813)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 50, sunPaint);

    // 태양 광선 그리기
    for (var ray in sunRays) {
      ray.move();
      final rayPaint = Paint()
        ..color = Color(0xFFFDB813).withOpacity(ray.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final start = Offset(center.dx + 50 * math.cos(ray.angle), center.dy + 50 * math.sin(ray.angle));
      final end = Offset(center.dx + (50 + ray.length) * math.cos(ray.angle), center.dy + (50 + ray.length) * math.sin(ray.angle));
      canvas.drawLine(start, end, rayPaint);
    }

    // 렌즈 플레어 효과
    for (var flare in lensFlares) {
      final flarePaint = Paint()
        ..color = flare.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(flare.position, flare.size, flarePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class SunnyAnimation extends StatefulWidget {
  final ValueNotifier<bool> isVisibleNotifier;

  const SunnyAnimation({Key? key, required this.isVisibleNotifier}) : super(key: key);

  @override
  _SunnyAnimationState createState() => _SunnyAnimationState();
}

class _SunnyAnimationState extends State<SunnyAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<SunRay> sunRays = [];
  List<LensFlare> lensFlares = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    for (int i = 0; i < 20; i++) {
      // 20개의 태양 광선 생성
      sunRays.add(SunRay());
    }

    for (int i = 0; i < 5; i++) {
      // 5개의 렌즈 플레어 생성
      lensFlares.add(LensFlare(Offset(200, 150), Size(400, 600)));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isVisibleNotifier,
      builder: (context, isVisible, child) {
        return isVisible
            ? AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: EnhancedSunnyPainter(sunRays, lensFlares, _controller.value),
                    size: Size.infinite,
                  );
                },
              )
            : Container();
      },
    );
  }
}
