import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weathergogo/cntr/data/current_weather_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/weather/data/weather_view_data.dart';
import 'package:project1/utils/log_utils.dart';

class HeaderMainPage extends GetView<WeatherGogoCntr> {
  const HeaderMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildYesterdayInfo(controller.yesterdayDesc.value),
                  _buildTemperature(controller.currentWeather.value.temp ?? '0.0'),
                  const Gap(5),
                  Text(
                    controller.currentWeather.value.description ?? '맑음',
                    style: lightText.copyWith(fontSize: 16),
                  ),
                  _buildAirQualityInfo(controller.mistData),
                ],
              ),
            ),
            _buildWeatherAnimation(controller.currentWeather.value),
          ],
        ),
      ),
    );
  }

  Widget _buildYesterdayInfo(String? yesterdayDesc) {
    if (yesterdayDesc == null || yesterdayDesc.isEmpty) return const SizedBox(height: 16);
    return SizedBox(
      height: 16,
      child: Text(
        yesterdayDesc,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 15,
          color: yesterdayDesc.contains('낮') ? Colors.green : Colors.amber,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildTemperature(String temp) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            temp.contains('.') ? temp : '$temp.0',
            key: ValueKey<String>(temp),
            style: const TextStyle(
              fontSize: 56,
              height: 1,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Text(
          '°C',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAirQualityInfo(Rx<MistViewData?> mistViewData) {
    return Obx(() {
      final mist = mistViewData.value;
      if (mist == null) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(5),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
              children: [
                const TextSpan(text: '미세 '),
                _buildMistSpan(mist.mist10Grade ?? ''),
                const TextSpan(text: ' 초미세 '),
                _buildMistSpan(mist.mist25Grade ?? ''),
              ],
            ),
          ),
        ],
      );
    });
  }

  TextSpan _buildMistSpan(String mist) {
    final color = _getMistColor(mist);
    return TextSpan(
      text: mist,
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color),
    );
  }

  Color _getMistColor(String mist) {
    switch (mist) {
      case '좋음':
        return Colors.blue;
      case '보통':
        return Colors.green;
      case '나쁨':
        return Colors.orange;
      case '매우나쁨':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildWeatherAnimation(CurrentWeatherData weather) {
    lo.g('weather.sky: ${weather.sky}, weather.rain: ${weather.rain}');

    return SizedBox(
      height: 120.0,
      width: 120.0,
      child: WeatherDataProcessor.instance.getFinalWeatherIcon(
        DateTime.now().hour,
        weather.sky?.toString() ?? '',
        weather.rain?.toString() ?? '',
      ),
    );
  }
}
