import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/log_utils.dart';

class AppbarPage extends StatelessWidget {
  static const double boxWidth = 52.0;
  static const double boxHeight = 40.0;

  const AppbarPage({super.key});
  @override
  Widget build(BuildContext context) {
    // return GetBuilder<WeatherGogoCntr>(
    //   builder: (weatherProv) {
    //     if (weatherProv.currentLocation.value == null) {
    //       return const Center(child: SizedBox(height: 1, width: 1));
    //     }
    return Obx(
      () {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'appbar',
                      child: Text(
                        Get.find<WeatherGogoCntr>().currentLocation.value!.name,
                        style: semiboldText.copyWith(
                          fontSize: 18.0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      DateFormat('y/MM/dd(E) a h:mm ', 'ko').format(DateTime.now()),
                      style: regularText.copyWith(color: Colors.grey.shade200),
                    )
                  ],
                ),
                SizedBox(
                  width: 24,
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    constraints: const BoxConstraints(),
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                      // backgroundColor: WidgetStateProperty.all(Colors.grey[500]),
                    ),
                    icon: const Icon(Icons.my_location, color: Color.fromARGB(255, 196, 211, 196), size: 24.0),
                    onPressed: () => Get.find<WeatherGogoCntr>().getCurrentWeatherData(true),
                  ),
                ),
              ],
            ),
            loadingWidget()
          ],
        );
      },
    );
  }

  Widget loadingWidget() {
    return Obx(() => Get.find<WeatherGogoCntr>().isLoading.value
        ? Container(
            height: 2,
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            width: double.infinity,
            child: const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          )
        : const SizedBox(
            height: 2,
          ));
  }
}
