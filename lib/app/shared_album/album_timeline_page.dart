import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';

/// 2a · 월별 타임라인(촬영일 자동 정리) — 1d 그리드를 대체하는 앨범 기본 화면.
/// v1: 업로드일(crtDtm) 기준으로 일/월 그룹핑(EXIF capturedAt은 후속). 날씨칩은 기존 저장 데이터 사용.
class AlbumTimelineView extends StatelessWidget {
  const AlbumTimelineView({
    super.key,
    required this.items,
    required this.communityId,
    required this.lastSeen,
    required this.onTapItem,
    this.onLoadMore,
    this.onRefresh,
  });

  final List<BoardWeatherListData> items;
  final int communityId;
  final DateTime? lastSeen;
  final void Function(int index) onTapItem;
  final VoidCallback? onLoadMore;
  // 당겨서 새로고침 — 앨범 피드/메타 다시 로드
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final days = _groupByDay();
    // 빈 상태도 스크롤 가능한 리스트로 감싸 '당겨서 새로고침'이 동작하게 한다.
    final Widget content = days.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.28),
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text('아직 담긴 순간이 없어요.\n＋ 로 첫 사진·영상을 올려보세요.',
                    textAlign: TextAlign.center, style: SaText.body),
              ),
            ],
          )
        : NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (onLoadMore != null &&
                  n.metrics.pixels > n.metrics.maxScrollExtent - 600 &&
                  n.metrics.axisDirection == AxisDirection.down) {
                onLoadMore!();
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: days.length,
              itemBuilder: (context, i) {
                final day = days[i];
                final bool showMonth = i == 0 || days[i - 1].month != day.month;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showMonth)
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 6),
                        child: Text(day.monthLabel,
                            style: SaText.titleM.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    _dayHeader(day),
                    const SizedBox(height: 8),
                    _dayGrid(day),
                    const SizedBox(height: 14),
                  ],
                );
              },
            ),
          );

    if (onRefresh == null) return content;
    return RefreshIndicator(
      color: SaColors.accentTeal,
      onRefresh: onRefresh!,
      child: content,
    );
  }

  Widget _dayHeader(_DayGroup day) {
    return Row(
      children: [
        Text(day.dayLabel, style: SaText.titleS.copyWith(fontSize: 13)),
        const SizedBox(width: 10),
        if (day.weatherText.isNotEmpty) _weatherChip(day),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: SaColors.border)),
      ],
    );
  }

  Widget _weatherChip(_DayGroup day) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: SaColors.isLight ? SaColors.surfaceElevated : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SaColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(_weatherIcon(day.rep), size: 11, color: SaColors.textSecondary),
          const SizedBox(width: 4),
          Text(day.weatherText, style: SaText.mono(fontSize: 10, color: SaColors.textSecondary)),
        ],
      ),
    );
  }

  IconData _weatherIcon(BoardWeatherListData? m) {
    final rain = m?.rain ?? '0';
    if (rain == '1' || rain == '4' || rain == '5') return PhosphorIconsFill.cloudRain;
    if (rain == '2' || rain == '3' || rain == '6' || rain == '7') return PhosphorIconsFill.cloudSnow;
    final sky = m?.sky ?? '1';
    if (sky == '3') return PhosphorIconsFill.cloud;
    if (sky == '4') return PhosphorIconsFill.cloudFog;
    return PhosphorIconsFill.sun;
  }

  Widget _dayGrid(_DayGroup day) {
    final medias = day.items;
    return StaggeredGrid.count(
      crossAxisCount: 3,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (int i = 0; i < medias.length; i++)
          // 그날 첫 항목(하이라이트)은 2×2 span
          StaggeredGridTile.count(
            crossAxisCellCount: i == 0 ? 2 : 1,
            mainAxisCellCount: i == 0 ? 2 : 1,
            child: _tile(medias[i]),
          ),
      ],
    );
  }

  Widget _tile(_TimelineItem ti) {
    final item = ti.item;
    final bool isVideo = item.typeDtCd == 'V';
    final String thumb = _thumbOf(item);
    return GestureDetector(
      onTap: () => onTapItem(ti.feedIndex),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumb.isNotEmpty)
              CachedNetworkImage(
                imageUrl: thumb,
                cacheKey: thumb,
                memCacheWidth: 400,
                fit: BoxFit.cover,
                placeholder: (_, __) => DecoratedBox(
                    decoration: BoxDecoration(gradient: SaWeatherGradients.of(_gradientKey(item)))),
                errorWidget: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(gradient: SaWeatherGradients.of(_gradientKey(item)))),
              )
            else
              DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of(_gradientKey(item)))),

            // 좌상단 NEW 점(안 본 것)
            if (ti.isNew)
              const Positioned(left: 7, top: 7, child: _Dot()),

            // 좌하단 영상 표시
            if (isVideo)
              Positioned(
                left: 7,
                bottom: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.42), borderRadius: BorderRadius.circular(999)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(PhosphorIconsFill.play, size: 9, color: Colors.white),
                    ],
                  ),
                ),
              ),

            // 우하단 댓글 수
            if ((item.replyCnt ?? 0) > 0)
              Positioned(
                right: 7,
                bottom: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.42), borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PhosphorIcon(PhosphorIconsFill.chatCircle, size: 9, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('${item.replyCnt}', style: SaText.mono(fontSize: 9, color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _thumbOf(BoardWeatherListData item) {
    if ((item.thumbnailPath ?? '').isNotEmpty) {
      String t = item.thumbnailPath!;
      if (t.endsWith('thumbnail.gif')) t = t.replaceAll('thumbnail.gif', 'thumbnail.jpg');
      return t;
    }
    if (item.imageUrls?.isNotEmpty ?? false) return item.imageUrls!.first;
    return '';
  }

  String _gradientKey(BoardWeatherListData item) {
    final keys = SaWeatherGradients.keys;
    return keys[(item.boardId ?? communityId) % keys.length];
  }

  // ── 그룹핑 ──────────────────────────────────────────
  List<_DayGroup> _groupByDay() {
    final Map<String, _DayGroup> map = {};
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      // 촬영일(EXIF) 우선, 없으면 업로드일 — "예전 사진 몰아 올려도 찍은 날로 묶임"
      final DateTime? dt = _parse(item.capturedAt) ?? _parse(item.crtDtm);
      if (dt == null) continue;
      final String key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final g = map.putIfAbsent(key, () => _DayGroup(dt));
      g.items.add(_TimelineItem(item, i, _isNew(item)));
    }
    final list = map.values.toList()..sort((a, b) => b.date.compareTo(a.date)); // 최신순
    return list;
  }

  bool _isNew(BoardWeatherListData item) {
    if (lastSeen == null) return false;
    // NEW 판정은 "업로드 시각" 기준(내가 마지막 본 뒤 올라온 것) — 촬영일 아님
    final dt = _parse(item.crtDtm);
    if (dt == null) return false;
    return dt.isAfter(lastSeen!);
  }

  DateTime? _parse(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s.replaceFirst(' ', 'T'));
  }
}

class _TimelineItem {
  _TimelineItem(this.item, this.feedIndex, this.isNew);
  final BoardWeatherListData item;
  final int feedIndex;
  final bool isNew;
}

class _DayGroup {
  _DayGroup(this.date);
  final DateTime date;
  final List<_TimelineItem> items = [];

  int get month => date.year * 100 + date.month;
  BoardWeatherListData? get rep => items.isEmpty ? null : items.first.item;

  String get monthLabel => '${date.year}년 ${date.month}월';

  static const _wd = ['월', '화', '수', '목', '금', '토', '일'];
  String get dayLabel => '${date.month}월 ${date.day}일 ${_wd[date.weekday - 1]}';

  String get weatherText {
    final m = rep;
    if (m == null) return '';
    final desc = (m.weatherInfo ?? '').split('.').first.trim();
    final temp = (m.currentTemp ?? '').trim();
    final parts = [if (desc.isNotEmpty) desc, if (temp.isNotEmpty) '$temp°'];
    return parts.join(' ');
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: SaColorsDark.accentPink,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: SaColorsDark.accentPink.withOpacity(0.5), blurRadius: 5, spreadRadius: 1)],
      ),
    );
  }
}
