import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class CustomButton extends StatelessWidget {
  final bool isEnable;
  final String type;
  final String text;
  final void Function()? onPressed;
  final double? widthValue;
  final double? heightValue;

  CustomButton(
      {super.key,
      this.isEnable = true,
      required this.text,
      required this.type,
      required this.onPressed,
      this.widthValue,
      this.heightValue});

  Map<String, double> heightSize = {
    'XL': 56,
    'L': 48,
    'M': 44,
    'S': 41,
    'XS': 34,
    'T': 29,
  };

  Map<String, double> fontSize = {
    'XL': 16,
    'L': 15,
    'M': 14,
    'S': 13,
    'XS': 12,
    'T': 11,
  };

  Map<String, double> widthSize = {
    'XL': double.infinity,
    'L': 164,
    'M': 90,
    'S': 303,
    'XS': 69,
    'T': 61,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final double fontValue = fontSize[type]!;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        // padding: EdgeInsets.symmetric(horizontal: 5.h, vertical: 5.h),
        height: heightValue ?? heightSize[type]!, // XL 버튼 높이
        width: widthValue ?? widthSize[type]!,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: type != 'XL' ? (!isEnable ? Colors.white : null) : null,
          shadows: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: type != 'XL' ? (!isEnable ? const BorderSide(width: 1, color: Colors.grey) : BorderSide.none) : BorderSide.none,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isEnable ? onPressed : null,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.transparent),
              // color: isEnable ? Colors.blue[700] : Colors.grey[300],
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color.fromARGB(255, 38, 162, 40),
                  Color.fromARGB(255, 34, 112, 26),
                  Color.fromARGB(255, 13, 104, 43),
                ],
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isEnable ? Colors.white : Colors.grey[300],
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
