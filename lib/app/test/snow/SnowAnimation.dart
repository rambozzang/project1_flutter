// widgets/snow_animation.dart
import 'package:flutter/material.dart';
import 'package:project1/app/test/snow/SnowPainter.dart';
import 'package:project1/app/test/snow/Snowflake.dart';

class SnowAnimation2 extends StatefulWidget {
  final ValueNotifier<bool> isVisibleNotifier;

  const SnowAnimation2({super.key, required this.isVisibleNotifier});

  @override
  _SnowAnimationState createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<SnowAnimation2> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<Snowflake> snowflakes = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    // 보일 때만 Ticker 가동(안 보이면 stop → 상시 프레임 생성 방지, 페이지 idle 가능).
    widget.isVisibleNotifier.addListener(_syncVisibility);
    _syncVisibility();

    for (int i = 0; i < 100; i++) {
      snowflakes.add(Snowflake());
    }
  }

  @override
  void dispose() {
    widget.isVisibleNotifier.removeListener(_syncVisibility);
    _controller.dispose();
    super.dispose();
  }

  // 가시성에 따라 Ticker를 켜고 끈다.
  void _syncVisibility() {
    if (widget.isVisibleNotifier.value) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
    }
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
                    painter: SnowPainter(snowflakes, _controller.value),
                    size: Size.infinite,
                  );
                },
              )
            : Container();
      },
    );
  }
}
