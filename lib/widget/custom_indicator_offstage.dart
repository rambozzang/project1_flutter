import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:project1/utils/utils.dart';

class CustomIndicatorOffstage extends StatefulWidget {
  final bool isLoading;
  final Color color;
  final double opacity;
  const CustomIndicatorOffstage({super.key, required this.isLoading, required this.color, required this.opacity});

  @override
  State<CustomIndicatorOffstage> createState() => _CustomIndicatorOffstageState();
}

class _CustomIndicatorOffstageState extends State<CustomIndicatorOffstage> {
  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: widget.isLoading, // isLoading이 false면 감춰~
      child: Stack(children: <Widget>[
        Opacity(
          opacity: widget.opacity,
          child: const ModalBarrier(dismissible: false, color: Colors.black),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Utils.progressbar(),
        ),
      ]),
    );
  }
}
