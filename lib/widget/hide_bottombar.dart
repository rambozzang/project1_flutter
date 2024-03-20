import 'dart:io';

import 'package:flutter/material.dart';

import 'package:project1/app/root/cntr/root_cntr.dart';

class HideBottomBar extends StatefulWidget {
  final Widget children;
  const HideBottomBar({super.key, required this.children});

  @override
  State<HideBottomBar> createState() => _HideBottomBarState();
}

class _HideBottomBarState extends State<HideBottomBar> {
  double andHeight = 60;
  double iosHeight = 84;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: RootCntr.to.bottomBarStreamController.stream,
      initialData: true,
      builder: (context, snapshot) {
        return AnimatedContainer(
          curve: Curves.ease,
          duration: const Duration(milliseconds: 125),
          height: snapshot.data == true
              ? Platform.isAndroid
                  ? andHeight
                  : iosHeight
              : 0.0,
          child: Wrap(children: [widget.children]),
        );
      },
    );
  }
}
