// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/utils/log_utils.dart';

import '../helper/utils.dart';
import '../models/dailyWeather.dart';
import '../theme/textStyle.dart';

class SevendayDetailPage extends StatefulWidget {
  const SevendayDetailPage({
    super.key,
    this.initialIndex = 0,
  });

  static const routeName = '/sevenDayForecast';

  final int initialIndex;

  @override
  State<SevendayDetailPage> createState() => _SevendayDetailPageState();
}

class _SevendayDetailPageState extends State<SevendayDetailPage> {
  static const double _horizontalPadding = 12.0;
  static const double _itemWidth = 24.0;
  static const double _selectedWidth = 24.0;

  late final ScrollController _scrollController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.initialIndex;
    _selectedIndex = int.parse(Get.parameters['initialIndex'] ?? '0');

    lo.g('_selectedIndex : $_selectedIndex');
    _scrollController = ScrollController();
    double _position = _selectedIndex * (_itemWidth + 2 * _horizontalPadding) + (_selectedWidth + _horizontalPadding);
    if (_selectedIndex > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _position,
          duration: const Duration(milliseconds: 250),
          curve: Curves.ease,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        forceMaterialTransparency: true,
        // automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
        title: const Text(
          '주간 예보',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: GetBuilder<WeatherCntr>(
        builder: (weatherProv) {
          DailyWeather _selectedWeather = weatherProv.dailyWeather[_selectedIndex];
          //           final minTemp = weatherProv.isCelsius ? weather.tempMin.toStringAsFixed(0) : weather.tempMin.toFahrenheit().toStringAsFixed(0);
          // final maxTemp = weatherProv.isCelsius ? weather.tempMax.toStringAsFixed(0) : weather.tempMax.toFahrenheit().toStringAsFixed(0);

          if (weatherProv.dailyWeather == null || weatherProv.dailyWeather.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            children: [
              const SizedBox(height: 12.0),
              Container(
                height: 130.0,
                color: Colors.black87,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  controller: _scrollController,
                  separatorBuilder: (context, index) => const SizedBox(width: 8.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: weatherProv.dailyWeather.length,
                  itemBuilder: (context, index) {
                    final DailyWeather weather = weatherProv.dailyWeather[index];
                    bool isSelected = index == _selectedIndex;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 74.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          // color: isSelected ? Colors.grey.shade300 : Colors.white,
                          color: isSelected ? Colors.grey.shade900 : Colors.grey.shade800,
                          // color: isSelected ? backgroundBlue : backgroundBlue.withOpacity(.2),
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  DateFormat('MM/dd').format(weather.date),
                                  style: mediumText,
                                  maxLines: 1,
                                ),
                                Text(
                                  index == 0 ? '오늘' : DateFormat('E', 'ko').format(weather.date),
                                  style: mediumText,
                                  maxLines: 1,
                                ),
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
                                FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${weather.tempMax.toStringAsFixed(0)}°/${weather.tempMin.toStringAsFixed(0)}°',
                                    // weatherProv.isCelsius
                                    //     ? '${weather.tempMax.toStringAsFixed(0)}°/${weather.tempMin.toStringAsFixed(0)}°'
                                    //     : '${weather.tempMax.toFahrenheit().toStringAsFixed(0)}°/${weather.tempMin.toFahrenheit().toStringAsFixed(0)}°',
                                    style: regularText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedIndex == 0 ? '오늘' : DateFormat('EEEE', 'ko').format(_selectedWeather.date),
                          style: mediumText,
                          maxLines: 1,
                        ),
                        Text(
                          '${_selectedWeather.tempMax.toStringAsFixed(0)}°/${_selectedWeather.tempMin.toStringAsFixed(0)}°',
                          // weatherProv.isCelsius
                          //     ? '${_selectedWeather.tempMax.toStringAsFixed(0)}°/${_selectedWeather.tempMin.toStringAsFixed(0)}°'
                          //     : '${_selectedWeather.tempMax.toFahrenheit().toStringAsFixed(0)}°/${_selectedWeather.tempMin.toFahrenheit().toStringAsFixed(0)}°',
                          style: boldText.copyWith(fontSize: 48.0, height: 1.15),
                        ),
                        Text(
                          _selectedWeather.weatherCategory,
                          style: semiboldText.copyWith(color: primaryBlue),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 112.0,
                      width: 112.0,
                      child: Lottie.asset(
                        getWeatherImage(_selectedWeather.weatherCategory),
                        fit: BoxFit.cover,
                      ),
                      // child: Image.asset(
                      //   getWeatherImage(_selectedWeather.weatherCategory),
                      //   fit: BoxFit.cover,
                      // ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '날씨 정보',
                    style: semiboldText.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    padding: const EdgeInsets.all(7.0),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.6),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: GridView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio: 12 / 4,
                        crossAxisCount: 2,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 8,
                      ),
                      children: [
                        _ForecastDetailInfoTile(
                          title: '흐 림',
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.cloud,
                            color: Colors.white,
                          ),
                          data: '${_selectedWeather.clouds}%',
                        ),
                        _ForecastDetailInfoTile(
                          title: 'UV 지수',
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.sun,
                            color: Colors.white,
                          ),
                          data: uviValueToString(_selectedWeather.uvi),
                        ),
                        _ForecastDetailInfoTile(
                          title: '강수량',
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.drop,
                            color: Colors.white,
                          ),
                          data: '${_selectedWeather.precipitation}mm',
                        ),
                        _ForecastDetailInfoTile(
                          title: '습 도',
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.thermometerSimple,
                            color: Colors.white,
                          ),
                          data: '${_selectedWeather.humidity}%',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '체감 온도',
                    style: semiboldText.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    padding: const EdgeInsets.all(7.0),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.6),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: GridView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(3.0),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio: 12 / 4,
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 14,
                      ),
                      children: [
                        _ForecastDetailInfoTile(
                          title: '아침 온도',
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.thermometerSimple,
                            color: Colors.white,
                          ),
                          data: '${_selectedWeather.tempMorning.toStringAsFixed(1)}°',
                        ),
                        _ForecastDetailInfoTile(
                          title: '현재 온도',
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.thermometerSimple,
                            color: Colors.white,
                          ),
                          data: '${_selectedWeather.tempDay.toStringAsFixed(1)}°',
                        ),
                        _ForecastDetailInfoTile(
                          title: '저녁 온도',
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.thermometerSimple,
                            color: Colors.white,
                          ),
                          data: '${_selectedWeather.tempEvening.toStringAsFixed(1)}°',
                        ),
                        _ForecastDetailInfoTile(
                          title: '밤 온도',
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.thermometerSimple,
                            color: Colors.white,
                          ),
                          data: '${_selectedWeather.tempNight.toStringAsFixed(1)}°',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18.0),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ForecastDetailInfoTile extends StatelessWidget {
  const _ForecastDetailInfoTile({
    super.key,
    required this.title,
    required this.data,
    required this.icon,
  });

  final String data;
  final Widget icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      margin: const EdgeInsets.all(1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(backgroundColor: primaryBlue, child: icon),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(child: Text(title, style: lightText)),
                FittedBox(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1.0),
                    child: Text(
                      data,
                      style: mediumText,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
