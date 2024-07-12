// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/full_width_banner_ad.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/app/weather/page/kakao_searchbar.dart';
import 'package:project1/app/weather/page/location_error.dart';
import 'package:project1/app/webview/weather_webview.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

import '../theme/textStyle.dart';
import '../widgets/WeatherInfoHeader.dart';
import '../widgets/mainWeatherDetail.dart';
import '../widgets/mainWeatherInfo.dart';
import '../widgets/sevenDayForecast.dart';
import '../widgets/twentyFourHourForecast.dart';

import 'request_error.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with TickerProviderStateMixin {
  // FloatingSearchBarController fsc = FloatingSearchBarController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> requestWeather() async {
    await Get.find<WeatherCntr>().getWeatherData();
  }

  Future<void> requesGemini(Position position) async {
    final gemini = Gemini.instance;

    // 온도
    double? temp = Get.find<WeatherCntr>().oneCallCurrentWeather.value!.temp;
    //흐림정도
    int? clouds = Get.find<WeatherCntr>().additionalWeatherData.value.clouds;
    // 바람
    String windSpeed = '${Get.find<WeatherCntr>().oneCallCurrentWeather.value!.wind_speed}m/s';

    String? uv = Get.find<WeatherCntr>().additionalWeatherData.value.uvi.toString();
    String? rain = '${Get.find<WeatherCntr>().additionalWeatherData.value.precipitation}mm';

    Get.find<WeatherCntr>().geminiResult.value = 'Ai....';
    gemini.streamGenerateContent('현재 온도 $temp°C , 바람 $windSpeed mm , UV지수 $uv , 강수량 $rain 이 날씨에 맞는 옷차림?').listen((value) {
      // gemini.streamGenerateContent('현재 ${Get.find<WeatherCntr>().currentWeather.value?.main?.temp} C 온도에  옷차림은 어떻게 할까요?').listen((value) {
      Get.find<WeatherCntr>().geminiResult.value = value.output!;
    }).onError((e) {
      log('streamGenerateContent exception :   ${e.toString()}');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFF262B49),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        title: const WeatherInfoHeader(),
      ),
      body: RefreshIndicator(onRefresh: () async {
        await requestWeather();
      }, child: GetBuilder<WeatherCntr>(
        builder: (weatherProv) {
          Lo.g('weatherProv.isLoading.value : ${weatherProv.isLoading.value}');

          if (!weatherProv.isLoading.value && !weatherProv.isLocationserviceEnabled.value) return const LocationServiceErrorDisplay();

          if (!weatherProv.isLoading.value &&
              weatherProv.locationPermission != LocationPermission.always &&
              weatherProv.locationPermission != LocationPermission.whileInUse) {
            return const LocationPermissionErrorDisplay();
          }

          if (weatherProv.isRequestError.value) return const RequestErrorDisplay();

          // if (weatherProv.isSearchError.value) return SearchErrorDisplay( );

          if (weatherProv.isLoading.value) return SizedBox(height: MediaQuery.of(context).size.height * 0.5, child: Utils.progressbar());

          return Stack(
            children: [
              ListView(
                controller: RootCntr.to.hideButtonController5,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 24.0).copyWith(
                  top: kToolbarHeight + 15,
                ),
                children: [
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
                              ),
                              onPressed: () => Get.toNamed('/MapPage'),
                              child: Row(
                                children: [
                                  Text(
                                    '지도 보기 ',
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
                  const MainWeatherInfo(),
                  const SizedBox(height: 16.0),
                  // gemini 컨테이너
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 52, 59, 100),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Gemini AI',
                            style: TextStyle(color: Colors.yellow),
                          ),
                        ),
                        Text(
                          weatherProv.geminiResult.value,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  //   margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  //   decoration: BoxDecoration(
                  //     color: const Color.fromARGB(255, 52, 59, 100),
                  //     borderRadius: BorderRadius.circular(10.0),
                  //   ),
                  //   child: SingleChildScrollView(
                  //     scrollDirection: Axis.horizontal,
                  //     child: Expanded(
                  //       child: Row(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Container(
                  //             width: 100.0,
                  //             height: 160.0,
                  //             decoration: BoxDecoration(
                  //               color: Colors.grey[300],
                  //               borderRadius: BorderRadius.circular(10.0),
                  //               image: DecorationImage(
                  //                 image: CachedNetworkImageProvider(Get.find<VideoListCntr>().list[0].thumbnailPath!),
                  //                 fit: BoxFit.cover,
                  //               ),
                  //             ),
                  //           ),
                  //           const Gap(10),
                  //           Container(
                  //             width: 100.0,
                  //             height: 160.0,
                  //             decoration: BoxDecoration(
                  //               color: Colors.grey[300],
                  //               borderRadius: BorderRadius.circular(10.0),
                  //               image: DecorationImage(
                  //                 image: CachedNetworkImageProvider(Get.find<VideoListCntr>().list[1].thumbnailPath!),
                  //                 fit: BoxFit.cover,
                  //               ),
                  //             ),
                  //           ),
                  //           const Gap(10),
                  //           Container(
                  //             width: 100.0,
                  //             height: 160.0,
                  //             decoration: BoxDecoration(
                  //               color: Colors.grey[300],
                  //               borderRadius: BorderRadius.circular(10.0),
                  //               image: DecorationImage(
                  //                 image: CachedNetworkImageProvider(Get.find<VideoListCntr>().list[2].thumbnailPath!),
                  //                 fit: BoxFit.cover,
                  //               ),
                  //             ),
                  //           ),
                  //           const Gap(10),
                  //           Container(
                  //             width: 100.0,
                  //             height: 160.0,
                  //             decoration: BoxDecoration(
                  //               color: Colors.grey[300],
                  //               borderRadius: BorderRadius.circular(10.0),
                  //               image: DecorationImage(
                  //                 image: CachedNetworkImageProvider(Get.find<VideoListCntr>().list[3].thumbnailPath!),
                  //                 fit: BoxFit.cover,
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  // 6가지 항목 컨테이너
                  const MainWeatherDetail(),
                  const SizedBox(height: 16.0),
                  // 24시간 예보 / 24HourForecast
                  const TwentyFourHourForecast(),
                  const SizedBox(height: 18.0),
                  // 주간예보 / 7일 예보
                  const SevenDayForecast(),
                  const SizedBox(height: 28.0),
                  const SizedBox(
                      height: 458.0,
                      child: WeatherWebView(
                        isBackBtn: false,
                      )),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(0.0),
                    ),
                    onPressed: () => Get.toNamed('/WeatherWebView'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '위성사진 전체보기 ',
                          style: semiboldText.copyWith(fontSize: 11.0),
                        ),
                        const Gap(5),
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
      )),
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
