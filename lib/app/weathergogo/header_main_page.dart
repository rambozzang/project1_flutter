import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weather/widgets/dust_bar_gauge.dart';
import 'package:project1/app/weather/widgets/dust_detail_modal.dart';
import 'package:project1/app/weathergogo/cntr/data/current_weather_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/weather/data/weather_view_data.dart';
import 'package:project1/utils/log_utils.dart';

class HeaderMainPage extends GetView<WeatherGogoCntr> {
  const HeaderMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildYesterdayInfo(controller.yesterdayDesc.value),
                  _buildTemperature(controller.currentWeather.value.temp ?? '0.0', controller.tempCountSeq.value),
                  const Gap(5),
                  _buildConditionLine(controller),
                  _buildAirQualityInfo(controller.mistData, context),
                ],
              ),
            ),
            _buildWeatherAnimation(controller.currentWeather.value),
          ],
        ),
      ),
    );
  }

  // 날씨 설명(맑음/비/흐림 등) + 오른쪽에 오늘(0~23시) 최고(↑)·최저(↓) 기온.
  Widget _buildConditionLine(WeatherGogoCntr controller) {
    final List<double>? minMax = controller.todayHiLo.value; // [min, max] — 컨트롤러가 오늘 실황+예보로 계산
    return Row(
      children: [
        Flexible(
          child: Text(
            controller.currentWeather.value.description ?? '맑음',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: lightText.copyWith(fontSize: 16),
          ),
        ),
        if (minMax != null) ...[
          const Gap(10),
          _buildTodayHiLo(minMax[0], minMax[1]),
        ],
      ],
    );
  }

  // 오늘(0~23시) 최고/최저 기온 표시 — ↑최고 ↓최저(°).
  Widget _buildTodayHiLo(double min, double max) {
    const shadow = [Shadow(color: Colors.black38, blurRadius: 4)];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.redAccent.shade100, shadows: shadow),
        Text('${max.toStringAsFixed(1)}°',
            style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600, shadows: shadow)),
        const Gap(6),
        Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.lightBlueAccent.shade100, shadows: shadow),
        Text('${min.toStringAsFixed(1)}°',
            style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600, shadows: shadow)),
      ],
    );
  }

  Widget _buildYesterdayInfo(String? yesterdayDesc) {
    if (yesterdayDesc == null || yesterdayDesc.isEmpty) return const SizedBox(height: 16);
    return SizedBox(
      height: 16,
      child: Text(
        yesterdayDesc,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 15,
          color: yesterdayDesc.contains('낮') ? Colors.green : Colors.amber,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildTemperature(String temp, int seq) {
    // 리프레시·관심지역·현재위치 클릭 등 새 조회마다(seq 증가) 숫자가 매번 0부터
    // 다시 카운트업된다. key를 seq로 두어 TweenAnimationBuilder를 새로 시작시킨다.
    final double target = double.tryParse(temp) ?? 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey<int>(seq),
          tween: Tween<double>(begin: 0, end: target),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 56,
              height: 1,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              // 카운트 중 자릿수 폭이 흔들리지 않게 고정폭 숫자 사용.
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const Text(
          '°C',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAirQualityInfo(Rx<MistViewData?> mistViewData, BuildContext context) {
    return Obx(() {
      final mist = mistViewData.value;
      if (mist == null || (mist.mist10Grade == null && mist.mist25Grade == null)) {
        return const SizedBox.shrink();
      }
      // 캡슐/배경 없이 하늘 위에 바로 얹는 가로 바 게이지 — 앱의 가벼운 톤 유지.
      // 가독성은 위젯 내부의 텍스트 섀도우·바 그림자가 담당한다.
      return GestureDetector(
        onTap: () => DustDetailModal.show(
          context,
          controller.mistDetailData.value,
          pm10: mist.mist10,
          pm25: mist.mist25,
          pm10Grade: mist.mist10Grade,
          pm25Grade: mist.mist25Grade,
          locationName: controller.currentLocation.value.name,
        ),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.transparent,
          // 좁은 화면에서 '상세' 힌트까지 더해지면 가로폭이 넘칠 수 있어, 넘칠 때만 축소해 오버플로우 방지.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DustBarGauge(
                  label: '미세',
                  value: mist.mist10,
                  grade: mist.mist10Grade,
                  max: 150,
                ),
                const Gap(10),
                DustBarGauge(
                  label: '초미세',
                  value: mist.mist25,
                  grade: mist.mist25Grade,
                  max: 75,
                ),
                const Gap(12),
                // 탭 가능하다는 신호(어포던스) — 배경 없이 '상세 ›' 힌트만.
                _buildTapHint(),
              ],
            ),
          ),
        ),
      );
    });
  }

  // 미세/초미세 영역이 탭 가능함을 알리는 힌트 — 밝은 하늘 대비용 섀도우 포함.
  Widget _buildTapHint() {
    const shadow = [Shadow(color: Colors.black54, blurRadius: 4)];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '상세',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w700,
            shadows: shadow,
          ),
        ),
        Icon(
          Icons.chevron_right,
          size: 16,
          color: Colors.white.withValues(alpha: 0.92),
          shadows: shadow,
        ),
      ],
    );
  }

  Widget _buildWeatherAnimation(CurrentWeatherData weather) {
    lo.g('weather.sky: ${weather.sky}, weather.rain: ${weather.rain}');

    return SizedBox(
      height: 120.0,
      width: 120.0,
      child: WeatherDataProcessor.instance.getFinalWeatherIcon(
        DateTime.now().hour,
        weather.sky?.toString() ?? '',
        weather.rain?.toString() ?? '',
      ),
    );
  }
}
