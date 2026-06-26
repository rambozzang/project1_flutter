import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/spot/cntr/spot_cntr.dart';
import 'package:project1/app/spot/spot_detail_page.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/spot/data/spot_data.dart';

/// "스팟별 날씨" — 캠핑·낚시·골프 스팟을 현재 날씨와 함께 둘러보고,
/// 스팟을 탭하면 그곳 커뮤니티 영상으로 "지금 거기 어때?"를 확인한다.
/// (백엔드 /api/spot/* 준비 시 자동 연동 — WEATHER_ACTIVATION_API_CONTRACT.md)
class SpotWeatherPage extends StatelessWidget {
  const SpotWeatherPage({super.key});

  static const Color _bg = Color(0xFF11141C);
  static const Color _surface = Color(0xFF1B1F2A);
  static const Color _border = Color(0xFF2A2F3C);
  static const Color _accent = Color(0xFF4A90E2);
  static const Color _textHi = Color(0xFFEDF1F7);
  static const Color _textLo = Color(0xFF98A2B3);

  static const List<({String code, String label, IconData icon})> _cats = [
    (code: 'camping', label: '캠핑', icon: Icons.cabin_rounded),
    (code: 'fishing', label: '낚시', icon: Icons.phishing_rounded),
    (code: 'golf', label: '골프', icon: Icons.golf_course_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final SpotCntr c = Get.put(SpotCntr());
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('스팟별 날씨', style: TextStyle(color: _textHi, fontSize: 18, fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: _textHi, size: 20), onPressed: () => Get.back()),
      ),
      body: Column(
        children: [
          _categoryBar(c),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: _accent));
              }
              if (c.spots.isEmpty) {
                return _emptyState();
              }
              return RefreshIndicator(
                color: _accent,
                onRefresh: c.fetch,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                  itemCount: c.spots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _spotCard(c.spots[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _categoryBar(SpotCntr c) {
    return SizedBox(
      height: 52,
      child: Obx(() {
        // category.value를 동기적으로 읽어야 Obx가 추적한다.
        // (itemBuilder는 지연 호출이라 그 안에서만 읽으면 Obx가 reactive를 감지 못해 오류 발생)
        final selected = c.category.value;
        return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: _cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _cats[i];
              final bool sel = selected == cat.code;
              return GestureDetector(
                onTap: () => c.changeCategory(cat.code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: sel ? _accent : _surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: sel ? _accent : _border),
                  ),
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 16, color: sel ? Colors.white : _textLo),
                      const SizedBox(width: 6),
                      Text(cat.label,
                          style: TextStyle(
                              color: sel ? Colors.white : _textLo, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          );
        }),
    );
  }

  Widget _spotCard(SpotData s) {
    return GestureDetector(
      onTap: () => Get.to(() => SpotDetailPage(spot: s)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // 현재 날씨 아이콘
            SizedBox(
              width: 46,
              height: 46,
              child: WeatherDataProcessor.instance.getWeatherGogoImage(s.sky ?? '1', s.rain ?? '0'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _textHi, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${s.currentTemp ?? '-'}°',
                          style: const TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(s.weatherInfo ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _textLo, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (s.distanceKm != null)
                  Text('${s.distanceKm!.toStringAsFixed(1)}km',
                      style: const TextStyle(color: _textLo, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, size: 13, color: _accent),
                      const SizedBox(width: 4),
                      Text('${s.videoCnt ?? 0}',
                          style: const TextStyle(color: _textHi, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.travel_explore_rounded, size: 56, color: _textLo),
        SizedBox(height: 14),
        Center(
          child: Text('주변 스팟이 아직 없어요',
              style: TextStyle(color: _textLo, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        SizedBox(height: 6),
        Center(
          child: Text('백엔드 스팟 데이터가 준비되면 표시됩니다',
              style: TextStyle(color: Color(0xFF5B6472), fontSize: 12)),
        ),
      ],
    );
  }
}
