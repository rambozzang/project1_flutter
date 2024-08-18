import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weathergogo/24_page.dart';
import 'package:project1/app/weathergogo/cntr/data/daily_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';

class SevenDayPage extends StatefulWidget {
  const SevenDayPage({super.key});

  @override
  State<SevenDayPage> createState() => _SevenDayPageState();
}

class _SevenDayPageState extends State<SevenDayPage> {
  final controller = Get.find<WeatherGogoCntr>();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF262B49),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20.0),
          _buildHeader(),
          const SizedBox(height: 15.0),
          // Stack(
          //   children: [
          //     DailyWeatherChart(weatherData: Get.find<WeatherGogoCntr>().sevenDayWeather),
          //     Positioned(
          //         top: 0,
          //         right: 0,
          //         bottom: 0,
          //         child: IconButton(
          //           icon: const Icon(
          //             Icons.arrow_forward_ios,
          //             color: Colors.white38,
          //             size: 20,
          //           ),
          //           onPressed: () {},
          //         )),
          //   ],
          // ),
          // GetBuilder<WeatherGogoCntr>(
          //   builder: (cntr) {
          //     if (cntr.sevenDayWeather.length < 6) {
          //       return const Center(
          //         child: Padding(
          //             padding: EdgeInsets.all(30),
          //             child: Text(
          //               '데이터 가져오는중..',
          //               style: TextStyle(color: Colors.white, fontSize: 13),
          //             )),
          //       );
          //     }
          Obx(
            () {
              return Column(
                children: [
                  DailyWeatherChart(weatherData: controller.sevenDayWeather),
                  const SizedBox(height: 35.0),
                  // _buildWeatherChart(),
                  _buildWeatherList(controller.sevenDayWeather),
                ],
              );
            },
          ),

          const SizedBox(height: 25.0),
        ],
      ),
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

  // Widget _buildWeatherChart() {
  //   return GetBuilder<WeatherGogoCntr>(
  //     builder: (cntr) {
  //       if (cntr.sevenDayWeather.isEmpty) {
  //         return const SizedBox(height: 1);
  //       }
  //       return SfCartesianChart(
  //         key: UniqueKey(),
  //         backgroundColor: const Color(0xFF262B49),
  //         plotAreaBorderWidth: 0,
  //         enableAxisAnimation: true,
  //         legend: const Legend(isVisible: true, position: LegendPosition.bottom),
  //         primaryXAxis: _buildPrimaryXAxis(),
  //         primaryYAxis: _buildPrimaryYAxis(cntr),
  //         series: <RangeColumnSeries<SevenDayWeather, String>>[
  //           _buildRangeColumnSeries(cntr),
  //         ],
  //       );
  //     },
  //   );
  // }

  // CategoryAxis _buildPrimaryXAxis() {
  //   return const CategoryAxis(
  //     labelStyle: TextStyle(fontSize: 13, color: Colors.white),
  //     maximumLabels: 100,
  //     autoScrollingDelta: 10,
  //     placeLabelsNearAxisLine: false,
  //     autoScrollingMode: AutoScrollingMode.start,
  //     majorGridLines: MajorGridLines(width: 0),
  //     majorTickLines: MajorTickLines(width: 0),
  //   );
  // }

  // NumericAxis _buildPrimaryYAxis(WeatherGogoCntr cntr) {
  //   return NumericAxis(
  //     labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
  //     minimum: (cntr.sevenDayMinTemp.floorToDouble() - 6.0),
  //     maximum: (cntr.sevenDayMaxTemp.floorToDouble() + 10.0),
  //     majorGridLines: const MajorGridLines(width: 0),
  //   );
  // }

  // int tempNum = 0;

  // RangeColumnSeries<SevenDayWeather, String> _buildRangeColumnSeries(WeatherGogoCntr cntr) {
  //   return RangeColumnSeries<SevenDayWeather, String>(
  //     name: '주간 예보 최고/최저온도',
  //     dataLabelSettings: DataLabelSettings(
  //       isVisible: true,
  //       labelIntersectAction: LabelIntersectAction.none,
  //       connectorLineSettings: const ConnectorLineSettings(
  //         type: ConnectorType.curve,
  //         color: Colors.red,
  //         width: 4,
  //       ),
  //       builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) => _buildDataLabel(data, pointIndex),
  //     ),
  //     width: 0.25,
  //     dataSource: [...cntr.sevenDayWeather],
  //     borderRadius: BorderRadius.circular(16),
  //     gradient: const LinearGradient(
  //       colors: [Color.fromARGB(255, 21, 85, 169), Color.fromARGB(255, 44, 162, 246)],
  //     ),
  //     xValueMapper: (SevenDayWeather data, _) =>
  //         '${data.fcstDate!.substring(6)}일\n(${DateFormat('E', 'ko').format(DateTime.parse(data.fcstDate.toString()))})',
  //     lowValueMapper: (SevenDayWeather data, _) => double.parse(data.morning.minTemp!.split('.')[0]),
  //     highValueMapper: (SevenDayWeather data, _) => double.parse(data.afternoon.maxTemp!.split('.')[0]),
  //   );
  // }

  // Widget _buildDataLabel(SevenDayWeather? weather, int pointIndex) {
  //   if (weather == null) return const SizedBox.shrink();

  //   final minTemp = weather.morning.minTemp!.split('.')[0];
  //   final maxTemp = weather.afternoon.maxTemp!.split('.')[0];
  //   // final temp = pointIndex % 2 == 0 ? maxTemp : minTemp;
  //   String? temp = tempNum % 2 == 0 ? maxTemp : minTemp;
  //   temp = temp.toString().split('.')[0];
  //   final ttempNum = tempNum;
  //   tempNum++;

  //   // 2부터는 중기예보 아이콘으로 변경
  //   final weathIcon = pointIndex > 1
  //       ? WeatherDataProcessor.instance.getWeatherIconForMidtermForecast(weather.morning.skyDesc.toString())
  //       : WeatherDataProcessor.instance.getWeatherGogoImage(weather.morning.sky.toString(), weather.morning.rain.toString());

  //   return ttempNum % 2 == 0
  //       ? SizedBox(
  //           height: 65,
  //           width: 40,
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.start,
  //             children: [
  //               Lottie.asset(weathIcon, fit: BoxFit.cover),
  //               Text('$temp°', style: regularText.copyWith(fontSize: 15, color: Colors.white)),
  //             ],
  //           ),
  //         )
  //       : Text('$temp°', style: regularText.copyWith(fontSize: 15, color: Colors.white));
  // }

  Widget _buildWeatherList(RxList<SevenDayWeather> sevenDayWeather) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sevenDayWeather.length,
          itemBuilder: (context, index) => _buildListItem(sevenDayWeather[index], index, context),
        ));
  }

  Widget _buildListItem(SevenDayWeather weather, int index, BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12.0),
      color: index.isEven ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => null, // Get.toNamed('/SevendayDetailPage/'),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[600]!, width: 0.1),
          ),
          margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateColumn(weather),
              _buildWeatherInfo(index, 'AM', weather, context),
              _buildWeatherInfo(index, 'PM', weather, context),
              _buildTemperatureGauge(weather, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateColumn(SevenDayWeather weather) {
    return SizedBox(
      width: 40,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.fill,
        child: Column(
          children: [
            Text(
              DateFormat('MM/dd').format(DateTime.parse(weather.fcstDate.toString())),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
              maxLines: 1,
            ),
            const SizedBox(height: 4.0),
            Text(
              DateFormat('EE', 'ko').format(DateTime.parse(weather.fcstDate.toString())),
              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(int index, String ampm, SevenDayWeather weather, BuildContext context) {
    final weatherInfo = ampm == 'AM' ? weather.morning : weather.afternoon;

    String icon = index > 1
        ? WeatherDataProcessor.instance.getWeatherIconForMidtermForecast(weatherInfo.skyDesc.toString())
        : WeatherDataProcessor.instance.getWeatherGogoImage(weatherInfo.sky.toString(), weatherInfo.rain.toString());

    String desc = index > 1
        ? weatherInfo.skyDesc.toString()
        : WeatherDataProcessor.instance.combineWeatherCondition(weatherInfo.sky.toString(), weatherInfo.rain.toString());

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (index == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(ampm == 'AM' ? '오전' : '오후', style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          const Gap(7),
          SizedBox(height: 36.0, width: 36.0, child: Lottie.asset(icon, fit: BoxFit.cover)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.umbrella_fill, size: 13, color: int.parse(weatherInfo.rainPo ?? '0') >= 50 ? Colors.blue : Colors.white),
              const Gap(3),
              Text('${weatherInfo.rainPo}%',
                  style: TextStyle(
                      color: int.parse(weatherInfo.rainPo ?? '0') >= 50 ? Colors.blue : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Text(desc, overflow: TextOverflow.clip, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTemperatureGauge(SevenDayWeather weather, BuildContext context) {
    String minTemp = weather.morning.minTemp == null ? '-10.0' : weather.morning.minTemp!.split('.')[0];

    String maxTemp = weather.afternoon.maxTemp == null ? '40.0' : weather.afternoon.maxTemp!.split('.')[0];

    return Row(
      children: [
        Text('$minTemp°', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
        const Gap(5),
        Obx(() => SizedBox(
              width: MediaQuery.of(context).size.width * 0.25,
              child: SfLinearGauge(
                minimum: Get.find<WeatherGogoCntr>().sevenDayMinTemp.value - 1.0,
                maximum: Get.find<WeatherGogoCntr>().sevenDayMaxTemp.value + 1.0,
                animateRange: true,
                animateAxis: true,
                showLabels: false,
                showTicks: false,
                showAxisTrack: true,
                majorTickStyle: const LinearTickStyle(length: 0, color: Colors.white),
                ranges: [
                  LinearGaugeRange(
                    startValue: double.parse(minTemp),
                    endValue: double.parse(maxTemp),
                    position: LinearElementPosition.cross,
                    color: Colors.blue,
                    startWidth: 9,
                    endWidth: 9,
                    edgeStyle: LinearEdgeStyle.bothCurve,
                  ),
                ],
              ),
            )),
        const Gap(5),
        Text('$maxTemp°', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
      ],
    );
  }
}
