import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/helper/extensions.dart';
import 'package:project1/app/weather/models/hourlyWeather.dart';
import 'package:project1/app/weather/provider/weatherProvider.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weather/widgets/customShimmer.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../helper/utils.dart';

class TwentyFourHourForecast extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: backgroundBlack, borderRadius: BorderRadius.circular(16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                const PhosphorIcon(PhosphorIconsRegular.clock, size: 24, color: Colors.white),
                const SizedBox(width: 4.0),
                Text(
                  '24시 예보',
                  style: semiboldText.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          Consumer<WeatherProvider>(
            builder: (context, weatherProv, _) {
              if (weatherProv.isLoading) {
                return const SizedBox(
                  height: 1,
                );
              }
              return Container(
                height: 180.0,
                constraints: const BoxConstraints(
                  minHeight: 140,
                ),
                child: ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: weatherProv.hourlyWeather.length,
                  itemBuilder: (context, index) => HourlyWeatherWidget(
                    index: index,
                    data: weatherProv.hourlyWeather[index],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20.0),
          Consumer<WeatherProvider>(builder: (context, weatherProv, _) {
            if (weatherProv.isLoading) {
              return const CustomShimmer(
                height: 200.0,
                width: double.infinity,
              );
            }
            return SfCartesianChart(
              backgroundColor: Colors.grey.withOpacity(0.3),
              plotAreaBorderWidth: 0,
              enableSideBySideSeriesPlacement: false,
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: TextStyle(fontSize: 13, color: Colors.white),
              ),
              palette: const <Color>[Colors.red, Colors.blue],
              // primaryXAxis: const CategoryAxis(),
              primaryXAxis: CategoryAxis(
                name: '날짜',
                labelStyle: const TextStyle(fontSize: 13, color: Colors.white),
                maximumLabels: 100,
                autoScrollingDelta: 7,
                placeLabelsNearAxisLine: false,
                autoScrollingMode: AutoScrollingMode.start,
                majorGridLines: MajorGridLines(width: 0.3, color: Colors.grey.withOpacity(0.3)),
                majorTickLines: const MajorTickLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                  labelStyle: const TextStyle(fontSize: 13, color: Colors.white),
                  minimum: (weatherProv.hourlyWeather.map((e) => e.temp).reduce((value, element) => value < element ? value : element) - 6)
                      .floorToDouble(),
                  maximum: weatherProv.hourlyWeather.map((e) => e.temp).reduce((value, element) => value > element ? value : element) + 6,
                  majorGridLines: const MajorGridLines(
                    width: 0,
                  )),
              zoomPanBehavior: ZoomPanBehavior(
                enablePanning: true,
                zoomMode: ZoomMode.xy,
              ),
              series: <LineSeries<HourlyWeather, String>>[
                LineSeries<HourlyWeather, String>(
                    name: '최고온도',
                    dataSource: <HourlyWeather>[
                      ...weatherProv.hourlyWeather,
                    ],
                    xValueMapper: (HourlyWeather sales, _) => '${sales.date.hour}시',
                    yValueMapper: (HourlyWeather sales, _) => sales.temp,
                    // dataLabelMapper: (HourlyWeather sales, _) => '${sales.date.hour}시',
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelIntersectAction: LabelIntersectAction.none,
                      overflowMode: OverflowMode.hide,
                      labelPosition: ChartDataLabelPosition.outside,
                      connectorLineSettings: const ConnectorLineSettings(
                        type: ConnectorType.curve,
                        color: Colors.red,
                        width: 2,
                      ),
                      builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                        return SizedBox(
                          height: 60,
                          width: 35,
                          child: Column(
                            children: [
                              Lottie.asset(
                                getWeatherImage(data.weatherCategory),
                                fit: BoxFit.cover,
                              ),
                              Text(data.temp.toStringAsFixed(1) + '°', style: regularText.copyWith(fontSize: 12, color: Colors.white)),
                            ],
                          ),
                        );
                      },
                    ),
                    width: 4,
                    color: Colors.yellow[300],
                    markerSettings: const MarkerSettings(isVisible: true)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class HourlyWeatherWidget extends StatelessWidget {
  final int index;
  final HourlyWeather data;
  const HourlyWeatherWidget({
    Key? key,
    required this.index,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 130,
      constraints: const BoxConstraints(
        minWidth: 90,
      ),
      margin: const EdgeInsets.only(left: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        // color: index % 2 == 0 ? primaryBlue.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 72.0,
            width: 72.0,
            child: Lottie.asset(
              getWeatherImage(data.weatherCategory),
              fit: BoxFit.cover,
            ),
            // child: Image.asset(
            //   getWeatherImage(data.weatherCategory),
            //   fit: BoxFit.cover,
            // ),
          ),
          const SizedBox(height: 2.0),
          Consumer<WeatherProvider>(builder: (context, weatherProv, _) {
            return Text(
              weatherProv.isCelsius ? '${data.temp.toStringAsFixed(1)}°' : '${data.temp.toFahrenheit().toStringAsFixed(1)}°',
              style: semiboldText,
            );
          }),
          const SizedBox(height: 4.0),
          FittedBox(
            child: Text(
              data.condition?.toTitleCase() ?? '',
              style: regularText.copyWith(fontSize: 12.0),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            index == 0 ? 'Now' : DateFormat('hh:mm a').format(data.date),
            style: regularText,
          )
        ],
      ),
    );
  }
}
