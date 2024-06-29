// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/helper/extensions.dart';
import 'package:project1/app/weather/provider/weatherProvider.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weather/widgets/customShimmer.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:provider/provider.dart';

import '../helper/utils.dart';

class MainWeatherDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<WeatherCntr>(builder: (weatherProv) {
      if (weatherProv.isLoading.value) {
        return CustomShimmer(
          height: 132.0,
          borderRadius: BorderRadius.circular(16.0),
        );
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
                      data: weatherProv.isCelsius.value
                          ? '${weatherProv.weather.value!.feelsLike?.toStringAsFixed(1)}°'
                          : '${weatherProv.weather.value!.feelsLike?.toFahrenheit().toStringAsFixed(1)}°'),
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
                    data: '${weatherProv.additionalWeatherData.value!.precipitation}%',
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
                    data: '${weatherProv.weather.value!.windSpeed}m/s',
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
                    data: '${weatherProv.weather.value!.humidity}%',
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
                    data: '${weatherProv.additionalWeatherData.value!.clouds}%',
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
  final String data;
  final Widget icon;
  const DetailInfoTile({
    Key? key,
    required this.title,
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
