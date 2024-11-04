import 'dart:io';

import 'package:flutter/material.dart';

import 'package:project1/root/cntr/root_cntr.dart';

class HideBottomBar extends StatefulWidget {
  final Widget childWdiget;
  const HideBottomBar({super.key, required this.childWdiget});

  @override
  State<HideBottomBar> createState() => _HideBottomBarState();
}

class _HideBottomBarState extends State<HideBottomBar> {
  // double andHeight = 60;
  // double iosHeight = 30;

  // double andHeight = 40;
  // double iosHeight = 44;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: RootCntr.to.bottomBarStreamController.stream,
      initialData: true,
      builder: (context, snapshot) {
        return AnimatedSlide(
            curve: Curves.ease,
            offset: snapshot.data! ? Offset.zero : const Offset(0, 2),
            // color: Colors.transparent,
            duration: const Duration(milliseconds: 125),
            // height: snapshot.data == true
            //     ? Platform.isAndroid
            //         ? andHeight
            //         : iosHeight
            //     : 0.0,
            child: widget.childWdiget
            // child: Wrap(children: [widget.children]),
            );
      },
    );
  }
}
