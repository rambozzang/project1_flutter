import 'package:flutter/material.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/utils/utils.dart';

// ignore: must_be_immutable
class CustomButton extends StatelessWidget {
  final bool isEnable;
  final bool isProgressing;
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
    this.isEnable = false,
    this.isProgressing = false,
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

  // build 시 공통 토큰을 참조해 핫리로드 뒤에도 이전 색을 보관하지 않는다.
  List<Color> get listDefColors => const [
        SaColorsLight.accentTeal,
        SaColorsLight.accentTeal,
      ];

  @override
  Widget build(BuildContext context) {
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
          color: type != 'XL' ? (!isEnable ? Colors.grey : null) : null,
          shadows: [
            BoxShadow(
              color: SaColorsLight.textPrimary.withValues(alpha: 0.08),
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
          onTap: isEnable && !isProgressing ? onPressed : null,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.transparent),
              //  color: isEnable ? Colors.blue[700] : Colors.grey[300],
              gradient: isEnable
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: listColors ?? listDefColors,
                    )
                  : const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.grey, Color.fromARGB(255, 119, 118, 118)],
                    ),
            ),
            child: Center(
              child: isProgressing
                  ? Utils.progressbar(
                      // 로딩바
                      color: Colors.white,
                      size: 30,
                    )
                  : Row(
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
