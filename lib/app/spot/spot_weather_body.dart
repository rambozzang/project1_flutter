import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/spot/cntr/spot_cntr.dart';
import 'package:project1/app/spot/spot_detail_page.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/spot/data/spot_data.dart';

/// [SpotWeatherPage]의 본문 위젯.
/// 탭 낭비(AlramPage) 등에서 Scaffold 없이 body만 필요할 때 사용한다.
class SpotWeatherBody extends StatefulWidget {
  /// 탭 낭비(AlramPage) 등에서 사용할 때 탭바 아래로 들어가 보이지 않도록
  /// 상단 여백을 추가할 수 있다.
  final double topPadding;

  const SpotWeatherBody({super.key, this.topPadding = 0});

  @override
  State<SpotWeatherBody> createState() => _SpotWeatherBodyState();
}

class _SpotWeatherBodyState extends State<SpotWeatherBody> {
  // 앱 전체 디자인 톤(흰색 배경 + 밝은 카드)과 통일한다.
  // 액센트는 스팟 기능 전체(목록 FAB·상세 페이지)와 동일한 브랜드 보라로 통일.
  static const Color _bg = Color(0xFFF8F9FB);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE8EAED);
  static const Color _accent = Color(0xFF8C83DD);
  static const Color _textHi = Colors.black;
  static const Color _textLo = Color(0xFF5F6368);

  static const List<({String code, String label, IconData icon})> _cats = [
    (code: 'camping', label: '캠핑', icon: Icons.cabin_rounded),
    (code: 'fishing', label: '낚시', icon: Icons.phishing_rounded),
    (code: 'golf', label: '골프', icon: Icons.golf_course_rounded),
  ];

  late final SpotCntr _c;

  @override
  void initState() {
    super.initState();
    // 탭 내에서 사용할 때는 페이지별 고유 tag로 등록하여 Get.put 중복 충돌을 방지한다.
    _c = Get.put(SpotCntr(), tag: 'spotWeatherTab');
  }

  @override
  void dispose() {
    Get.delete<SpotCntr>(tag: 'spotWeatherTab');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        color: _bg,
        child: Column(
          children: [
            SizedBox(height: widget.topPadding),
            _categoryBar(),
            Expanded(
              child: Obx(() {
                if (_c.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: _accent));
                }
                if (_c.spots.isEmpty) {
                  return _emptyState();
                }
                return RefreshIndicator(
                  color: _accent,
                  onRefresh: _c.fetch,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    itemCount: _c.spots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _spotCard(_c.spots[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 52,
      child: Obx(() {
        final selected = _c.category.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          itemCount: _cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = _cats[i];
            final bool sel = selected == cat.code;
            return GestureDetector(
              onTap: () => _c.changeCategory(cat.code),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
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
    final msg = _c.errorMsg.value ?? '주변 스팟이 아직 없어요';
    final sub = _c.errorMsg.value == null
        ? '백엔드 스팟 데이터가 준비되면 표시됩니다'
        : '아래로 당겨서 다시 시도해 보세요';
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.travel_explore_rounded, size: 56, color: _textLo),
        const SizedBox(height: 14),
        Center(
          child: Text(msg,
              style: const TextStyle(color: _textLo, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(sub,
              style: const TextStyle(color: Color(0xFF5B6472), fontSize: 12)),
        ),
      ],
    );
  }
}
