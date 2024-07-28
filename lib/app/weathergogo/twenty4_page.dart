import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weathergogo/cntr/data/hourly_weather_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Twenty4Page extends StatelessWidget {
  const Twenty4Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF262B49)),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildHourlyWeatherWidget(),
          ),
          const SizedBox(height: 10.0),
          _buildScrollHint(),
          _buildWeatherChart(context),
          const Gap(14),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
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
    return const Align(
      alignment: Alignment.bottomRight,
      child: Text(
        "좌우 드래그만 가능합니다.",
        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget _buildHourlyWeatherWidget() {
    return GetBuilder<WeatherGogoCntr>(
      builder: (cntr) {
        if (cntr.hourlyWeather.isEmpty) {
          return Center(child: Utils.progressbar(size: 5));
        }
        return SizedBox(
          height: 200.0,
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: cntr.hourlyWeather.length,
            itemBuilder: (context, index) => _buildHourlyWeatherItem(cntr, index),
          ),
        );
      },
    );
  }

  Widget _buildHourlyWeatherItem(WeatherGogoCntr cntr, int index) {
    final data = cntr.hourlyWeather[index];
    final yesterdayData = cntr.yesterdayHourlyWeather.firstWhere(
      (element) => element.date.hour == data.date.hour,
      orElse: () => HourlyWeatherData(temp: 0, sky: '', rain: '', date: DateTime.now()),
    );

    final tempDiff = data.temp - yesterdayData.temp;
    final yesterDayDesc = _getYesterdayDescription(tempDiff);

    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      margin: const EdgeInsets.only(left: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            index == 0 ? 'Now' : DateFormat('a hh:mm ', 'ko').format(data.date),
            style: mediumText,
          ),
          const SizedBox(height: 10.0),
          SizedBox(
            height: 60.0,
            width: 60.0,
            child: Lottie.asset(
              WeatherDataProcessor.instance.getFinalWeatherIcon(data.sky.toString(), data.rain.toString()),
              fit: BoxFit.cover,
            ),
          ),
          Text('${data.temp.toStringAsFixed(1)}°', style: semiboldText),
          if (yesterDayDesc.isNotEmpty) _buildYesterdayComparisonRow(tempDiff, yesterDayDesc),
          const SizedBox(height: 4.0),
          FittedBox(
            child: Text(
              WeatherDataProcessor.instance.combineWeatherCondition(data.sky.toString(), data.rain.toString()),
              style: const TextStyle(fontSize: 12.0, color: Colors.white, fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYesterdayComparisonRow(double tempDiff, String yesterDayDesc) {
    final isWarmer = tempDiff > 0;
    return Row(
      children: [
        Text(
          yesterDayDesc,
          style: TextStyle(
            fontSize: 12,
            color: isWarmer ? Colors.amber : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (tempDiff != 0)
          Icon(
            isWarmer ? Icons.arrow_upward : Icons.arrow_downward,
            size: 13,
            color: isWarmer ? Colors.amber : Colors.green,
          ),
      ],
    );
  }

  String _getYesterdayDescription(double tempDiff) {
    if (tempDiff == 0) return '어제와 동일';
    final formattedDiff = tempDiff.abs().toStringAsFixed(1);
    return tempDiff > 0 ? '어제보다 $formattedDiff°' : '어제보다 -$formattedDiff°';
  }

  Widget _buildWeatherChart(context) {
    return GetBuilder<WeatherGogoCntr>(
      builder: (cntr) {
        if (cntr.hourlyWeather.isEmpty) {
          return const SizedBox(height: 1);
        }
        final todayMinMax = _getMinMaxTemperature(cntr.hourlyWeather);
        final yesterdayMinMax = cntr.yesterdayHourlyWeather.isNotEmpty
            ? _getMinMaxTemperature(cntr.yesterdayHourlyWeather)
            : const MinMax(min: double.infinity, max: double.negativeInfinity);

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            // 수직 드래그를 감지하여 ListView로 전달
            if (details.delta.dy != 0) {
              Scrollable.of(context).position.jumpTo(
                    Scrollable.of(context).position.pixels - details.delta.dy,
                  );
            }
          },
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              textStyle: TextStyle(fontSize: 13, color: Colors.white),
            ),
            palette: const <Color>[Colors.red, Colors.blue],
            primaryXAxis: _buildCategoryAxis(),
            primaryYAxis: _buildNumericAxis(todayMinMax, yesterdayMinMax),
            zoomPanBehavior: ZoomPanBehavior(
              enablePanning: true,
              enablePinching: true,
              enableSelectionZooming: true,
              enableMouseWheelZooming: true,
              zoomMode: ZoomMode.x,
            ),
            series: _buildLineSeries(cntr),
          ),
        );
      },
    );
  }

  CategoryAxis _buildCategoryAxis() {
    return CategoryAxis(
      name: 'C',
      labelStyle: const TextStyle(fontSize: 13, color: Colors.white),
      maximumLabels: 50,
      autoScrollingDelta: 7,
      placeLabelsNearAxisLine: true,
      autoScrollingMode: AutoScrollingMode.start,
      majorGridLines: MajorGridLines(width: 0.3, color: Colors.grey.withOpacity(0.3)),
      majorTickLines: const MajorTickLines(width: 0),
    );
  }

  NumericAxis _buildNumericAxis(MinMax todayMinMax, MinMax yesterdayMinMax) {
    final min = (todayMinMax.min < yesterdayMinMax.min ? todayMinMax.min : yesterdayMinMax.min) - 6;
    final max = (todayMinMax.max > yesterdayMinMax.max ? todayMinMax.max : yesterdayMinMax.max) + 6;
    return NumericAxis(
      maximumLabels: 7,
      labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
      minimum: min,
      maximum: max,
      majorGridLines: const MajorGridLines(width: 0),
    );
  }

  List<LineSeries<HourlyWeatherData, String>> _buildLineSeries(WeatherGogoCntr cntr) {
    final series = <LineSeries<HourlyWeatherData, String>>[
      _buildTodayLineSeries(cntr.hourlyWeather),
    ];
    if (cntr.yesterdayHourlyWeather.isNotEmpty) {
      series.add(_buildYesterdayLineSeries(cntr.yesterdayHourlyWeather));
    }
    return series;
  }

  LineSeries<HourlyWeatherData, String> _buildTodayLineSeries(List<HourlyWeatherData> data) {
    return LineSeries<HourlyWeatherData, String>(
      key: const ValueKey('TODAY'),
      name: '오늘',
      dataSource: data,
      xValueMapper: (HourlyWeatherData weather, _) => '${weather.date.hour}시',
      yValueMapper: (HourlyWeatherData weather, _) => weather.temp,
      dataLabelSettings: DataLabelSettings(
        isVisible: true,
        labelIntersectAction: LabelIntersectAction.none,
        overflowMode: OverflowMode.hide,
        labelPosition: ChartDataLabelPosition.outside,
        labelAlignment: ChartDataLabelAlignment.top,
        connectorLineSettings: const ConnectorLineSettings(
          type: ConnectorType.curve,
          color: Colors.red,
          width: 2,
        ),
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
          return SizedBox(
            height: 65,
            width: 40,
            child: Column(
              children: [
                Lottie.asset(
                  WeatherDataProcessor.instance.getWeatherGogoImage(data.sky, data.rain),
                  fit: BoxFit.cover,
                ),
                Text('${data.temp.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          );
        },
      ),
      width: 4.5,
      color: Colors.blue,
      markerSettings: const MarkerSettings(isVisible: true),
    );
  }

  LineSeries<HourlyWeatherData, String> _buildYesterdayLineSeries(List<HourlyWeatherData> data) {
    return LineSeries<HourlyWeatherData, String>(
      key: const ValueKey('yesterday'),
      name: '어제',
      dataSource: data,
      xValueMapper: (HourlyWeatherData weather, _) => '${weather.date.hour}시',
      yValueMapper: (HourlyWeatherData weather, _) => weather.temp,
      dataLabelSettings: DataLabelSettings(
        isVisible: true,
        builder: (dynamic weather, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
          return SizedBox(
            height: 20,
            width: 30,
            child: Text(
              '${weather.temp.toStringAsFixed(1)}°',
              style: TextStyle(fontSize: 12, color: Colors.amber),
            ),
          );
        },
      ),
      width: 2,
      color: Colors.amber,
      markerSettings: const MarkerSettings(isVisible: true),
    );
  }

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
