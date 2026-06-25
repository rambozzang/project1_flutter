import 'package:animate_icons/animate_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weatherCom/cntr/weather_com_controller.dart';
import 'package:project1/app/weatherCom/models/weather_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weather/helper/utils.dart';

class WeatherComPage extends StatefulWidget {
  const WeatherComPage({super.key});

  @override
  State<WeatherComPage> createState() => _WeatherComPageState();
}

class _WeatherComPageState extends State<WeatherComPage> {
  final WeatherComController controller = Get.find<WeatherComController>();

  final double cellWidth = 58.0;

  final double cellHeight = 130.0;

  final double headerHeight = 50.0;

  final double chartHeight = 25.0;

  final double weatherIconSize = 38.0;

  final double borderTopWidth = 4.0;
  final double borderWidth = 1.0;

  final double companyNameWidth = 70.0; // 회사명 컬럼의 너비

  late AnimateIconController controller2;

  ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  ValueNotifier<bool> isAdLoading2 = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadAd();
    controller2 = AnimateIconController();
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('WeathComPage');
    await AdManager().loadBannerAd('WeathComPage2');
    isAdLoading.value = true;
    isAdLoading2.value = true;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        // forceMaterialTransparency: true,
        title: Hero(
            tag: 'appbar',
            child: Text(
              Get.find<WeatherGogoCntr>().currentLocation.value.name,
              style: semiboldText.copyWith(
                fontSize: 18.0,
                decoration: TextDecoration.none,
              ),
            )),
        centerTitle: false,
        titleSpacing: 0.0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        actions: [
          AnimateIcons(
            startIcon: Icons.refresh,
            endIcon: Icons.refresh_rounded,
            controller: controller2,
            // add this tooltip for the start icon
            startTooltip: 'Icons.refresh',
            // add this tooltip for the end icon
            endTooltip: 'Icons.refresh_rounded',
            size: 26.0,
            onStartIconPress: () {
              Get.find<WeatherComController>().fetchAllForecasts();
              return true;
            },
            onEndIconPress: () {
              Get.find<WeatherComController>().fetchAllForecasts();
              return true;
            },
            duration: const Duration(milliseconds: 500),
            startIconColor: Colors.amber,
            endIconColor: Colors.amber,
            clockwise: false,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // Color(0xFF0D1B2A),
              // Color(0xFF1B263B),
              // Color(0xFF2A3B50),

              Color.fromARGB(255, 16, 31, 47),
              Color.fromARGB(255, 38, 53, 80),
              Color.fromARGB(255, 57, 77, 101),
            ],
          ),
        ),
        child: GetBuilder<WeatherComController>(
          builder: (controller) {
            Widget mainWidget;
            if (controller.isLoading.value) {
              mainWidget = _buildLoading(controller);
            } else {
              mainWidget = SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 15),
                    _buildNotice(),
                    const SizedBox(height: 15),
                    _buildHourlyChart(context),
                    const SizedBox(height: 30),
                    if (!controller.isLoading.value) ...[
                      ValueListenableBuilder<bool>(
                          valueListenable: isAdLoading2,
                          builder: (context, value, child) {
                            if (!value) return const SizedBox.shrink();
                            return const BannerAdWidget(screenName: 'WeathComPage2');
                          }),
                    ],
                    const SizedBox(height: 30),
                    _buildDailyChart(context),
                    const SizedBox(height: 15),
                    _buildWeatherProvidersTable(),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: mainWidget,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  // child: child,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.01),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading(controller) {
    int cnt = controller.processCount.value == 0 ? 1 : controller.processCount.value;
    int progress = (cnt / 6 * 100).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 168),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.3,
          child: CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 13.0,
            animation: true,
            animationDuration: 500,
            percent: progress / 100,
            animateFromLastPercent: true,
            center: Text(
              '$progress%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white),
            ),
            footer: Padding(
              padding: const EdgeInsets.symmetric(vertical: 25.0),
              child: Text(
                '데이터 수집 중... $cnt/6개 기관 완료',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0, color: Colors.white),
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Colors.purple,
          ),
        ),
        const Spacer(),
        ValueListenableBuilder<bool>(
            valueListenable: isAdLoading,
            builder: (context, value, child) {
              if (!value) return const SizedBox.shrink();
              return const BannerAdWidget(screenName: 'WeathComPage');
            }),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildNotice() {
    return GetBuilder<WeatherComController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SizedBox.shrink();
        }
        return Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
                '🍇 각 기관의 서버 상태에 따라 데이터 누락 및 수집 지연될 수 있습니다. 또한 서비스 비용 증가, '
                'API 한도 초과, API 요금 미납 등으로 인해 데이터 수집이 차단될 수도 있습니다',
                style: TextStyle(color: Colors.white, fontSize: 12)));
      },
    );
  }

  Widget _buildHourlyChart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('시간별 비교'),
        _buildhourlyDetailChart(
          context: context,
          times: controller.hourlyTimes,
          weatherData: controller.alignedHourlyData,
          buildHeaderRow: _buildHourlyHeaderRow,
          buildWeatherRow: _buildHourlyWeatherRow,
          chartPainter: ChartPainterHour(controller.alignedHourlyData, controller.hourlyTimes.length, cellWidth, cellHeight, chartHeight),
        ),
      ],
    );
  }

  Widget _buildDailyChart(BuildContext context) {
    return GetBuilder<WeatherComController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('일자별 비교'),
            _buildDailyDetailChart(
              context: context,
              dates: controller.dailyDates,
              weatherData: controller.alignedDailyData,
              buildHeaderRow: _buildDailyHeaderRow,
              buildWeatherRow: _buildDailyWeatherRow,
              chartPainter: ChartPainterDay(controller.alignedDailyData, controller.dailyDates.length, cellWidth, cellHeight, chartHeight),
            ),
          ],
        );
      },
    );
  }

  Widget _buildhourlyDetailChart({
    required BuildContext context,
    required List<String> times,
    required Map<String, List<WeatherData>> weatherData,
    required Widget Function() buildHeaderRow,
    required Widget Function(String, List<WeatherData>) buildWeatherRow,
    required CustomPainter chartPainter,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double minCellWidth = 50.0;
    const double maxCellWidth = 80.0;

    // double cellWidth = (screenWidth - 16 - companyNameWidth) / times.length;
    // cellWidth = cellWidth.clamp(minCellWidth, maxCellWidth);

    final double totalWidth = cellWidth * times.length + companyNameWidth;
    final double totalHeight = (weatherData.length * cellHeight) + headerHeight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      width: screenWidth - 16,
      height: totalHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            children: [
              // 데이터 행과 회사명
              Column(
                children: [
                  // 헤더 행
                  Row(
                    children: [
                      Container(
                        width: companyNameWidth,
                        height: headerHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            // top: BorderSide(color: Colors.purple[300]!, width: 3),
                            // bottom: BorderSide(color: Colors.purple[300]!, width: borderWidth),
                            top: BorderSide(color: Colors.lightGreen, width: borderTopWidth),
                            bottom: BorderSide(color: Colors.lightGreen[300]!, width: borderWidth),

                            right: BorderSide(color: Colors.grey[600]!, width: borderWidth),
                          ),
                        ),
                        child: const Text('기관', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      Expanded(child: buildHeaderRow()),
                    ],
                  ),
                  // 데이터 행
                  ...weatherData.entries.map((entry) {
                    return Row(
                      children: [
                        Container(
                          width: companyNameWidth,
                          height: cellHeight,
                          alignment: Alignment.centerLeft,
                          // padding: EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[600]!, width: borderWidth),
                              right: BorderSide(color: Colors.grey[600]!, width: borderWidth),
                            ),
                          ),
                          // child: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold, color: getColorForSource(entry.key))),
                          child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        Expanded(child: buildWeatherRow(entry.key, entry.value)),
                      ],
                    );
                  }),
                ],
              ),
              // 차트
              Positioned(
                left: companyNameWidth,
                top: headerHeight,
                child: SizedBox(
                  width: totalWidth - companyNameWidth,
                  height: totalHeight - headerHeight,
                  child: CustomPaint(
                    painter: chartPainter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyDetailChart({
    required BuildContext context,
    required List<String> dates,
    required Map<String, List<WeatherData>> weatherData,
    required Widget Function() buildHeaderRow,
    required Widget Function(String, List<WeatherData>) buildWeatherRow,
    required CustomPainter chartPainter,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dailyCellWidth = cellWidth * 2; // 각 날짜(오전/오후)의 전체 너비
    final double totalWidth = dailyCellWidth * dates.length + companyNameWidth;
    final double totalHeight = (weatherData.length * cellHeight) + headerHeight + 35; // 35는 오전/오후 헤더의 높이

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      width: screenWidth - 16,
      height: totalHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            children: [
              // 데이터 행과 회사명
              Column(
                children: [
                  // 헤더 행
                  Row(
                    children: [
                      Container(
                        width: companyNameWidth,
                        height: headerHeight + 35,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.purple[300]!, width: borderTopWidth),
                            bottom: BorderSide(color: Colors.purple[300]!, width: borderWidth),
                            right: BorderSide(color: Colors.grey[600]!, width: borderWidth),
                          ),
                        ),
                        child: const Text('기관', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      Expanded(child: buildHeaderRow()),
                    ],
                  ),
                  // 데이터 행
                  ...weatherData.entries.map((entry) {
                    return Row(
                      children: [
                        Container(
                          width: companyNameWidth,
                          height: cellHeight,
                          alignment: Alignment.centerLeft,
                          // padding: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[600]!, width: borderWidth),
                              right: BorderSide(color: Colors.grey[600]!, width: borderWidth),
                            ),
                          ),
                          // child: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold, color: getColorForSource(entry.key))),
                          child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        Expanded(child: buildWeatherRow(entry.key, entry.value)),
                      ],
                    );
                  }),
                ],
              ),
              // 차트
              Positioned(
                left: companyNameWidth,
                top: headerHeight + 35,
                child: SizedBox(
                  width: totalWidth - companyNameWidth,
                  height: totalHeight - headerHeight - 35,
                  child: CustomPaint(
                    painter: chartPainter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildHourlyHeaderRow() {
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        border: Border(
          // top: BorderSide(color: Colors.purple[300]!, width: 3),
          // bottom: BorderSide(color: Colors.purple[300]!, width: borderWidth),
          // top: BorderSide(color: Colors.grey!, width: borderTopWidth),
          // bottom: BorderSide(color: Colors.grey[300]!, width: borderWidth),
          top: BorderSide(color: Colors.lightGreen, width: borderTopWidth),
          bottom: BorderSide(color: Colors.lightGreen[300]!, width: borderWidth),
        ),
      ),
      child: Row(
        children: List.generate(controller.hourlyTimes.length, (index) {
          return _buildHeaderCell(index, controller.hourlyTimes[index], cellWidth, headerHeight);
        }),

        // controller.hourlyTimes.map((time) => _buildHeaderCell(time, cellWidth, headerHeight)).toList(),
      ),
    );
  }

  Widget _buildDailyHeaderRow() {
    int rowIndex = 0;
    return Container(
      height: headerHeight + 35,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.purple[300]!, width: borderTopWidth),
          bottom: BorderSide(color: Colors.purple[300]!, width: borderWidth),
        ),
      ),
      child: Row(
        children: controller.dailyDates.map((date) {
          rowIndex++;
          return SizedBox(
            width: cellWidth * 2,
            child: Column(
              children: [
                Container(
                  height: headerHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rowIndex % 2 == 1 ? const Color(0xFF0D1B2A) : const Color(0xFF1B263B),
                    // border: Border(right: BorderSide(color: Colors.grey[600]!, width: borderWidth)),
                  ),
                  child: Text(
                    date,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Row(
                  children: ['오전', '오후'].map((part) {
                    return Container(
                      width: cellWidth,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rowIndex % 2 == 1 ? const Color(0xFF0D1B2A) : const Color(0xFF1B263B),
                        // border: Border(right: BorderSide(color: Colors.grey[600]!, width: borderWidth)),
                      ),
                      child: Text(
                        part,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderCell(int index, String text, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? const Color(0xFF0D1B2A) : const Color(0xFF1B263B),
        // border: Border(right: BorderSide(color: Colors.grey[300]!, width: borderWidth)),
      ),
      child: Center(
        child: Text(
          '$text시',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHourlyWeatherRow(String source, List<WeatherData> data) {
    return Row(
      children: List.generate(data.length, (index) {
        return _buildWeatherCell(index, data[index], cellWidth);
      }),
    );
  }

  Widget _buildDailyWeatherRow(String source, List<WeatherData> data) {
    return Row(
      children: List.generate(data.length ~/ 2, (index) {
        return Row(
          children: [
            _buildWeatherCell(index, data[index * 2], cellWidth),
            _buildWeatherCell(index, data[index * 2 + 1], cellWidth),
          ],
        );
      }),
    );
  }

  String getlottiefilePath(WeatherData weatherData) {
    //기상청
    if (weatherData.source.contains('json')) {
      return weatherData.source;
    }
    // openweathermap
    return getWeatherImage(weatherData.source);
  }

  Widget _buildWeatherCell(int index, WeatherData weatherData, double width) {
    String rainPo = weatherData.rainProbability == 0.9999 ? '-' : '${(weatherData.rainProbability * 100).toStringAsFixed(0)}%';

    return Container(
      width: width,
      height: cellHeight,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? const Color(0xFF0D1B2A) : const Color(0xFF1B263B),
        border: Border(
          bottom: BorderSide(color: Colors.grey[600]!, width: borderWidth),
          // right: BorderSide(color: Colors.red[300]!, width: borderWidth),
        ),
      ),
      child: weatherData.temperature.isNaN
          ? const Center(child: Text('-', style: TextStyle(fontSize: 14, color: Colors.white)))
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Lottie.asset(
                  getlottiefilePath(weatherData),
                  height: weatherIconSize,
                  width: weatherIconSize,
                ),
                SizedBox(height: chartHeight),
                Text(
                  '${weatherData.temperature.toStringAsFixed(1)}°',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                Text(
                  rainPo.toString(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.yellow[800]),
                ),
              ],
            ),
    );
  }

  Widget _buildCompanyName(String name, Color color) {
    return Positioned(
      top: 49,
      left: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherProvidersTable() {
    return GetBuilder<WeatherComController>(
      builder: (cntr) {
        if (cntr.isLoading.value) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(8.0),
          // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            // color: Colors.white,
            border: Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              const Text(
                '날씨 정보 제공 업체',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 25),
              _buildTableRow('기상청', 'https://www.weather.go.kr/w/resources/image/foot_logo2.png', '기상청', '한국의 상세한 기상 예보 제공.', '대한민국',
                  '기상청(KMA)은 한국 내에서 가장 신뢰할 수 있는 기상 정보를 제공하는 국가 기관입니다.'),
              _buildTableRow('OpenWeatherMap', 'https://brands.home-assistant.io/_/openweathermap/logo@2x.png', '글로벌 날씨 데이터 제공',
                  '전 세계의 현재 날씨 데이터를 제공.', '영국', 'OpenWeatherMap은 다양한 API를 통해 실시간 날씨 데이터, 예보 및 역사 데이터를 제공합니다.'),
              _buildTableRow('AccuWeather', 'https://ad-engine.accuweather.com/images/logos/accuweather-dark.png', '정확한 날씨 예보 제공',
                  '높은 정확도로 유명.', '미국', 'AccuWeather는 사용자에게 매우 정확한 기상 예보를 제공하며, 전 세계적으로 많은 사용자를 보유하고 있습니다.'),
              _buildTableRow('MetNorway', 'https://www.met.no/en/_/asset/no.met.metno:0000019005ff5d20/images/met-logo.png', '노르웨이 기상 연구소',
                  '북유럽 및 북극 지역의 기상 데이터 전문.', '노르웨이', 'MetNorway는 노르웨이 기상 연구소로, 특히 북유럽 및 북극 지역의 상세한 기상 데이터를 제공합니다.'),
              _buildTableRow('Tomorrow.io', 'https://dka575ofm4ao0.cloudfront.net/pages-transactional_logos/retina/290306/logo.png',
                  '기상 정보 플랫폼', '첨단 기술을 사용한 기상 예보 제공.', '미국', 'Tomorrow.io는 인공지능과 머신러닝을 사용하여 보다 정밀한 기상 예보를 제공하는 플랫폼입니다.'),
              _buildTableRow('WeatherAPI', 'https://cdn.weatherapi.com/v4/images/weatherapi_logo.png', '신뢰할 수 있는 날씨 API 서비스',
                  '간단한 API로 풍부한 날씨 데이터 제공.', '영국', 'WeatherAPI는 사용이 간편한 API를 통해 다양한 기상 데이터를 제공합니다. 특히 개발자들에게 인기가 많습니다.'),
              _buildTableRow('웨더뉴스', 'https://www.kr-weathernews.com/mv4/html/assets/images/fullLogo.webp', '종합 기상 정보 제공',
                  '정확하고 신속한 기상 정보 제공.', '일본', '웨더뉴스는 일본에서 시작된 기상 정보 제공 회사로, 정확하고 신속한 기상 정보를 제공합니다. 또한, 전 세계적으로 다양한 기상 데이터를 제공하고 있습니다.'),
              _buildTableRow(
                  '웨더채널',
                  'https://play-lh.googleusercontent.com/RV3DftXlA7WUV7w-BpE8zM0X7Y4RQd2vBvZVv6A01DEGb_eXFRjLmUhSqdbqrEl9klI=w480-h960-rw',
                  '기상 방송 및 뉴스 제공',
                  '신뢰할 수 있는 기상 뉴스 및 예보 제공.',
                  '미국',
                  '웨더채널은 미국에서 가장 인기 있는 기상 방송 채널 중 하나로, 신뢰할 수 있는 기상 뉴스와 예보를 제공합니다. 또한, 다양한 기상 관련 콘텐츠를 제공합니다.'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableRow(String name, String logoUrl, String description, String features, String country, String details) {
    Color clr = Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
          // constraints: const BoxConstraints(min: 80),
          width: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            color: Colors.white.withOpacity(0.9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                logoUrl,
                width: 130,
                height: 50,
                fit: BoxFit.contain,
                // color: Colors.white,
              ),
              // Text(
              //   name,
              //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(fontSize: 12, color: clr)),
        const SizedBox(height: 4),
        Text('특징: $features', style: TextStyle(fontSize: 12, color: clr)),
        const SizedBox(height: 4),
        Text('소재지: $country', style: TextStyle(fontSize: 12, color: clr)),
        const SizedBox(height: 4),
        Text(details, style: TextStyle(fontSize: 12, color: clr)),
        const SizedBox(height: 25),
      ],
    );
  }
}

// ChartPainterHour and ChartPainterDay classes remain the same

class ChartPainterHour extends CustomPainter {
  final Map<String, List<WeatherData?>> weatherData;
  final int timePoints;
  final double cellWidth;
  final double cellHeight;
  final double chartHeight;

  ChartPainterHour(this.weatherData, this.timePoints, this.cellWidth, this.cellHeight, this.chartHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final double chartTopPadding = cellHeight * 0.3;
    final double chartBottomPadding = cellHeight * 0.4;

    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;
    for (var data in weatherData.values) {
      for (var weatherData in data) {
        if (weatherData != null && !weatherData.temperature.isNaN) {
          if (weatherData.temperature < minTemp) minTemp = weatherData.temperature;
          if (weatherData.temperature > maxTemp) maxTemp = weatherData.temperature;
        }
      }
    }

    minTemp -= 2;
    maxTemp += 2;

    int i = 0;
    weatherData.forEach((source, dataList) {
      final linePaint = Paint()
        ..color = getColorForSource(source)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final dotPaint = Paint()
        ..color = getColorForSource(source)
        ..style = PaintingStyle.fill;

      final path = Path();
      bool isFirstPoint = true;

      for (int j = 0; j < dataList.length; j++) {
        final weatherData = dataList[j];
        if (weatherData != null && !weatherData.temperature.isNaN) {
          final double x = j * cellWidth + cellWidth / 2;
          final double normalizedTemp = (weatherData.temperature - minTemp) / (maxTemp - minTemp);
          final double y = i * cellHeight + chartTopPadding + (1 - normalizedTemp) * (cellHeight - chartTopPadding - chartBottomPadding);

          if (isFirstPoint) {
            path.moveTo(x, y);
            isFirstPoint = false;
          } else {
            path.lineTo(x, y);
          }

          canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
        }
      }

      canvas.drawPath(path, linePaint);
      i++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChartPainterDay extends CustomPainter {
  final Map<String, List<WeatherData>> weatherData;
  final int datePoints;
  final double cellWidth;
  final double cellHeight;
  final double chartHeight;

  ChartPainterDay(this.weatherData, this.datePoints, this.cellWidth, this.cellHeight, this.chartHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final double chartTopPadding = cellHeight * 0.3;
    final double chartBottomPadding = cellHeight * 0.4;
    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;

    // 온도 범위 계산
    for (var dataList in weatherData.values) {
      for (var data in dataList) {
        if (!data.temperature.isNaN) {
          if (data.temperature < minTemp) minTemp = data.temperature;
          if (data.temperature > maxTemp) maxTemp = data.temperature;
        }
      }
    }
    minTemp -= 2;
    maxTemp += 2;

    int sourceIndex = 0;
    weatherData.forEach((source, dataList) {
      final linePaint = Paint()
        ..color = getColorForSource(source)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final dotPaint = Paint()
        ..color = getColorForSource(source)
        ..style = PaintingStyle.fill;

      for (int dateIndex = 0; dateIndex < dataList.length; dateIndex += 2) {
        final morningData = dataList[dateIndex];
        final afternoonData = dateIndex + 1 < dataList.length ? dataList[dateIndex + 1] : null;

        if (!morningData.temperature.isNaN) {
          final double x1 = dateIndex * cellWidth + cellWidth / 2;
          final double normalizedTemp1 = (morningData.temperature - minTemp) / (maxTemp - minTemp);
          final double y1 =
              sourceIndex * cellHeight + chartTopPadding + (1 - normalizedTemp1) * (cellHeight - chartTopPadding - chartBottomPadding);

          canvas.drawCircle(Offset(x1, y1), 3.5, dotPaint);

          if (afternoonData != null && !afternoonData.temperature.isNaN) {
            final double x2 = x1 + cellWidth;
            final double normalizedTemp2 = (afternoonData.temperature - minTemp) / (maxTemp - minTemp);
            final double y2 =
                sourceIndex * cellHeight + chartTopPadding + (1 - normalizedTemp2) * (cellHeight - chartTopPadding - chartBottomPadding);

            canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
            canvas.drawCircle(Offset(x2, y2), 3.5, dotPaint);

            // 다음 날 아침 데이터와 연결
            if (dateIndex + 2 < dataList.length) {
              final nextMorningData = dataList[dateIndex + 2];
              if (!nextMorningData.temperature.isNaN) {
                final double x3 = (dateIndex + 2) * cellWidth + cellWidth / 2;
                final double normalizedTemp3 = (nextMorningData.temperature - minTemp) / (maxTemp - minTemp);
                final double y3 = sourceIndex * cellHeight +
                    chartTopPadding +
                    (1 - normalizedTemp3) * (cellHeight - chartTopPadding - chartBottomPadding);

                canvas.drawLine(Offset(x2, y2), Offset(x3, y3), linePaint);
              }
            }
          }
        }
      }
      sourceIndex++;
    });

    // 날짜 구분선 그리기
    // final dateSeparatorPaint = Paint()
    //   ..color = Colors.grey.withOpacity(0.5)
    //   ..strokeWidth = 1
    //   ..style = PaintingStyle.stroke;

    // for (int i = 1; i < datePoints; i++) {
    //   final x = i * cellWidth * 2;
    //   canvas.drawLine(Offset(x, 0), Offset(x, size.height), dateSeparatorPaint);
    // }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color getColorForSource(String source) {
  switch (source) {
    // case '기상청':
    //   return Colors.blue;
    // case 'OpenWeather':
    //   return Colors.red;
    // case 'METNorway':
    //   return Colors.green;
    // case 'WeatherAPI':
    //   return Colors.orange;
    // case 'Tomorrow.io':
    //   return Colors.purple;
    // case 'AccuWeather':
    //   return Colors.indigo;
    case 'Yesterday':
      return const Color.fromARGB(255, 232, 232, 2); {}
    // return const Color.fromARGB(255, 223, 214, 42);
    case 'Today':
      return Colors.deepOrangeAccent;
    // return const Color.fromARGB(255, 255, 191, 0);
    // return Colors.blue[700]!;
    default:
      return Colors.white;
  }
}

//  Kma
//  dailyData : 2024-07-31 00:00:00.000 temp : 30.0 rain : 0.2 source : assets/lottie/day_cloudy.json
//  dailyData : 2024-07-31 00:00:00.000 temp : 27.0 rain : 0.2 source : assets/lottie/day_cloudy.json
//  dailyData : 2024-08-01 00:00:00.000 temp : 30.0 rain : 0.2 source : assets/lottie/day_cloudy.json
//  dailyData : 2024-08-01 00:00:00.000 temp : 28.0 rain : 0.2 source : assets/lottie/day_cloudy.json
//  dailyData : 2024-08-02 00:00:00.000 temp : 26.0 rain : 0.9 source : assets/lottie/sun.json
//  dailyData : 2024-08-02 00:00:00.000 temp : 32.0 rain : 0.7000000000000001 source : assets/lottie/sun.json
//  dailyData : 2024-08-03 00:00:00.000 temp : 26.0 rain : 0.3 source : assets/lottie/sun.json
//  dailyData : 2024-08-03 00:00:00.000 temp : 33.0 rain : 0.2 source : assets/lottie/sun.json
//  dailyData : 2024-08-04 00:00:00.000 temp : 27.0 rain : 0.3 source : assets/lottie/sun.json
//  dailyData : 2024-08-04 00:00:00.000 temp : 33.0 rain : 0.2 source : assets/lottie/sun.json
//  dailyData : 2024-08-05 00:00:00.000 temp : 27.0 rain : 0.2 source : assets/lottie/sun.json
//  dailyData : 2024-08-05 00:00:00.000 temp : 33.0 rain : 0.2 source : assets/lottie/sun.json
//  dailyData : 2024-08-06 00:00:00.000 temp : 26.0 rain : 0.4 source : assets/lottie/sun.json
//  dailyData : 2024-08-06 00:00:00.000 temp : 32.0 rain : 0.4 source : assets/lottie/sun.json
//  OpenWeatherMap
//  dailyData : 2024-07-30 12:00:00.000 temp : 24.97 rain : 0.32 source : Rain
//  dailyData : 2024-07-30 12:00:00.000 temp : 31.66 rain : 0.32 source : Rain
//  dailyData : 2024-07-31 12:00:00.000 temp : 24.63 rain : 0.11 source : Clouds
//  dailyData : 2024-07-31 12:00:00.000 temp : 32.89 rain : 0.11 source : Clouds
//  dailyData : 2024-08-01 12:00:00.000 temp : 25.89 rain : 0.26 source : Rain
//  dailyData : 2024-08-01 12:00:00.000 temp : 31.57 rain : 0.26 source : Rain
//  dailyData : 2024-08-02 12:00:00.000 temp : 26.21 rain : 0.83 source : Rain
//  dailyData : 2024-08-02 12:00:00.000 temp : 32.62 rain : 0.83 source : Rain
//  dailyData : 2024-08-03 12:00:00.000 temp : 26.23 rain : 0.37 source : Rain
//  dailyData : 2024-08-03 12:00:00.000 temp : 34.19 rain : 0.37 source : Rain
//  dailyData : 2024-08-04 12:00:00.000 temp : 26.6 rain : 0.6 source : Rain
//  dailyData : 2024-08-04 12:00:00.000 temp : 35.16 rain : 0.6 source : Rain
//  dailyData : 2024-08-05 12:00:00.000 temp : 27.1 rain : 0.86 source : Rain
//  dailyData : 2024-08-05 12:00:00.000 temp : 31.7 rain : 0.86 source : Rain
//  dailyData : 2024-08-06 12:00:00.000 temp : 25.51 rain : 0.76 source : Rain
//  dailyData : 2024-08-06 12:00:00.000 temp : 30.24 rain : 0.76 source : Rain
