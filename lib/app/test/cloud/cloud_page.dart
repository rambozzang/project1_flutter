import 'dart:math' as math;
import 'package:flutter/material.dart';

class Cloud {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;

  Cloud() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble() * 400 - 100; // 화면 밖에서 시작할 수 있게
    y = math.Random().nextDouble() * 500;
    size = math.Random().nextDouble() * 60 + 40; // 40-100 사이의 크기
    speed = math.Random().nextDouble() * 0.5 + 0.1; // 0.1-0.6 사이의 속도
    opacity = math.Random().nextDouble() * 0.5 + 0.1; // 0.1-0.4 사이의 투명도
  }

  void move(double width) {
    x += speed;
    if (x > width + 100) {
      // 화면을 완전히 벗어나면 리셋
      reset();
      x = -100; // 왼쪽에서 다시 시작
    }
  }
}

class CloudPainter extends CustomPainter {
  final List<Cloud> clouds;
  final double animation;

  CloudPainter(this.clouds, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (var cloud in clouds) {
      cloud.move(size.width);

      final paint = Paint()
        ..color = Colors.white.withOpacity(cloud.opacity)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(cloud.x, cloud.y);
      path.addOval(Rect.fromCircle(center: Offset(cloud.x, cloud.y), radius: cloud.size * 0.5));
      path.addOval(Rect.fromCircle(center: Offset(cloud.x + cloud.size * 0.4, cloud.y), radius: cloud.size * 0.3));
      path.addOval(Rect.fromCircle(center: Offset(cloud.x - cloud.size * 0.4, cloud.y + cloud.size * 0.1), radius: cloud.size * 0.4));
      path.addOval(Rect.fromCircle(center: Offset(cloud.x + cloud.size * 0.4, cloud.y + cloud.size * 0.1), radius: cloud.size * 0.25));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CloudyAnimation extends StatefulWidget {
  final ValueNotifier<bool> isVisibleNotifier;

  const CloudyAnimation({super.key, required this.isVisibleNotifier});

  @override
  _CloudyAnimationState createState() => _CloudyAnimationState();
}

class _CloudyAnimationState extends State<CloudyAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<Cloud> clouds = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10), // 느린 애니메이션
      vsync: this,
    )..repeat();

    for (int i = 0; i < 10; i++) {
      // 5개의 구름 생성
      clouds.add(Cloud());
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
                    painter: CloudPainter(clouds, _controller.value),
                    size: Size.infinite,
                  );
                },
              )
            : Container();
      },
    );
  }
}
