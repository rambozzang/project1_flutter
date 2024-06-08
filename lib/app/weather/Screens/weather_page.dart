// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/full_width_banner_ad.dart';
import 'package:project1/app/weather/Screens/kakao_searchbar.dart';
import 'package:project1/app/weather/Screens/locationError.dart';
import 'package:project1/app/weather/widgets/CustomSearchBar.dart';
import 'package:project1/app/webview/weather_webvide.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';
import 'package:provider/provider.dart';

import '../provider/weatherProvider.dart';
import '../theme/colors.dart';
import '../theme/textStyle.dart';
import '../widgets/WeatherInfoHeader.dart';
import '../widgets/mainWeatherDetail.dart';
import '../widgets/mainWeatherInfo.dart';
import '../widgets/sevenDayForecast.dart';
import '../widgets/twentyFourHourForecast.dart';

import 'requestError.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with TickerProviderStateMixin {
  FloatingSearchBarController fsc = FloatingSearchBarController();

  @override
  void initState() {
    super.initState();
    requestWeather();
  }

  int _getRandomInt(int min, int max) {
    final Random random = Random();
    return min + random.nextInt(max - min);
  }

  Future<void> requestWeather() async {
    await Provider.of<WeatherProvider>(context, listen: false).getWeatherData(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        title: WeatherInfoHeader(),
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProv, _) {
          if (!weatherProv.isLoading && !weatherProv.isLocationserviceEnabled) return const LocationServiceErrorDisplay();

          if (!weatherProv.isLoading &&
              weatherProv.locationPermission != LocationPermission.always &&
              weatherProv.locationPermission != LocationPermission.whileInUse) {
            return const LocationPermissionErrorDisplay();
          }

          if (weatherProv.isRequestError) return const RequestErrorDisplay();

          if (weatherProv.isSearchError) return SearchErrorDisplay(fsc: fsc);

          if (weatherProv.isLoading) return Center(child: Utils.progressbar());

          return Stack(
            children: [
              ListView(
                controller: RootCntr.to.hideButtonController5,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(12.0).copyWith(
                  top: kToolbarHeight + MediaQuery.viewPaddingOf(context).top + 24.0,
                ),
                children: [
                  // WeatherInfoHeader(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '날씨 정보',
                              style: semiboldText.copyWith(fontSize: 24.0),
                            ),
                            const Gap(
                              10,
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(0.0),
                                // backgroundColor: primaryBlue,
                              ),
                              onPressed: () => Get.toNamed('/MapPage'),
                              child: Row(
                                children: [
                                  Text(
                                    'CCTV 보기 ',
                                    style: semiboldText.copyWith(fontSize: 9.0),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 10.0, color: Colors.amber),
                                ],
                              ),
                            ),
                            const Gap(15),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(0.0),
                              ),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => KakaoSearchPage())),
                              child: Row(
                                children: [
                                  Text(
                                    '카카오 검색 ',
                                    style: semiboldText.copyWith(fontSize: 9.0),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 10.0, color: Colors.amber),
                                ],
                              ),
                            ),
                            const Gap(15),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.bolt, color: Colors.amber, size: 24.0),
                          onPressed: () => requestWeather(),
                        ),
                      ),
                    ],
                  ),
                  //    const SizedBox(height: 16.0),
                  MainWeatherInfo(),
                  const SizedBox(height: 16.0),
                  MainWeatherDetail(),
                  const SizedBox(height: 24.0),

                  // 24시간 예보 / 24HourForecast
                  TwentyFourHourForecast(),

                  const SizedBox(height: 18.0),
                  // 주간예보 / 7일 예보
                  SevenDayForecast(),
                  const SizedBox(height: 28.0),
                  const SizedBox(
                      height: 458.0,
                      child: WeatherWebVidew(
                        isBackBtn: false,
                      )),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(0.0),
                      // backgroundColor: primaryBlue,
                    ),
                    onPressed: () => Get.toNamed('/WeatherWebVidew'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '위성사진 전체보기 ',
                          style: semiboldText.copyWith(fontSize: 11.0),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 10.0, color: Colors.amber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 38.0),
                  // Ads 패딩 적용
                  FullWidthBannerAd(bannerAd: AdManager.instance.myCafeScreenBannerAd, sidePadding: 40.0),
                ],
              ),
              // CustomSearchBar(fsc: fsc),
              const KakaoSearchPage(),
            ],
          );
        },
      ),
    );
  }
}

class SalesData {
  SalesData(this.year, this.sales);
  final String year;
  final double sales;
}

class _ChartData {
  _ChartData(this.x, this.y, this.z);
  final int x;
  final int y;
  final int z;
}
