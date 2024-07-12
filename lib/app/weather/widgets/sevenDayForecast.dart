import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/helper/extensions.dart';
import 'package:project1/app/weather/models/dailyWeather.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:supercharged/supercharged.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../helper/utils.dart';

class SevenDayForecast extends StatelessWidget {
  const SevenDayForecast({super.key});

  @override
  Widget build(BuildContext context) {
    int tempNum = 0;
    return Container(
      color: const Color(0xFF262B49),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const PhosphorIcon(
                  PhosphorIconsRegular.calendar,
                  color: Colors.white,
                ),
                const SizedBox(width: 4.0),
                const Text(
                  '주간 예보',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GetBuilder<WeatherCntr>(
                  builder: (weatherProv) {
                    return TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(0.0),
                        // backgroundColor: primaryBlue,
                      ),
                      onPressed: () => Get.toNamed('/SevendayDetailPage/0'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '자세히 보기',
                            style: semiboldText.copyWith(fontSize: 11.0),
                          ),
                          const Gap(5),
                          const Icon(Icons.arrow_forward_ios, size: 10.0, color: Colors.amber),
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          GetBuilder<WeatherCntr>(builder: (weatherProv) {
            if (weatherProv.isLoading.value || weatherProv.dailyWeather.isEmpty) {
              return const SizedBox(height: 1);
            }
            return SfCartesianChart(
              key: UniqueKey(),
              backgroundColor: const Color(0xFF262B49), // Colors.black87,
              plotAreaBorderWidth: 0,
              enableAxisAnimation: false,
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
              ),
              primaryXAxis: const CategoryAxis(
                // name: '날짜',
                labelStyle: TextStyle(fontSize: 13, color: Colors.white),
                maximumLabels: 100,
                autoScrollingDelta: 10,
                placeLabelsNearAxisLine: false,
                autoScrollingMode: AutoScrollingMode.start,
                majorGridLines: MajorGridLines(width: 0),
                majorTickLines: MajorTickLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                  //  numberFormat: NumberFormat('##########人'),
                  labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
                  minimum: (weatherProv.sevenDayMinTemp.floorToDouble() - 6.0),
                  maximum: (weatherProv.sevenDayMaxTemp.floorToDouble() + 10.0),
                  majorGridLines: const MajorGridLines(width: 0)),
              // zoomPanBehavior: ZoomPanBehavior(
              //   enablePanning: true,
              // ),
              series: <RangeColumnSeries<DailyWeather, String>>[
                RangeColumnSeries<DailyWeather, String>(
                  name: '주간 예보 최고/최저온도',

                  color: Colors.white,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    // labelAlignment: ChartDataLabelAlignment.top,
                    // labelPosition: ChartDataLabelPosition.outside,
                    labelIntersectAction: LabelIntersectAction.none,
                    connectorLineSettings: const ConnectorLineSettings(
                      type: ConnectorType.curve,
                      color: Colors.red,
                      width: 4,
                    ),
                    builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                      final DailyWeather weather = data;

                      final minTemp = weatherProv.isCelsius.value
                          ? weather.tempMin.toStringAsFixed(0)
                          : weather.tempMin.toFahrenheit().toStringAsFixed(0);
                      final maxTemp = weatherProv.isCelsius.value
                          ? weather.tempMax.toStringAsFixed(0)
                          : weather.tempMax.toFahrenheit().toStringAsFixed(0);

                      final temp = tempNum % 2 == 0 ? maxTemp : minTemp;
                      final ttempNum = tempNum;
                      tempNum++;

                      return ttempNum % 2 == 0
                          ? SizedBox(
                              height: 65,
                              width: 40,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Lottie.asset(
                                    getWeatherImage(data.weatherCategory),
                                    fit: BoxFit.cover,
                                  ),
                                  Text('$temp°', style: regularText.copyWith(fontSize: 15, color: Colors.white)),
                                ],
                              ),
                            )
                          : Text('$temp°', style: regularText.copyWith(fontSize: 15, color: Colors.white));
                    },
                  ),
                  width: 0.25,
                  dataSource: [...weatherProv.dailyWeather],
                  // dataSource: _chartData,
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [
                    Color.fromARGB(255, 21, 85, 169),
                    Color.fromARGB(255, 44, 162, 246),
                  ]),
                  xValueMapper: (DailyWeather sales, _) => '${sales.date.day}일\n(${DateFormat('E', 'ko').format(sales.date)})',
                  lowValueMapper: (DailyWeather sales, _) => sales.tempMin.toStringAsFixed(0).toDouble(),
                  highValueMapper: (DailyWeather sales, _) => sales.tempMax.toStringAsFixed(0).toDouble(),
                )
              ],
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GetBuilder<WeatherCntr>(
              builder: (weatherProv) {
                if (weatherProv.isLoading.value) {
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: 7,
                    itemBuilder: (context, index) => const SizedBox(
                      height: 1,
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  controller: ScrollController(),
                  itemCount: weatherProv.dailyWeather.length,
                  itemBuilder: (context, index) {
                    return listDetail(index, weatherProv, context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 25.0),
        ],
      ),
    );
  }

  Widget listDetail(int index, WeatherCntr weatherProv, BuildContext context) {
    final DailyWeather weather = weatherProv.dailyWeather[index];
    // °
    final minTemp = weatherProv.isCelsius.value ? weather.tempMin.toStringAsFixed(0) : weather.tempMin.toFahrenheit().toStringAsFixed(0);
    final maxTemp = weatherProv.isCelsius.value ? weather.tempMax.toStringAsFixed(0) : weather.tempMax.toFahrenheit().toStringAsFixed(0);

    return Material(
      borderRadius: BorderRadius.circular(12.0),
      color: index.isEven ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => Get.toNamed('/SevendayDetailPage/$index'),
        child: Container(
          // height: 82,
          decoration: BoxDecoration(
            //  borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey[600]!, width: 0.1),
          ),
          margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.1,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MM/dd').format(weather.date),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        index == 0 ? '오늘' : DateFormat('EE', 'ko').format(weather.date),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.15,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 36.0,
                      width: 36.0,
                      child: Lottie.asset(
                        getWeatherImage(weather.weatherCategory),
                        fit: BoxFit.cover,
                      ),
                      // child: Image.asset(
                      //   getWeatherImage(weather.weatherCategory),
                      //   fit: BoxFit.cover,
                      // ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(weather.condition,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        )),
                    // Text(weather.weatherCategory, style: const TextStyle(color: Colors.white)),
                    // Text(weather.condition, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '$minTemp°',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  const Gap(5),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.4,
                    child: SfLinearGauge(
                      minimum: weatherProv.sevenDayMinTemp - 1.0,
                      maximum: weatherProv.sevenDayMaxTemp + 1.0,
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
                  ),
                  const Gap(5),
                  Text(
                    '$maxTemp°',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
