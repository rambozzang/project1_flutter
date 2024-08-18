// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:lottie/lottie.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:project1/app/weather/helper/extensions.dart';
// import 'package:project1/app/weather/models/hourlyWeather.dart';
// import 'package:project1/app/weather/theme/textStyle.dart';
// import 'package:project1/app/weather/cntr/weather_cntr.dart';
// import 'package:project1/utils/log_utils.dart';
// // import 'package:syncfusion_flutter_charts/charts.dart';

// import '../helper/utils.dart';

// class TwentyFourHourForecast extends StatelessWidget {
//   const TwentyFourHourForecast({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Color(0xFF262B49),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
//             child: Row(
//               children: [
//                 const PhosphorIcon(PhosphorIconsRegular.clock, size: 24, color: Colors.white),
//                 const SizedBox(width: 4.0),
//                 Text(
//                   '24시 예보',
//                   style: semiboldText.copyWith(fontSize: 16),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10.0),
//           GetBuilder<WeatherCntr>(
//             builder: (weatherProv) {
//               if (weatherProv.isLoading.value || weatherProv.hourlyWeather.isEmpty) {
//                 return const SizedBox(
//                   height: 1,
//                 );
//               }
//               lo.g('weatherProv.hourlyWeather.length : ${weatherProv.hourlyWeather.length}');
//               return Container(
//                 height: 200.0,
//                 constraints: const BoxConstraints(
//                   minHeight: 190,
//                 ),
//                 child: ListView.builder(
//                   physics: const ClampingScrollPhysics(),
//                   shrinkWrap: true,
//                   scrollDirection: Axis.horizontal,
//                   itemCount: weatherProv.hourlyWeather.length,
//                   itemBuilder: (context, index) => HourlyWeatherWidget(
//                     index: index,
//                     data: weatherProv.hourlyWeather[index],
//                   ),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(height: 10.0),
//           Align(
//               alignment: Alignment.bottomRight,
//               child: Text("좌우 드래그만 가능합니다.", style: regularText.copyWith(fontSize: 12, color: Colors.white))),
//           GetBuilder<WeatherCntr>(builder: (weatherProv) {
//             if (weatherProv.isLoading.value || weatherProv.hourlyWeather.isEmpty) {
//               return const SizedBox(
//                 height: 1,
//               );
//             }
//             double todayMin =
//                 (weatherProv.hourlyWeather.map((e) => e.temp).reduce((value, element) => value < element ? value : element) - 6)
//                     .floorToDouble();
//             double todayMax =
//                 (weatherProv.hourlyWeather.map((e) => e.temp).reduce((value, element) => value > element ? value : element) + 6)
//                     .floorToDouble();
//             double yesterDayMin = 1000.0;
//             double yesterDayMax = 0.0;
//             if (weatherProv.yesterdayHourlyWeather.isNotEmpty) {
//               yesterDayMin =
//                   (weatherProv.yesterdayHourlyWeather.map((e) => e.temp).reduce((value, element) => value < element ? value : element) - 6)
//                       .floorToDouble();
//               yesterDayMax =
//                   (weatherProv.yesterdayHourlyWeather.map((e) => e.temp).reduce((value, element) => value > element ? value : element) + 6)
//                       .floorToDouble();
//             }

//             return SfCartesianChart(
//               plotAreaBorderWidth: 0,
//               legend: const Legend(
//                 isVisible: true,
//                 position: LegendPosition.bottom,
//                 textStyle: TextStyle(fontSize: 13, color: Colors.white),
//               ),
//               palette: const <Color>[Colors.red, Colors.blue],
//               primaryXAxis: CategoryAxis(
//                 name: 'C',
//                 labelStyle: const TextStyle(fontSize: 13, color: Colors.white),
//                 maximumLabels: 50,
//                 autoScrollingDelta: 7,
//                 placeLabelsNearAxisLine: true,
//                 autoScrollingMode: AutoScrollingMode.start,
//                 majorGridLines: MajorGridLines(width: 0.3, color: Colors.grey.withOpacity(0.3)),
//                 majorTickLines: const MajorTickLines(width: 0),
//               ),
//               primaryYAxis: NumericAxis(
//                   maximumLabels: 7,
//                   labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
//                   minimum: todayMin < yesterDayMin ? todayMin : yesterDayMin,
//                   maximum: todayMax > yesterDayMax ? todayMax : yesterDayMax,
//                   majorGridLines: const MajorGridLines(
//                     width: 0,
//                   )),
//               zoomPanBehavior: ZoomPanBehavior(
//                 enablePanning: true,
//                 enablePinching: true,
//                 enableSelectionZooming: true,
//                 enableMouseWheelZooming: true,
//                 zoomMode: ZoomMode.x,
//               ),
//               series: <LineSeries<HourlyWeather, String>>[
//                 LineSeries<HourlyWeather, String>(
//                   key: const ValueKey('TODAY'),
//                   name: '오늘',
//                   dataSource: <HourlyWeather>[
//                     ...weatherProv.hourlyWeather,
//                   ],
//                   xValueMapper: (HourlyWeather sales, _) => '${sales.date.hour}시',
//                   yValueMapper: (HourlyWeather sales, _) => sales.temp,
//                   dataLabelSettings: DataLabelSettings(
//                     isVisible: true,
//                     labelIntersectAction: LabelIntersectAction.none,
//                     overflowMode: OverflowMode.hide,
//                     labelPosition: ChartDataLabelPosition.outside,
//                     labelAlignment: ChartDataLabelAlignment.top,
//                     connectorLineSettings: const ConnectorLineSettings(
//                       type: ConnectorType.curve,
//                       color: Colors.red,
//                       width: 2,
//                     ),
//                     builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
//                       return SizedBox(
//                         height: 65,
//                         width: 40,
//                         child: Column(
//                           children: [
//                             Lottie.asset(
//                               getWeatherImage(data.weatherCategory),
//                               fit: BoxFit.cover,
//                             ),
//                             Text(data.temp.toStringAsFixed(1) + '°', style: regularText.copyWith(fontSize: 12, color: Colors.white)),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                   width: 4.5,
//                   color: Colors.blue,
//                   markerSettings: const MarkerSettings(isVisible: true),
//                 ),
//                 LineSeries<HourlyWeather, String>(
//                   key: const ValueKey('yesterday'),
//                   name: '어제',
//                   dataSource: <HourlyWeather>[
//                     ...weatherProv.yesterdayHourlyWeather,
//                   ],
//                   xValueMapper: (HourlyWeather weather, _) => '${weather.date.hour}시',
//                   yValueMapper: (HourlyWeather weather, _) => weather.temp,
//                   dataLabelSettings: DataLabelSettings(
//                     isVisible: true,
//                     labelIntersectAction: LabelIntersectAction.none,
//                     overflowMode: OverflowMode.hide,
//                     labelPosition: ChartDataLabelPosition.outside,
//                     labelAlignment: ChartDataLabelAlignment.auto,
//                     connectorLineSettings: const ConnectorLineSettings(
//                       type: ConnectorType.curve,
//                       // color: Colors.red,
//                       width: 1,
//                     ),
//                     builder: (dynamic weather, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
//                       return SizedBox(
//                         height: 20,
//                         width: 30,
//                         child: Text(weather.temp.toStringAsFixed(1) + '°',
//                             style: regularText.copyWith(
//                               fontSize: 12,
//                               color: Colors.amber,
//                             )),
//                       );
//                     },
//                   ),
//                   width: 2,
//                   color: Colors.amber,
//                   markerSettings: const MarkerSettings(isVisible: true),
//                 ),
//               ],
//             );
//           }),
//           const Gap(14),
//         ],
//       ),
//     );
//   }
// }

// class HourlyWeatherWidget extends StatelessWidget {
//   final int index;
//   final HourlyWeather data;
//   const HourlyWeatherWidget({
//     super.key,
//     required this.index,
//     required this.data,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       // height: 130,
//       constraints: const BoxConstraints(
//         minWidth: 90,
//       ),
//       margin: const EdgeInsets.only(left: 10.0),
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.3),
//         // color: index % 2 == 0 ? primaryBlue.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(16.0),
//         border: Border.all(color: Colors.grey.withOpacity(0.2)),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           GetBuilder<WeatherCntr>(builder: (weatherProv) {
//             HourlyWeather hourlyWeather = weatherProv.yesterdayHourlyWeather.firstWhere((element) => element.date.hour == data.date.hour,
//                 orElse: () => HourlyWeather(temp: 0, weatherCategory: '', date: DateTime.now()));

//             String yesterDayDesc = "";
//             double tempDesc = 0.0;
//             if (hourlyWeather.temp != 0) {
//               // 위 2개 값을 비교값
//               tempDesc = data!.temp! - hourlyWeather.temp;
//               // temp 값을 소수점 1자리 음수포함 해서 반올림 해서 변경
//               tempDesc = tempDesc.floorToDouble();
//               yesterDayDesc = data.temp! > hourlyWeather.temp ? '어제보다 $tempDesc°' : '어제보다 $tempDesc°';
//               yesterDayDesc = tempDesc == 0.0 ? '어제와 동일' : yesterDayDesc;
//             }

//             return Column(
//               children: [
//                 Text(
//                   index == 0 ? 'Now' : DateFormat('a hh:mm ', 'ko').format(data.date),
//                   style: mediumText,
//                 ),
//                 const SizedBox(height: 10.0),
//                 SizedBox(
//                   height: 60.0,
//                   width: 60.0,
//                   child: Lottie.asset(
//                     getWeatherImage(data.weatherCategory),
//                     fit: BoxFit.cover,
//                   ),
//                   // child: Image.asset(
//                   //   getWeatherImage(data.weatherCategory),
//                   //   fit: BoxFit.cover,
//                   // ),
//                 ),
//                 Text(
//                   weatherProv.isCelsius.value ? '${data.temp.toStringAsFixed(1)}°' : '${data.temp.toFahrenheit().toStringAsFixed(1)}°',
//                   style: semiboldText,
//                 ),
//                 yesterDayDesc == ""
//                     ? const SizedBox()
//                     : Row(
//                         children: [
//                           Text(
//                             yesterDayDesc,
//                             style: regularText.copyWith(
//                               fontSize: 12,
//                               color: data.temp! > hourlyWeather.temp ? Colors.amber : Colors.green,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           tempDesc == 0.0
//                               ? const SizedBox()
//                               : Icon(
//                                   data.temp! > hourlyWeather.temp ? Icons.arrow_upward : Icons.arrow_downward,
//                                   size: 13,
//                                   color: data.temp! > hourlyWeather.temp ? Colors.amber : Colors.green,
//                                 ),
//                         ],
//                       ),
//               ],
//             );
//           }),
//           const SizedBox(height: 4.0),
//           FittedBox(
//             child: Text(
//               data.condition?.toTitleCase() ?? '',
//               style: regularText.copyWith(fontSize: 12.0),
//             ),
//           ),
//           const SizedBox(height: 4.0),
//         ],
//       ),
//     );
//   }
// }
