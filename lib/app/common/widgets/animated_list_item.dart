import 'package:flutter/material.dart';

class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration staggerDelay;
  final double beginOffset;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.beginOffset = 20,
  });

  @override
  Widget build(BuildContext context) {
    final delayMs = index * staggerDelay.inMilliseconds;
    final totalMs = duration.inMilliseconds + delayMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: totalMs),
      curve: Curves.linear,
      builder: (context, value, cachedChild) {
        final rawLocal = delayMs == 0
            ? value
            : ((value - delayMs / totalMs) /
                    (duration.inMilliseconds / totalMs))
                .clamp(0.0, 1.0);
        final localValue = Curves.easeOutCubic.transform(rawLocal);

        return Opacity(
          opacity: localValue,
          child: Transform.translate(
            offset: Offset(0, beginOffset * (1 - localValue)),
            child: cachedChild,
          ),
        );
      },
      child: child,
    );
  }
}
