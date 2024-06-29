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
  final List<Color>? listColors;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  CustomButton({
    super.key,
    this.isEnable = true,
    required this.text,
    required this.type,
    required this.onPressed,
    this.widthValue,
    this.heightValue,
    this.listColors,
    this.prefixIcon,
    this.suffixIcon,
  });

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

  List<Color>? listDefColors = [
    //연두색
    // Color.fromARGB(255, 38, 162, 40),
    // Color.fromARGB(255, 34, 112, 26),
    // Color.fromARGB(255, 13, 104, 43),

    // 검은 회색
    // Color(0xFF3A3F65), // 기준 색상보다 약간 더 밝은 색상
    // Color(0xFF1E2238), // 기준 색상보다 약간 더 어두운 색상
    // Color(0xFF414766), // 기준 색상보다 약간 더 채도가 높은 색상

    // 밝은 회색
    // Color(0xFF4A5076), // 기준 색상보다 조금 더 밝은 색상
    // Color(0xFF6A7098), // 기준 색상보다 더 밝은 색상
    // Color(0xFF8A90BA), // 기준 색상보다 훨씬 더 밝은 색상

    // 기준 퍼플
    Color(0xFF483D8B), // 어두운 슬레이트 블루
    Color(0xFF5A4FCF), // 슬레이트 블루
    Color(0xFF7D67E8), // 미디엄 슬레이트 블루

    // 밝은 퍼플
    // Color(0xFF5A4FCF), //- 바이올렛 블루
    // Color(0xFF7D67E8), //- 라벤더 퍼플
    // Color(0xFF9A7FFF), //- 라이트 퍼플
  ];

  // List<Color>? listDefColors2 = [
  // Color.fromARGB(255, 140, 131, 221),
  // Color.fromARGB(255, 140, 131, 221),

  // ];

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
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
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
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.transparent),
              // color: isEnable ? Colors.blue[700] : Colors.grey[300],
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: listColors ?? listDefColors!,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null) prefixIcon!,
                  Text(
                    text,
                    style: TextStyle(
                      color: isEnable ? Colors.white : Colors.grey[300],
                      fontSize: fontValue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (suffixIcon != null) suffixIcon!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
