import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:project1/app/weather/helper/extensions.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/app/weather/widgets/dust_bar_gauge.dart';

class MainWeatherInfo extends StatelessWidget {
  const MainWeatherInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WeatherCntr>(builder: (weatherProv) {
      if (weatherProv.isLoading.value) {
        return const SizedBox(height: 1);
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
                  // 어제보다 정보
                  Text(
                    weatherProv.yesterdayDesc.value,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 15,
                      color: weatherProv.yesterdayDesc.value.contains('낮') ? Colors.green : Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 80.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          child: Text(
                            weatherProv.isCelsius.value
                                ? weatherProv.oneCallCurrentWeather.value!.temp!.toStringAsFixed(1)
                                : weatherProv.oneCallCurrentWeather.value!.temp!.toFahrenheit().toStringAsFixed(1),
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
                    weatherProv.oneCallCurrentWeather.value!.weather![0].description!.toTitleCase(),
                    style: lightText.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final mist = weatherProv.mistViewData.value;
                      if (mist == null ||
                          (mist.mist10Grade == null && mist.mist25Grade == null)) {
                        return const SizedBox.shrink();
                      }
                      return Row(
                        children: [
                          DustBarGauge(
                            label: '미세',
                            value: mist.mist10,
                            grade: mist.mist10Grade,
                            max: 150,
                          ),
                          const SizedBox(width: 12),
                          DustBarGauge(
                            label: '초미세',
                            value: mist.mist25,
                            grade: mist.mist25Grade,
                            max: 75,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // Lottie.asset(
            //   // getWeatherImage(weatherProv.weather.value!.weatherCategory!),
            //   getWeatherImage(weatherProv.oneCallCurrentWeather.value!.weather![0].main!),
            //   height: 138.0,
            //   width: 138.0,
            // ),
          ],
        ),
      );
    });
  }
}
