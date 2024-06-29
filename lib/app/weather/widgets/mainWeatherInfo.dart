import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';

import 'package:project1/app/weather/helper/extensions.dart';
import 'package:project1/app/weather/helper/utils.dart';
import 'package:project1/app/weather/provider/weatherProvider.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:provider/provider.dart';

import 'customShimmer.dart';

class MainWeatherInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<WeatherCntr>(builder: (weatherProv) {
      if (weatherProv.isLoading.value) {
        return const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: CustomShimmer(
                height: 148.0,
                width: 148.0,
              ),
            ),
            SizedBox(width: 16.0),
            CustomShimmer(
              height: 148.0,
              width: 148.0,
            ),
          ],
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 80.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          child: Text(
                            weatherProv.isCelsius.value
                                ? weatherProv.weather.value!.temp!.toStringAsFixed(1)
                                : weatherProv.weather.value!.temp!.toFahrenheit().toStringAsFixed(1),
                            style: boldText.copyWith(fontSize: 56),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            weatherProv.measurementUnit,
                            style: mediumText.copyWith(fontSize: 26),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    weatherProv.weather.value!.description!.toTitleCase(),
                    style: lightText.copyWith(fontSize: 16),
                  ),
                  //    Text(OpenWheatherRepo().weatherDescKo[weatherProv.weather.]),
                  Obx(() => Get.find<WeatherCntr>().mistViewData.value?.mist10Grade == null
                      ? const SizedBox.shrink()
                      : Text(
                          '미세먼지    : ${Get.find<WeatherCntr>().mistViewData.value?.mist10Grade}\n초미세먼지 : ${Get.find<WeatherCntr>().mistViewData.value?.mist25Grade}',
                          style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 160, 160, 160), fontWeight: FontWeight.w600),
                        )),
                ],
              ),
            ),
            Lottie.asset(
              // 'assets/images/weather/clear-day.json',
              // 'assets/lottie/sun.json',
              getWeatherImage(weatherProv.weather.value!.weatherCategory!),
              height: 138.0,
              width: 138.0,
            ),
            //   SvgPicture.asset('assets/images/weather/clear-day.svg', height: 148.0, width: 148.0, semanticsLabel: 'Acme Logo'),
            // SizedBox(
            //     height: 148.0,
            //     width: 148.0,
            //     // child: Image.asset(
            //     //   getWeatherImage(weatherProv.weather.weatherCategory),
            //     //   fit: BoxFit.cover,
            //     // ),
            //     child: SvgPicture.asset('assets/images/weather/clear-day.svg', height: 148.0,
            //     width: 148.0,semanticsLabel: 'Acme Logo')),
          ],
        ),
      );
    });
  }
}
