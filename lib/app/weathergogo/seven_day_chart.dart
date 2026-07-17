import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/weathergogo/cntr/data/daily_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/utils/utils.dart';

class DailyWeatherChart extends StatefulWidget {
  const DailyWeatherChart({super.key});

  @override
  State<DailyWeatherChart> createState() => _DailyWeatherChartState();
}

class _DailyWeatherChartState extends State<DailyWeatherChart> {
  final double itemWidth = 95.0;

  final double itemHeight = 330.0;

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
        // 일출·일몰 섹션과의 간격이 다른 구간보다 넓어 하단 여백 축소(25 → 8).
        const SizedBox(height: 8.0),
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
    // 안전한 double 파싱을 위한 헬퍼 함수
    double parseTemp(String? temp) {
      if (temp == null || temp.isEmpty) return 0.0;
      try {
        return double.parse(temp);
      } catch (e) {
        return 0.0;
      }
    }

    final minTemp = parseTemp(dayWeather.morning.minTemp ?? dayWeather.afternoon.minTemp);
    final maxTemp = parseTemp(dayWeather.afternoon.maxTemp ?? dayWeather.morning.maxTemp);

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
                globalMinTemp: weatherData.map((e) => parseTemp(e.morning.minTemp ?? e.afternoon.minTemp)).reduce((a, b) => a < b ? a : b),
                globalMaxTemp: weatherData.map((e) => parseTemp(e.afternoon.maxTemp ?? e.morning.maxTemp)).reduce((a, b) => a > b ? a : b),
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
    // 주간은 하루×2 = 십수 개 아이콘 동시 표시 → optimized(30fps+래스터 캐시)로 애니 유지하며 부하만 낮춘다.
    final Widget weathIcon = index > 1
        ? WeatherDataProcessor.instance.getWeatherIconForMidtermForecast(data.skyDesc.toString(), optimized: true)
        : WeatherDataProcessor.instance.getWeatherGogoImage(data.sky.toString(), data.rain.toString(), optimized: true);

    return Column(
      children: [
        Text(period, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
        SizedBox(height: 40, width: 40, child: RepaintBoundary(child: weathIcon)),
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
  // 데이터(주간 기온) 변경 시 다시 그린다. Obx가 sevenDayWeather 변경 때만 리빌드하므로 안전.
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
