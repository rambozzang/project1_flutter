import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weather/widgets/dust_bar_gauge.dart';
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
    // 리프레시·관심지역·현재위치 클릭 등으로 새 온도가 들어오면 이전 값에서
    // 새 값으로 숫자가 카운트되며 올라가는 효과(첫 표시는 0부터 카운트업).
    final double target = double.tryParse(temp) ?? 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 56,
              height: 1,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              // 카운트 중 자릿수 폭이 흔들리지 않게 고정폭 숫자 사용.
              fontFeatures: [FontFeature.tabularFigures()],
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
      if (mist == null || (mist.mist10Grade == null && mist.mist25Grade == null)) {
        return const SizedBox.shrink();
      }
      // 캡슐/배경 없이 하늘 위에 바로 얹는 가로 바 게이지 — 앱의 가벼운 톤 유지.
      // 가독성은 위젯 내부의 텍스트 섀도우·바 그림자가 담당한다.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DustBarGauge(
            label: '미세',
            value: mist.mist10,
            grade: mist.mist10Grade,
            max: 150,
          ),
          const Gap(18),
          DustBarGauge(
            label: '초미세',
            value: mist.mist25,
            grade: mist.mist25Grade,
            max: 75,
          ),
        ],
      );
    });
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
