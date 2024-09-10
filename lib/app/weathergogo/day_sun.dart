import 'package:flutter/material.dart';

class DaySun extends StatefulWidget {
  final ValueNotifier<bool> isVisibleNotifier;
  final double top;
  final double right;

  const DaySun({super.key, required this.isVisibleNotifier, required this.top, required this.right});

  @override
  State<DaySun> createState() => _NightSunState();
}

class _NightSunState extends State<DaySun> {
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
                  'assets/lottie/day_sun.png',
                  width: 200,
                  // height: 300,
                ),
              )
            : Container();
      },
    );
  }
}
