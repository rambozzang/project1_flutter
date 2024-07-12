// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/helper/extensions.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';

import '../helper/utils.dart';

class MainWeatherDetail extends StatelessWidget {
  const MainWeatherDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WeatherCntr>(builder: (weatherProv) {
      if (weatherProv.isLoading.value ||
          weatherProv.oneCallCurrentWeather.value!.dt == null ||
          weatherProv.additionalWeatherData.value.uvi == null) {
        return const SizedBox(height: 1);
      }
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF262B49), // backgroundBlack,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  DetailInfoTile(
                      icon: const PhosphorIcon(
                        PhosphorIconsRegular.thermometerSimple,
                        color: Colors.white,
                      ),
                      title: '체감 온도',
                      subtitle: '',
                      data: weatherProv.isCelsius.value
                          ? '${weatherProv.oneCallCurrentWeather.value!.feels_like?.toStringAsFixed(1)}°'
                          : '${weatherProv.oneCallCurrentWeather.value!.feels_like?.toFahrenheit().toStringAsFixed(1)}°'),
                  const VerticalDivider(
                    thickness: 1.0,
                    indent: 4.0,
                    endIndent: 4.0,
                    color: backgroundBlue,
                  ),
                  DetailInfoTile(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.drop,
                      color: Colors.white,
                    ),
                    title: '강수량',
                    subtitle: '',
                    data: '${weatherProv.additionalWeatherData.value!.precipitation}mm',
                  ),
                  const VerticalDivider(
                    thickness: 1.0,
                    indent: 4.0,
                    endIndent: 4.0,
                    color: backgroundBlue,
                  ),
                  DetailInfoTile(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.sun,
                      color: Colors.white,
                    ),
                    title: 'UV 지수',
                    subtitle: '',
                    data: uviValueToString(
                      weatherProv.additionalWeatherData.value.uvi!,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              thickness: 1.0,
              color: backgroundBlue,
              indent: 12.0,
              endIndent: 12.0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  DetailInfoTile(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.wind,
                      color: Colors.white,
                    ),
                    title: '바 람',
                    subtitle: weatherProv.yesterdayWeather.isNotEmpty
                        ? '${weatherProv.yesterdayWeather.firstWhere((el) => el.category == 'WSD').obsrValue}m/s'
                        : '',
                    data: '${weatherProv.oneCallCurrentWeather.value!.wind_speed}m/s',
                  ),
                  const VerticalDivider(
                    thickness: 1.0,
                    indent: 4.0,
                    endIndent: 4.0,
                    color: backgroundBlue,
                  ),
                  DetailInfoTile(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.dropHalfBottom,
                      color: Colors.white,
                    ),
                    title: '습 도',
                    subtitle: weatherProv.yesterdayWeather.isNotEmpty
                        ? '${weatherProv.yesterdayWeather.firstWhere((el) => el.category == 'REH').obsrValue}%'
                        : '',
                    data: '${weatherProv.oneCallCurrentWeather.value!.humidity}%',
                  ),
                  const VerticalDivider(
                    thickness: 1.0,
                    indent: 4.0,
                    endIndent: 4.0,
                    color: backgroundBlue,
                  ),
                  DetailInfoTile(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.cloud,
                      color: Colors.white,
                    ),
                    title: '흐 림',
                    subtitle: '',
                    data: '${weatherProv.additionalWeatherData.value!.clouds ?? 0}%',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class DetailInfoTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String data;
  final Widget icon;
  const DetailInfoTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: primaryBlue, child: icon),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(child: Text(title, style: lightText)),
                  FittedBox(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 1.0),
                      child: Text(
                        data,
                        style: mediumText,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  subtitle == ''
                      ? const SizedBox.shrink()
                      : FittedBox(
                          child: Text(subtitle!, style: const TextStyle(color: Colors.amber, fontSize: 12.0)),
                        ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
