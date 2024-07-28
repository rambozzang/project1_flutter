import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weathergogo/cntr/data/current_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';

class AppbarPage extends StatelessWidget {
  static const double boxWidth = 52.0;
  static const double boxHeight = 40.0;

  const AppbarPage({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<WeatherGogoCntr>(
      builder: (weatherProv) {
        if (weatherProv.currentLocation.value == null) {
          return const Center(child: SizedBox(height: 1, width: 1));
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weatherProv.currentLocation.value?.name}',
                  style: semiboldText.copyWith(fontSize: 18.0),
                ),
                const SizedBox(height: 4.0),
                Text(
                  DateFormat('y/MM/dd E , a hh:mm ', 'ko').format(DateTime.now()),
                  style: regularText.copyWith(color: Colors.grey.shade200),
                )
              ],
            ),
            const SizedBox(width: 8.0),
          ],
        );
      },
    );
  }
}
