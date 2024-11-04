import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/utils/WeatherLottie.dart';

class AaaaaaPAge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox.expand(
          child: WeatherLottie.background(),
        ),
      ),
    );
  }

  Widget _buildContainer(String text, Color color,
      {Color textColor = Colors.white, Gradient gradient = const LinearGradient(colors: [Colors.transparent, Colors.transparent])}) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Gradient _buildDayGradient() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF87CEEB), Color(0xFFDEB887)],
    );
  }

  Gradient _buildNightGradient() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF191970), Color(0xFF4B0082)],
    );
  }
}
