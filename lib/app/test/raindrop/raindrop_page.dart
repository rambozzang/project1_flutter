import 'dart:math' as math;
import 'package:flutter/material.dart';

class RainDrop {
  late double x;
  late double y;
  late double length;
  late double speed;
  late double opacity;

  RainDrop() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble() * 400;
    y = math.Random().nextDouble() * 1200 - 1200;
    length = math.Random().nextDouble() * 15 + 5; // 길이를 5-20으로 줄임
    speed = math.Random().nextDouble() * 17 + 1; // 속도를 1-4로 줄임
    opacity = math.Random().nextDouble() * 0.3 + 0.1; // 불투명도 0.1-0.4로 줄임
  }

  void fall(double height) {
    y += speed;
    if (y > height) {
      reset();
    }
  }
}

class RainPainter extends CustomPainter {
  final List<RainDrop> rainDrops;
  final double animation;

  RainPainter(this.rainDrops, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (var rain in rainDrops) {
      rain.fall(size.height);

      final paint = Paint()
        ..color = Colors.white.withOpacity(rain.opacity)
        ..strokeWidth = 2.5 // 선의 굵기를 줄임
        ..strokeCap = StrokeCap.round;

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

class RainDropAnimation extends StatefulWidget {
  final ValueNotifier<bool> isVisibleNotifier;

  const RainDropAnimation({Key? key, required this.isVisibleNotifier}) : super(key: key);

  @override
  _RainDropAnimationState createState() => _RainDropAnimationState();
}

class _RainDropAnimationState extends State<RainDropAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<RainDrop> rainDrops = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // 애니메이션 주기를 늘림
      vsync: this,
    )..repeat();

    for (int i = 0; i < 50; i++) {
      // 빗방울의 수를 50개로 줄임
      rainDrops.add(RainDrop());
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
                    painter: RainPainter(rainDrops, _controller.value),
                    size: Size.infinite,
                  );
                },
              )
            : Container();
      },
    );
  }
}
