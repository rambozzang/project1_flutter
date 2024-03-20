import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/utils/utils.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    // log(AuthCntr.to.custId.value);

    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 65,
          width: 65,
          child: Utils.progressbar(),
        ),
      ),
    );
  }
}
