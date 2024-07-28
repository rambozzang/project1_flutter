// 광고
import 'package:flutter/material.dart';
import 'package:project1/admob/banner_ad_widget.dart';

Widget buildAddmob() {
  return Container(
    height: 80,
    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Stack(
      children: [
        const BannerAdWidget(screenName: 'SeachPage'),
        Container(
          color: Colors.red[300],
          child: const Text(
            "배너광고",
            style: TextStyle(color: Colors.white),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            margin: const EdgeInsets.only(right: 10, bottom: 0),
            child: const Text(
              "Nike",
              style: TextStyle(color: Colors.white),
            ),
          ),
        )
      ],
    ),
  );
}
