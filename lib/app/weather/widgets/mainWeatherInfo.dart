import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'package:project1/app/weather/helper/extensions.dart';
import 'package:project1/app/weather/helper/utils.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';

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
                    weatherProv.yesterdayDesc.value ?? '',
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
                  Get.find<WeatherCntr>().mistViewData.value?.mist10Grade == null
                      ? const SizedBox.shrink()
                      : RichText(
                          text: TextSpan(
                            text: '미세',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            children: <TextSpan>[
                              buildTextMist(Get.find<WeatherCntr>().mistViewData.value!.mist10Grade.toString()),
                              const TextSpan(
                                text: ' 초미세',
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white),
                              ),
                              buildTextMist(Get.find<WeatherCntr>().mistViewData.value!.mist25Grade.toString()),
                            ],
                          ),
                        ),
                ],
              ),
            ),
            Lottie.asset(
              // getWeatherImage(weatherProv.weather.value!.weatherCategory!),
              getWeatherImage(weatherProv.oneCallCurrentWeather.value!.weather![0].main!),
              height: 138.0,
              width: 138.0,
            ),
          ],
        ),
      );
    });
  }

  TextSpan buildTextMist(String mist) {
    /*
      if (value >= 0 && value <= 30) {
      return '좋음';
    } else if (value >= 31 && value <= 80) {
      return '보통';
    } else if (value >= 81 && value <= 150) {
      return '나쁨';
    } else {
      return '매우나쁨';
    }
    */
    Color color = Colors.blue;
    switch (mist) {
      case '좋음':
        color = Colors.blue;
        break;
      case '보통':
        color = Colors.green;
        break;
      case '나쁨':
        color = Colors.orange;
        break;
      case '매우나쁨':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return TextSpan(
      text: mist,
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color),
    );
  }
}
