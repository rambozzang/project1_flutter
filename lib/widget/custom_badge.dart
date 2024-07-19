import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CustomBadge extends StatelessWidget {
  final String text;
  final int colorNo;
  Color? textColor;
  Color? bgColor;
  void Function()? onPressed;
  double? widthValue;
  double? heightValue;

  CustomBadge(
      {super.key,
      required this.text,
      required this.colorNo,
      this.textColor,
      this.onPressed,
      this.widthValue,
      this.heightValue,
      this.bgColor});

  final Map<int, Map<String, Color>> colorMap = {
    1: {'textColor': const Color(0xFF1A61CD), 'backgroundColor': const Color(0xFFE5E5E5)},
    2: {'textColor': const Color(0xFF2AA100), 'backgroundColor': const Color(0xFFEFFAEA)},
    3: {'textColor': const Color(0xFF4F4745), 'backgroundColor': const Color(0xFFE0D8D4)},
    4: {'textColor': const Color(0xFFE23E28), 'backgroundColor': const Color(0xFFFFE8E4)},
    5: {'textColor': const Color(0xFFffffff), 'backgroundColor': const Color(0xFFFF9900)},
    6: {'textColor': const Color(0xFFFF9900), 'backgroundColor': const Color(0xFF4F4745)},
    7: {'textColor': const Color(0xFFffffff), 'backgroundColor': const Color(0xFF9E9693)},
    8: {'textColor': const Color(0xFF9E9693), 'backgroundColor': const Color(0xFFE0D8D4)},
  };

  @override
  Widget build(BuildContext context) {
    textColor = colorMap[colorNo]?['textColor'] ?? (textColor ?? Colors.white);
    Color backgroundColor = (colorMap[colorNo]?['backgroundColor'] ?? (bgColor ?? Color(0xFFFF9900)));

    return ElevatedButton(
      clipBehavior: Clip.none,
      style: ElevatedButton.styleFrom(
        shadowColor: Colors.transparent,
        // fixedSize: Size(0, 0),
        minimumSize: Size.zero, // Set this
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        backgroundColor: backgroundColor,
      ),
      onPressed: onPressed ?? () {},
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
