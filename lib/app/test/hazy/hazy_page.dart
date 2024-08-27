import 'dart:math' as math;
import 'package:flutter/material.dart';

class HazyParticle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;

  HazyParticle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble() * 400;
    y = math.Random().nextDouble() * 800;
    size = math.Random().nextDouble() * 3 + 1; // 1-4 사이의 크기
    speed = math.Random().nextDouble() * 0.5 + 0.1; // 0.1-0.6 사이의 속도
    opacity = math.Random().nextDouble() * 0.1 + 0.05; // 0.05-0.15 사이의 투명도
  }

  void move(double height) {
    y -= speed;
    if (y < 0) {
      y = height;
      x = math.Random().nextDouble() * 400;
    }
  }
}

class HazyPainter extends CustomPainter {
  final List<HazyParticle> particles;
  final double animation;

  HazyPainter(this.particles, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    // 전체 화면에 흐린 효과 적용
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.001)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // 입자 그리기
    for (var particle in particles) {
      particle.move(size.height);

      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class HazyAnimation extends StatefulWidget {
  final ValueNotifier<bool> isVisibleNotifier;

  const HazyAnimation({Key? key, required this.isVisibleNotifier}) : super(key: key);

  @override
  _HazyAnimationState createState() => _HazyAnimationState();
}

class _HazyAnimationState extends State<HazyAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<HazyParticle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    for (int i = 0; i < 100; i++) {
      // 100개의 입자 생성
      particles.add(HazyParticle());
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
                    painter: HazyPainter(particles, _controller.value),
                    size: Size.infinite,
                  );
                },
              )
            : Container();
      },
    );
  }
}
