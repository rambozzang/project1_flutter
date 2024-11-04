import 'package:flutter/material.dart';
import 'dart:math' as math;

class ShimmeringText extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmeringText({
    super.key,
    required this.text,
    this.fontSize = 20.0,
    this.baseColor = Colors.black,
    this.highlightColor = Colors.white,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  _ShimmeringTextState createState() => _ShimmeringTextState();
}

class _ShimmeringTextState extends State<ShimmeringText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    // 투명도 애니메이션
    _opacityAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // 색상 애니메이션
    _colorAnimation = ColorTween(
      begin: widget.baseColor,
      end: widget.highlightColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                _colorAnimation.value!,
                widget.baseColor,
                _colorAnimation.value!,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
