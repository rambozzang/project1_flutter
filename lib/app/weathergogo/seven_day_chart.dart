import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weathergogo/cntr/data/daily_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/twenty4_page.dart';
import 'package:project1/utils/utils.dart';

class DailyWeatherChart extends StatefulWidget {
  const DailyWeatherChart({super.key});

  @override
  State<DailyWeatherChart> createState() => _DailyWeatherChartState();
}

class _DailyWeatherChartState extends State<DailyWeatherChart> {
  final double itemWidth = 95.0;

  final double itemHeight = 310.0;

  final double graphHeight = 140.0;

  final cntr = Get.find<WeatherGogoCntr>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20.0),
        _buildHeader(),
        const SizedBox(height: 15.0),
        SizedBox(
          height: itemHeight,
          child: Obx(() {
            final sevenDayWeather = cntr.sevenDayWeather;
            if (sevenDayWeather.isEmpty) {
              return Utils.progressbar();
            }
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sevenDayWeather.length,
              itemBuilder: (context, index) => _buildDailyWeatherItem(index, sevenDayWeather[index], sevenDayWeather),
            );
          }),
        ),
        const SizedBox(height: 25.0),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIconsRegular.calendar, color: Colors.white),
          SizedBox(width: 4.0),
          Text(
            '주간 예보',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildDailyWeatherItem(int index, SevenDayWeather dayWeather, List<SevenDayWeather> weatherData) {
    final minTemp = double.parse(dayWeather.morning.minTemp ?? dayWeather.afternoon.minTemp ?? '0');
    final maxTemp = double.parse(dayWeather.afternoon.maxTemp ?? dayWeather.morning.maxTemp ?? '0');

    return Container(
      width: itemWidth,
      height: itemHeight,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.transparent : Colors.blueGrey.withOpacity(0.15), // const Color.fromARGB(255, 31, 46, 75),
        // color: index % 2 == 0 ? const Color(0xFF0D1B2A) : const Color(0xFF1B263B),
        //border: Border.all(color: Colors.white.withOpacity(0.43)),
        border: Border.symmetric(
          vertical: BorderSide(
            color: Colors.white.withOpacity(0.03),
          ),
        ),
      ),
      child: Column(
        children: [
          Text(intl.DateFormat('dd(E)', 'ko').format(DateTime.parse(dayWeather.fcstDate.toString())),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHalfDayWeather(index, dayWeather.morning, '오전'),
              _buildHalfDayWeather(index, dayWeather.afternoon, '오후'),
            ],
          ),
          SizedBox(
            height: graphHeight,
            child: CustomPaint(
              size: const Size(18, 30),
              painter: TemperatureGraphPainter(
                minTemp: minTemp,
                maxTemp: maxTemp,
                globalMinTemp:
                    weatherData.map((e) => double.parse(e.morning.minTemp ?? e.afternoon.minTemp ?? '0')).reduce((a, b) => a < b ? a : b),
                globalMaxTemp:
                    weatherData.map((e) => double.parse(e.afternoon.maxTemp ?? e.morning.maxTemp ?? '0')).reduce((a, b) => a > b ? a : b),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHalfDayWeather(int index, DayWeatherData data, String period) {
    // 2부터는 중기예보 아이콘으로 변경
    final Widget weathIcon = index > 1
        ? WeatherDataProcessor.instance.getWeatherIconForMidtermForecast(data.skyDesc.toString())
        : WeatherDataProcessor.instance.getWeatherGogoImage(data.sky.toString(), data.rain.toString());

    return Column(
      children: [
        Text(period, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
        SizedBox(height: 40, width: 40, child: weathIcon
            // child: Lottie.asset(
            //   weathIcon,
            //   fit: BoxFit.cover,
            // ),
            ),
        Text('${data.rainPo ?? '0'}%',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 204, 226, 240))),
        const SizedBox(
          height: 6,
        ),
      ],
    );
  }
}

class TemperatureGraphPainter extends CustomPainter {
  final double minTemp;
  final double maxTemp;
  final double globalMinTemp;
  final double globalMaxTemp;

  TemperatureGraphPainter({
    required this.minTemp,
    required this.maxTemp,
    required this.globalMinTemp,
    required this.globalMaxTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barWidth = size.width * 0.6;
    final double centerX = size.width / 2;
    final double totalRange = globalMaxTemp - globalMinTemp;

    // 막대의 시작과 끝 위치 계산
    final double barBottom = size.height * 0.9; // 그래프의 90% 높이에서 시작
    final double barTop = size.height * 0.2; // 그래프의 10% 높이에서 끝

    final double minBarY = barBottom - ((minTemp - globalMinTemp) / totalRange) * (barBottom - barTop);
    final double maxBarY = barBottom - ((maxTemp - globalMinTemp) / totalRange) * (barBottom - barTop);
    // 둥근 모서리의 사각형 정의

    // 둥근 모서리의 사각형 정의
    final rect = Rect.fromLTRB(centerX - barWidth / 2, maxBarY, centerX + barWidth / 2, minBarY);
    final barRRect = RRect.fromRectAndRadius(rect, const Radius.circular(5));

    // 그라데이션 정의
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.mirror,
      colors: [
        Colors.orange,
        Colors.orange,
        Colors.yellow,
      ],
    );

    // 그라데이션으로 막대 채우기
    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(barRRect, fillPaint);

    // 테두리 그리기
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(barRRect, borderPaint);
    // 최저/최고 온도 텍스트
    _drawTemperatureText(canvas, minTemp.toStringAsFixed(1), Offset(centerX, minBarY), Colors.white, true);
    _drawTemperatureText(canvas, maxTemp.toStringAsFixed(1), Offset(centerX, maxBarY), Colors.white, false);
  }

  void _drawTemperatureText(Canvas canvas, String text, Offset position, Color color, bool isMinTemp) {
    final textSpan = TextSpan(
      text: '$text°',
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    if (isMinTemp) {
      // 최저 온도 텍스트를 그래프 아래에 위치시킴
      textPainter.paint(canvas, position.translate(-textPainter.width / 2, textPainter.height / 2));
    } else {
      // 최고 온도 텍스트를 그래프 위에 위치시킴
      textPainter.paint(canvas, position.translate(-textPainter.width / 2, -textPainter.height * 1.5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
