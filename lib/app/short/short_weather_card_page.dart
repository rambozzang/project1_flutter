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

class ShortWeatherCardPage extends GetView<WeatherGogoCntr> {
  const ShortWeatherCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final temp = controller.currentWeather.value.temp ?? '0.0';
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildWeatherAnimation(controller.currentWeather.value),
          // _buildTemperature(controller.currentWeather.value.temp ?? '0.0'),
          Text(
            temp.contains('.') ? temp : '$temp.0',
            key: ValueKey<String>(temp),
            style: const TextStyle(
              fontSize: 15,
              height: 1,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '°C',
            style: TextStyle(
              fontSize: 8,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Gap(6),
          Text(
            controller.currentWeather.value.description ?? '맑음',
            style: const TextStyle(
              fontSize: 14,
              height: 1,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(5),
          _buildYesterdayInfo(controller.yesterdayDesc.value),
          const Spacer()
        ],
      ),
    );
  }

  Widget _buildYesterdayInfo(String? yesterdayDesc) {
    if (yesterdayDesc == null || yesterdayDesc.isEmpty) return const SizedBox(width: 80);
    return Text(
      yesterdayDesc.replaceAll('낮아요', '↓').replaceAll('높아요', '↑'),
      style: TextStyle(
        height: 1,
        fontSize: 14,
        color: !yesterdayDesc.contains('낮') ? Colors.green : const Color.fromARGB(255, 157, 121, 10),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAirQualityInfo(Rx<MistViewData?> mistViewData) {
    return Obx(() {
      final mist = mistViewData.value;
      if (mist == null) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
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
    return Container(
      height: 38.0,
      width: 38.0,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: WeatherDataProcessor.instance.getFinalWeatherIcon(
        DateTime.now().hour,
        weather.sky?.toString() ?? '',
        weather.rain?.toString() ?? '',
      ),
    );
  }
}
