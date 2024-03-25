import 'package:flutter/material.dart';

class Custom2Button extends StatelessWidget {
  final Widget widget;
  final void Function()? onPressed;
  final double? widthValue;
  final double? heightValue;
  final double? circularValue;

  Custom2Button({
    super.key,
    required this.widget,
    required this.onPressed,
    this.widthValue,
    this.heightValue,
    this.circularValue,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: widthValue ?? 65, height: heightValue ?? 40),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.withOpacity(0.5),
          padding: const EdgeInsets.all(1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(circularValue ?? 16.0),
          ),
          elevation: 1.0,
        ),
        onPressed: () {
          if (onPressed != null) {
            onPressed!();
          }
        },
        child: widget,
        // child: Text(
        //   text,
        //   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        // ),
      ),
    );
  }
}
