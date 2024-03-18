import 'package:flutter/material.dart';

import 'package:get/get.dart';

// ignore: must_be_immutable
class CustomSecButton extends StatelessWidget {
  final String type;
  final String text;
  final void Function()? onPressed;
  final double? widthValue;
  final double? heightValue;
  final Color? colorValue;

  CustomSecButton(
      {super.key, required this.text, required this.type, required this.onPressed, this.widthValue, this.heightValue, this.colorValue});

  Map<String, double> heightSize = {
    'XL': 56,
    'L': 48,
    'M': 44,
    'S': 41,
    'XS': 34,
    'T': 29,
    'XT': 29,
  };

  Map<String, double> fontSize = {
    'XL': 16,
    'L': 15,
    'M': 14,
    'S': 13,
    'XS': 12,
    'T': 11,
    'XT': 11,
  };

  Map<String, double> widthSize = {
    'XL': double.infinity,
    'L': 164,
    'M': 90,
    'S': 303,
    'XS': 69,
    'T': 61,
    'XT': 50,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final double fontValue = fontSize[type]!;

    return Container(
      padding: type == 'XT' ? EdgeInsets.symmetric(horizontal: 5, vertical: 5) : null,
      height: heightValue ?? heightSize[type]!, // XL 버튼 높이
      width: widthValue ?? widthSize[type]!,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(width: 1, color: Colors.grey),
        ),
      ),
      child: Material(
        color: colorValue ?? Colors.transparent,
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Ink(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
              //  color: C.semanticGrayDevider,
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: fontValue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
