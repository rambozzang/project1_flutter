import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weatherCom/models/weather_data.dart';
import 'package:project1/app/weatherCom/weather_com_page.dart';
import 'package:project1/app/weathergogo/cntr/data/hourly_weather_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/utils.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

class Twenty4Page extends StatefulWidget {
  const Twenty4Page({super.key});

  @override
  State<Twenty4Page> createState() => _Twenty4PageState();
}

class _Twenty4PageState extends State<Twenty4Page> {
  // 크기 관련 상수 정의
  final double hourlyItemWidth = 62.0;

  final double hourlyItemHeight = 320.0;
  // final double hourlyItemHeight = 280.0;

  final double weatherIconSize = 40.0;

  final double chartHeight = 135.0;

  final double chartTopPadding = 178.0;

  final double circleRadius = 4.0;

  final controller = Get.find<WeatherGogoCntr>();

  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration: const BoxDecoration(color: Color(0xFF262B49)),
      // padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Stack(
              children: [
                _buildHourlyWeatherWidget(),
                Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () {},
                    )),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          _buildScrollHint(),
          const SizedBox(height: 15.0),
          // _buildWeatherChart(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIconsRegular.clock, size: 24, color: Colors.white),
          SizedBox(width: 4.0),
          Text('24시 예보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildScrollHint() {
    return Align(
      alignment: Alignment.topCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 5,
            decoration: BoxDecoration(
              color: getColorForSource('Today'),
            ),
          ),
          const Gap(5),
          const Text(
            "오늘",
            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w400),
          ),
          const Gap(10),
          Container(
            width: 20,
            height: 5,
            decoration: BoxDecoration(
              color: getColorForSource('Yesterday'),
            ),
          ),
          const Gap(5),
          const Text(
            "어제",
            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyWeatherWidget() {
    return Obx(
      () {
        if (controller.hourlyWeather.isEmpty) return SizedBox(height: hourlyItemHeight, child: Utils.progressbar());
        return SizedBox(
          height: hourlyItemHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: Get.find<WeatherGogoCntr>().hourlyWeather.length * hourlyItemWidth,
              child: Stack(
                children: [
                  _buildHourlyWeatherItems(),
                  Positioned(
                    top: chartTopPadding,
                    left: 0,
                    right: 0,
                    child: _buildContinuousChart(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinuousChart() {
    return Obx(() {
      if (controller.hourlyWeather.isEmpty && controller.yesterdayHourlyWeather.isEmpty) return const SizedBox.shrink();
      return SizedBox(
        height: chartHeight,
        child: CustomPaint(
          size: Size(controller.hourlyWeather.length * hourlyItemWidth, chartHeight),
          painter: ChartPainterHour({
            'Yesterday': Get.find<WeatherGogoCntr>().yesterdayHourlyWeather.isNotEmpty
                ? Get.find<WeatherGogoCntr>()
                    .yesterdayHourlyWeather
                    .map((e) => WeatherData(
                          time: e.date,
                          humidity: 0,
                          temperature: e.temp,
                          rainProbability: double.parse((e.rainPo ?? 0.0).toString()), // 실제 데이터로 대체 필요
                          source: 'Yesterday',
                        ))
                    .toList()
                : [],
            'Today': Get.find<WeatherGogoCntr>().hourlyWeather.isNotEmpty
                ? Get.find<WeatherGogoCntr>()
                    .hourlyWeather
                    .map((e) => WeatherData(
                          time: e.date,
                          temperature: e.temp,
                          humidity: 0,
                          rainProbability: double.parse((e.rainPo ?? 0.0).toString()), // 실제 데이터로 대체 필요
                          source: 'Today',
                        ))
                    .toList()
                : [],
          }, hourlyItemWidth, chartHeight, chartHeight, circleRadius),
        ),
      );
    });
  }

  Widget _buildHourlyWeatherItems() {
    return Obx(() => Row(
          children: List.generate(
            controller.hourlyWeather.length,
            (index) => _buildHourlyWeatherItem(controller.hourlyWeather[index], index),
          ),
        ));
  }

  Widget _buildHourlyWeatherItem(HourlyWeatherData data, int index) {
    final yesterdayData = controller.yesterdayHourlyWeather.firstWhere(
      (element) => element.date.hour == data.date.hour && element.date.day == (data.date.subtract(const Duration(days: 1))).day,
      orElse: () => HourlyWeatherData(temp: 99.0, sky: '', rain: '', date: DateTime.now()),
    );

    final tempDiff = data.temp - (yesterdayData.temp == 99.0 ? data.temp : yesterdayData.temp);
    var yesterDayDesc = _getYesterdayDescription(tempDiff);
    yesterDayDesc = yesterdayData.temp == 99.0 ? '-' : yesterDayDesc;

    return Column(
      children: [
        data.date.hour == 0 || index == 0
            ? SizedBox(
                height: 23,
                child: Text('${intl.DateFormat('dd', 'ko').format(data.date)}(${intl.DateFormat('EE', 'ko').format(data.date)})',
                    style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
              )
            : const SizedBox(height: 23),
        Container(
          width: hourlyItemWidth,
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
          decoration: BoxDecoration(
            // color: index % 2 == 0 ? const Color.fromARGB(255, 31, 46, 75) : Colors.transparent,
            color: index % 2 == 0 ? Colors.blue.withOpacity(0.15) : Colors.transparent,
            border: data.date.hour == 0 ? Border(left: BorderSide(color: Colors.white.withOpacity(0.5))) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                intl.DateFormat('H', 'ko').format(data.date), // '${intl.DateFormat('a h', 'ko').format(data.date)}시',
                style: const TextStyle(fontSize: 14.0, color: Colors.white, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5.0),
              SizedBox(
                height: weatherIconSize,
                width: weatherIconSize,
                child: Lottie.asset(
                  WeatherDataProcessor.instance.getFinalWeatherIcon(data.date.hour, data.sky.toString(), data.rain.toString()),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 4.0),

              FittedBox(
                child: Text(
                  WeatherDataProcessor.instance.combineWeatherCondition(data.sky.toString(), data.rain.toString()),
                  overflow: TextOverflow.clip,
                  style: const TextStyle(fontSize: 13.0, color: Colors.white, fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: 4.0),

              FittedBox(
                child: data.rainPo == '99.99'
                    ? const Text(
                        '-',
                        overflow: TextOverflow.clip,
                        style: TextStyle(fontSize: 13.0, color: Color.fromARGB(255, 204, 226, 240), fontWeight: FontWeight.w400),
                      )
                    : Row(
                        children: [
                          const Icon(CupertinoIcons.umbrella_fill, size: 12, color: Color.fromARGB(255, 204, 226, 240)),
                          const SizedBox(width: 2.0),
                          Text(
                            '${data.rainPo}%',
                            overflow: TextOverflow.clip,
                            style: const TextStyle(fontSize: 13.0, color: Color.fromARGB(255, 204, 226, 240), fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 4.0),

              _buildYesterdayComparisonRow(tempDiff, yesterDayDesc),
              const SizedBox(height: 4.0),
              SizedBox(height: chartHeight + 5), // 차트를 위한 공간
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYesterdayComparisonRow(double tempDiff, String yesterDayDesc) {
    final isWarmer = tempDiff > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          yesterDayDesc,
          style: TextStyle(
            fontSize: 13,
            color: yesterDayDesc == '-'
                ? Colors.white
                : isWarmer
                    ? Colors.amber
                    : const Color.fromARGB(255, 22, 220, 29),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (tempDiff != 0 && yesterDayDesc != '-')
          Icon(
            isWarmer ? Icons.arrow_upward : Icons.arrow_downward,
            size: 13,
            color: isWarmer ? Colors.amber : Colors.green,
          ),
      ],
    );
  }

  String _getYesterdayDescription(double tempDiff) {
    if (tempDiff == 0) return '-';
    final formattedDiff = tempDiff.abs().toStringAsFixed(1);
    return tempDiff > 0 ? '$formattedDiff°' : '-$formattedDiff°';
  }

  // Widget _buildWeatherChart(context) {
  MinMax _getMinMaxTemperature(List<HourlyWeatherData> data) {
    final temperatures = data.map((e) => e.temp).toList();
    return MinMax(
      min: temperatures.reduce((a, b) => a < b ? a : b),
      max: temperatures.reduce((a, b) => a > b ? a : b),
    );
  }
}

class MinMax {
  final double min;
  final double max;
  const MinMax({required this.min, required this.max});
}

class ChartPainterHour extends CustomPainter {
  final Map<String, List<WeatherData>> weatherData;
  final double cellWidth;
  final double cellHeight;
  final double chartHeight;
  final double circleRadius;

  ChartPainterHour(this.weatherData, this.cellWidth, this.cellHeight, this.chartHeight, this.circleRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final double chartTopPadding = cellHeight * 0.15;
    final double chartBottomPadding = cellHeight * 0.15;

    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;

    for (var dataList in weatherData.values) {
      for (var data in dataList) {
        if (data.temperature.isFinite) {
          if (data.temperature < minTemp) minTemp = data.temperature;
          if (data.temperature > maxTemp) maxTemp = data.temperature;
        }
      }
    }

    // 온도 범위가 유효한지 확인
    if (!minTemp.isFinite || !maxTemp.isFinite || minTemp == maxTemp) {
      print('Invalid temperature range: $minTemp - $maxTemp');
      return; // 유효하지 않은 경우 그리기 중단
    }

    // 온도 범위를 더 넓게 만듭니다.
    final tempRange = maxTemp - minTemp;
    minTemp -= tempRange * 0.01;
    maxTemp += tempRange * 0.01;

    weatherData.forEach((source, dataList) {
      final paint = Paint()
        ..color = getColorForSource(source)
        ..strokeWidth = source == 'Today' ? 5 : 2
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool isFirstPoint = true;

      for (int i = 0; i < dataList.length; i++) {
        final data = dataList[i];
        if (!data.temperature.isFinite) continue;

        final double x = i * cellWidth + cellWidth / 2;
        final double normalizedTemp = (data.temperature - minTemp) / (maxTemp - minTemp);
        final double y = chartTopPadding + (1 - normalizedTemp) * (chartHeight - chartTopPadding - chartBottomPadding);

        if (isFirstPoint) {
          path.moveTo(x, y);
          isFirstPoint = false;
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);

      for (int i = 0; i < dataList.length; i++) {
        final data = dataList[i];
        if (!data.temperature.isFinite) continue;

        final double x = i * cellWidth + cellWidth / 2;
        final double normalizedTemp = (data.temperature - minTemp) / (maxTemp - minTemp);
        final double y = chartTopPadding + (1 - normalizedTemp) * (chartHeight - chartTopPadding - chartBottomPadding);

        canvas.drawCircle(
          Offset(x, y),
          source == 'Today' ? circleRadius : circleRadius - 1,
          Paint()..color = Colors.white,
        );

        final textSpan = TextSpan(
          text: '${data.temperature.toStringAsFixed(1)}°',
          style: TextStyle(
            color: data.source == 'Today' ? Colors.black : Colors.white,
            fontSize: data.source == 'Today' ? 13 : 12,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        double textX = x - textPainter.width / 2;
        double textY = y + (data.source == 'Today' ? -30 : 10);

        if (textY + textPainter.height > size.height) {
          textY = y - textPainter.height - (data.source == 'Today' ? -30 : 10);
        }

        final bgRect = Rect.fromLTWH(textX - 2, textY - 2, textPainter.width + 4, textPainter.height + 4);
        canvas.drawRect(bgRect, Paint()..color = data.source == 'Today' ? Colors.white.withOpacity(0.85) : Colors.transparent);

        textPainter.paint(canvas, Offset(textX, textY));
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
