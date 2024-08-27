import 'dart:math' as math;
import 'package:flutter/material.dart';

class DarkCloud {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;

  DarkCloud(Size screenSize) {
    reset(screenSize);
  }

  void reset(Size screenSize) {
    x = math.Random().nextDouble() * screenSize.width;
    y = math.Random().nextDouble() * screenSize.height;
    size = math.Random().nextDouble() * 100 + 50; // 50-150 사이의 크기
    speed = math.Random().nextDouble() * 0.5 + 0.1; // 0.1-0.6 사이의 속도
    opacity = math.Random().nextDouble() * 0.3 + 0.5; // 0.5-0.8 사이의 투명도
  }

  void move(Size screenSize) {
    x -= speed;
    if (x + size < 0) {
      x = screenSize.width + size;
      y = math.Random().nextDouble() * screenSize.height;
    }
  }
}

class DarkCloudsPainter extends CustomPainter {
  final List<DarkCloud> clouds;
  final double animation;

  DarkCloudsPainter(this.clouds, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그리기
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    for (var cloud in clouds) {
      cloud.move(size);

      final cloudPaint = Paint()
        ..color = Colors.grey[700]!.withOpacity(cloud.opacity)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(cloud.x, cloud.y);
      path.addOval(Rect.fromCircle(center: Offset(cloud.x, cloud.y), radius: cloud.size * 0.5));
      path.addOval(Rect.fromCircle(center: Offset(cloud.x + cloud.size * 0.4, cloud.y), radius: cloud.size * 0.3));
      path.addOval(Rect.fromCircle(center: Offset(cloud.x - cloud.size * 0.4, cloud.y + cloud.size * 0.1), radius: cloud.size * 0.4));
      path.addOval(Rect.fromCircle(center: Offset(cloud.x + cloud.size * 0.4, cloud.y + cloud.size * 0.1), radius: cloud.size * 0.25));

      canvas.drawPath(path, cloudPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DarkCloudsAnimation extends StatefulWidget {
  final ValueNotifier<bool> isVisibleNotifier;

  const DarkCloudsAnimation({Key? key, required this.isVisibleNotifier}) : super(key: key);

  @override
  _DarkCloudsAnimationState createState() => _DarkCloudsAnimationState();
}

class _DarkCloudsAnimationState extends State<DarkCloudsAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<DarkCloud> clouds = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // 화면 크기를 가정합니다. 실제 사용시 MediaQuery를 사용하여 정확한 크기를 얻을 수 있습니다.
    Size assumedScreenSize = const Size(400, 600);
    for (int i = 0; i < 5; i++) {
      clouds.add(DarkCloud(assumedScreenSize));
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
                    painter: DarkCloudsPainter(clouds, _controller.value),
                    size: Size.infinite,
                  );
                },
              )
            : Container();
      },
    );
  }
}
