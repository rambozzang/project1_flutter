// widgets/rain_animation.dart
import 'package:flutter/material.dart';
import 'package:project1/app/test/rain/RainDrop.dart';
import 'package:project1/app/test/rain/RainPainter.dart';

class RainAnimation2 extends StatefulWidget {
  final ValueNotifier<bool> isVisibleNotifier;

  const RainAnimation2({super.key, required this.isVisibleNotifier});

  @override
  _RainAnimationState createState() => _RainAnimationState();
}

class _RainAnimationState extends State<RainAnimation2> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<RainDrop> rainDrops = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    for (int i = 0; i < 100; i++) {
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
                    child: child,
                  );
                },
              )
            : Container();
      },
    );
  }
}
