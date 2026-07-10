import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:text_scroll/text_scroll.dart';

/// 특보 안내 힌트 — 관심지역이 없으면 특보가 뜨지 않으므로, 메인 상단에
/// 앱 실행당 1회 · 진입 3초 뒤 · 8초간 '마퀴(흐르는 한 줄)'로 나타났다가 스르륵 사라진다.
/// 탭하면 관심지역 등록 화면으로 이동. (관심지역이 이미 있으면 조용히 넘어감)
class SpecialWeatherHint extends StatefulWidget {
  const SpecialWeatherHint({super.key});

  @override
  State<SpecialWeatherHint> createState() => _SpecialWeatherHintState();
}

class _SpecialWeatherHintState extends State<SpecialWeatherHint> {
  // 앱 실행당 1회만 — 메인 재진입/리빌드에도 반복 노출되지 않게.
  static bool _shownThisSession = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!_shownThisSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  Future<void> _run() async {
    // 진입 직후 관심지역이 아직 로딩 중일 수 있어 잠깐 뒤에 판단.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted || _shownThisSession) return;
    // 관심지역이 있으면 특보가 정상 노출되므로 안내가 필요 없다.
    if (Get.find<WeatherGogoCntr>().areaList.isNotEmpty) return;
    _shownThisSession = true;
    setState(() => _visible = true);
    // 마퀴가 한 줄 흐를 시간(8초) 뒤 스르륵 사라진다.
    await Future.delayed(const Duration(seconds: 8));
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
        child: GestureDetector(
          onTap: () => Get.toNamed('/FavoriteAreaPage'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.34),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
            // 마퀴(흐르는 한 줄) — 특보는 관심지역 등록 시 받을 수 있음을 안내.
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: TextScroll(
                    '기상특보 알림은 관심지역을 등록하시면 해당 지역만 받아보실 수 있어요.   탭하여 지금 관심지역을 등록해보세요',
                    mode: TextScrollMode.endless,
                    velocity: const Velocity(pixelsPerSecond: Offset(32, 0)),
                    pauseBetween: const Duration(milliseconds: 900),
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
