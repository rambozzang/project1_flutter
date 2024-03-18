import 'package:flutter/material.dart';

import 'package:get/get.dart';

class CustomIconButton extends StatelessWidget {
  final Function()? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  const CustomIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.borderColor,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SizedBox(
      width: width ?? 50,
      height: height ?? 50,
      child: Material(
        color: backgroundColor ?? theme.canvasColor,
        shape: CircleBorder(side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none),
        child: InkWell(
          onTap: onPressed,
          highlightColor: theme.primaryColor.withOpacity(0.2),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          child: icon,
        ),
      ),
    );
  }
}
