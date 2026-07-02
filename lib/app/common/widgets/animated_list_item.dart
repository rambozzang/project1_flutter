import 'package:flutter/material.dart';

class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration staggerDelay;
  final double beginOffset;

  /// stagger 누적 상한(ms). 항목이 많아도 뒤쪽 항목이 과하게 늦게 뜨지 않도록 제한.
  final int maxStaggerMs;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 220),
    this.staggerDelay = const Duration(milliseconds: 28),
    this.beginOffset = 16,
    this.maxStaggerMs = 220,
  });

  @override
  Widget build(BuildContext context) {
    // stagger 지연을 상한으로 캡핑 → 그리드에 항목이 수십 개여도 마지막 항목이
    // 1초 넘게 늦게 뜨던 문제 방지(전체가 금방 채워지고 스냅하게 보임).
    final delayMs = (index * staggerDelay.inMilliseconds).clamp(0, maxStaggerMs);
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
