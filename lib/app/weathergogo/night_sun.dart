import 'package:flutter/material.dart';

class NightSun extends StatefulWidget {
  final ValueNotifier<bool> isVisibleNotifier;
  final double top;
  final double right;

  const NightSun({super.key, required this.isVisibleNotifier, required this.top, required this.right});

  @override
  State<NightSun> createState() => _NightSunState();
}

class _NightSunState extends State<NightSun> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isVisibleNotifier,
      builder: (context, isVisible, child) {
        return isVisible
            ? Positioned(
                top: widget.top,
                right: widget.right,
                child: Image.asset(
                  'assets/lottie/sun.webp',
                  width: 200,
                  // height: 300,
                ),
              )
            : Container();
      },
    );
  }
}
