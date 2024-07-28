import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:project1/app/weatherCom/api/AccuWeatherClient.dart';
import 'package:project1/app/weatherCom/api/KmaClient.dart';
import 'package:project1/app/weatherCom/api/WeatherChannelClient.dart';
import 'package:project1/app/weatherCom/api/WeatherNewsClient.dart';
import 'package:project1/app/weatherCom/cntr/weather_controller.dart';
import 'package:project1/app/weatherCom/models/weather_data.dart';
import 'package:project1/app/weatherCom/services/openweathermap_client.dart';

class WeatherComPage extends StatefulWidget {
  const WeatherComPage({super.key});

  @override
  State<WeatherComPage> createState() => _WeatherComPageState();
}

class _WeatherComPageState extends State<WeatherComPage> {
  @override
  void initState() {
    super.initState();

    // Get.put(WeatherController([
    //   OpenWeatherMapClient(apiKey: 'YOUR_OPENWEATHERMAP_API_KEY'),
    //   AccuWeatherClient(apiKey: 'YOUR_ACCUWEATHER_API_KEY'),
    //   WeatherChannelClient(apiKey: 'YOUR_WEATHERCHANNEL_API_KEY'),
    //   WeatherNewsClient(apiKey: 'YOUR_WEATHERNEWS_API_KEY'),
    //   KmaClient(apiKey: 'YOUR_KMA_API_KEY'),
    // ]));
  }

  @override
  void dispose() {
    super.dispose();
  }

  final List<String> times = ['오늘', '18시', '19시', '20시', '21시', '22시', '23시'];
  final List<Map<String, dynamic>> weatherData = [
    {
      'name': '기상청',
      'temps': [28, 28, 27, 28, 28, 28, 28]
    },
    {
      'name': '아큐웨더',
      'temps': [30, 30, 30, 30, 29, 29, 28]
    },
    {
      'name': '웨더채널',
      'temps': [29, 29, 29, 28, 28, 28, 28]
    },
    {
      'name': '웨더뉴스',
      'temps': [30, 30, 29, 28, 29, 28, 28]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final WeatherController controller = Get.find<WeatherController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Weather Forecast')),
      body: CustomScrollView(
        scrollDirection: Axis.horizontal,
        slivers: [
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              minHeight: 50,
              maxHeight: 50,
              child: Container(
                color: Colors.grey[200],
                child: Column(
                  children: [
                    Center(child: Text('시간')),
                    ...weatherData.map((data) => SizedBox(width: 100, child: Text(data['name']))).toList(),
                  ],
                ),
              ),
            ),
            pinned: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, columnIndex) {
                if (columnIndex == 0) {
                  return SizedBox(
                    width: 100,
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          color: Colors.blue[100],
                          child: Center(child: Text(times[columnIndex])),
                        ),
                        ...weatherData
                            .map((data) => Container(
                                  height: 50,
                                  color: Colors.white,
                                  child: Center(child: Text(data['name'])),
                                ))
                            .toList(),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        color: Colors.blue[100],
                        child: Center(child: Text(times[columnIndex])),
                      ),
                      ...weatherData
                          .map((data) => Container(
                                height: 50,
                                color: Colors.white,
                                child: Center(child: Text('${data['temps'][columnIndex]}°')),
                              ))
                          .toList(),
                    ],
                  ),
                );
              },
              childCount: times.length,
            ),
          ),
        ],
      ),
      // body: Obx(() {
      //   if (controller.isLoading) {
      //     return const Center(child: CircularProgressIndicator());
      //   }

      //   if (controller.forecasts.isEmpty) {
      //     return const Center(child: Text('No forecast data available'));
      //   }

      //   return SingleChildScrollView(
      //     child: Column(
      //       children: [
      //         for (var entry in controller.forecasts.entries) _buildForecastChart(entry.key, entry.value),
      //       ],
      //     ),
      //   );
      // }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () => controller.fetchAllForecasts(),
      ),
    );
  }

  Widget _buildForecastChart(String source, List<WeatherData> forecast) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              source,
            ),
            const SizedBox(height: 16),
            Container(
                child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var item in forecast) _buildForecastChartItem(item),
                ],
              ),
            ))
            // SizedBox(
            //   height: 200,
            //   child: LineChart(
            //     LineChartData(
            //       gridData: const FlGridData(show: true),
            //       titlesData: const FlTitlesData(show: true),
            //       borderData: FlBorderData(show: true),
            //       minX: 0,
            //       maxX: 23,
            //       minY: forecast.map((e) => e.temperature).reduce((a, b) => a < b ? a : b) - 5,
            //       maxY: forecast.map((e) => e.temperature).reduce((a, b) => a > b ? a : b) + 5,
            //       lineBarsData: [
            //         LineChartBarData(
            //           spots: forecast.asMap().entries.map((entry) {
            //             return FlSpot(entry.key.toDouble(), entry.value.temperature);
            //           }).toList(),
            //           isCurved: true,
            //           //  colors: [Colors.blue],
            //           dotData: const FlDotData(show: false),
            //           belowBarData: BarAreaData(show: false),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastChartItem(forecast) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text('${forecast.temperature}°'),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}
