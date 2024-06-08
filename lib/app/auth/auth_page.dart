import 'package:flutter/material.dart';
import 'package:project1/widget/play_lottie.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    // log(AuthCntr.to.custId.value);

    return const Scaffold(
      body: Center(
        child: SizedBox(
          height: 65,
          width: 65,
          child: PlayLottie(lottie: 'assets/lottie/loading_weather.json'),
        ),
      ),
    );
  }
}
