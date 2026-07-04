import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:share_plus/share_plus.dart';

/// 2c · 회고 — 앨범 미디어를 날씨/기간 테마로 자동 큐레이션한 컬렉션.
/// v1: 서버 mp4 렌더링 없이 클라이언트에서 묶어 몰입뷰로 순차 감상(진짜 몽타주 렌더링은 후속).
class RecapView extends StatelessWidget {
  const RecapView({
    super.key,
    required this.items,
    required this.communityId,
    required this.albumName,
    required this.onPlay,
  });

  final List<BoardWeatherListData> items;
  final int communityId;
  final String albumName;
  final void Function(List<BoardWeatherListData> collection, int index) onPlay;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('회고를 만들 미디어가 아직 없어요.\n사진·영상이 쌓이면 자동으로 모아드려요.',
              textAlign: TextAlign.center, style: SaText.body),
        ),
      );
    }

    final hero = _thisWeek();
    final themes = _themes();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text('회고', style: SaText.titleL.copyWith(fontSize: 26)),
        ),
        Text('우리 앨범이 모은 추억', style: SaText.caption),
        const SizedBox(height: 18),
        _heroCard(context, hero),
        const SizedBox(height: 22),
        for (final t in themes) ...[
          _themeCard(context, t),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  // ── 히어로: 이번 주(최근 7일), 없으면 최근 전체 ──
  _Recap _thisWeek() {
    final now = DateTime.now();
    final within = items.where((e) {
      final dt = DateTime.tryParse((e.crtDtm ?? '').replaceFirst(' ', 'T'));
      return dt != null && now.difference(dt).inDays < 7;
    }).toList();
    final list = within.length >= 2 ? within : items.take(30).toList();
    final label = within.length >= 2 ? '이번 주 하이라이트' : '${albumName}의 순간들';
    return _Recap('hero', label, list);
  }

  // ── 날씨 테마별 자동 큐레이션(3장 이상만) ──
  List<_Recap> _themes() {
    final Map<String, List<BoardWeatherListData>> buckets = {};
    for (final e in items) {
      final key = _bucketOf(e);
      if (key == null) continue;
      buckets.putIfAbsent(key, () => []).add(e);
    }
    const order = ['rain', 'snow', 'sunset', 'clear', 'cloudy'];
    const meta = {
      'rain': ('장마 다이제스트 ☔', 'night'),
      'snow': ('첫눈 모음 ❄️', 'snow'),
      'sunset': ('노을 베스트 🌆', 'sunset'),
      'clear': ('맑은 날 모음 ☀️', 'golden'),
      'cloudy': ('흐린 날의 기록 ☁️', 'fog'),
    };
    final List<_Recap> out = [];
    for (final k in order) {
      final list = buckets[k];
      if (list == null || list.length < 3) continue;
      final m = meta[k]!;
      out.add(_Recap(k, m.$1, list, gradientKey: m.$2));
    }
    return out;
  }

  String? _bucketOf(BoardWeatherListData e) {
    final rain = e.rain ?? '0';
    if (['1', '4', '5'].contains(rain)) return 'rain';
    if (['2', '3', '6', '7'].contains(rain)) return 'snow';
    final info = e.weatherInfo ?? '';
    if (info.contains('비')) return 'rain';
    if (info.contains('눈')) return 'snow';
    final sky = e.sky ?? '1';
    if (sky == '4') return 'cloudy';
    if (sky == '3') return 'cloudy';
    // 맑음 — 저녁(17~20시)이면 노을
    final dt = DateTime.tryParse((e.crtDtm ?? '').replaceFirst(' ', 'T'));
    if (dt != null && dt.hour >= 17 && dt.hour <= 20) return 'sunset';
    return 'clear';
  }

  String _thumb(BoardWeatherListData e) {
    if ((e.thumbnailPath ?? '').isNotEmpty) {
      String t = e.thumbnailPath!;
      if (t.endsWith('thumbnail.gif')) t = t.replaceAll('thumbnail.gif', 'thumbnail.jpg');
      return t;
    }
    if (e.imageUrls?.isNotEmpty ?? false) return e.imageUrls!.first;
    return '';
  }

  // ── 히어로 카드 ──
  Widget _heroCard(BuildContext context, _Recap r) {
    final cover = r.items.isNotEmpty ? _thumb(r.items.first) : '';
    return GestureDetector(
      onTap: () => onPlay(r.items, 0),
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          gradient: SaWeatherGradients.of('aurora'),
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover.isNotEmpty) CachedNetworkImage(imageUrl: cover, memCacheWidth: 800, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x55000000), Color(0xAA000000)],
                ),
              ),
            ),
            // "이번 주 완성" 뱃지
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: SaColorsDark.accentPink, borderRadius: BorderRadius.circular(999)),
                child: Text('이번 주 완성', style: SaText.mono(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
            // 중앙 play
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.6))),
                child: const Icon(Icons.play_arrow_rounded, size: 38, color: Colors.white),
              ),
            ),
            // 하단 타이틀
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, style: SaText.titleM.copyWith(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('${_countLabel(r)} · 자동 큐레이션',
                      style: SaText.mono(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 테마 카드: 몽타주 스트립 + 정보 + 공유 ──
  Widget _themeCard(BuildContext context, _Recap r) {
    final frames = r.items.map(_thumb).where((t) => t.isNotEmpty).take(4).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SaColors.border),
      ),
      child: Row(
        children: [
          // 몽타주 스트립(4프레임)
          GestureDetector(
            onTap: () => onPlay(r.items, 0),
            child: SizedBox(
              width: 108,
              height: 74,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        for (int i = 0; i < 4; i++)
                          Expanded(
                            child: i < frames.length
                                ? CachedNetworkImage(imageUrl: frames[i], fit: BoxFit.cover, height: 74)
                                : DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of(r.gradientKey ?? 'night'))),
                          ),
                      ],
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SaText.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(_countLabel(r), style: SaText.mono(fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Share.share("'$albumName' 앨범의 ${r.title} — SkySnap 공유앨범에서 함께 봐요"),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: SaColors.accentTeal.withOpacity(0.14), shape: BoxShape.circle),
              child: PhosphorIcon(PhosphorIconsFill.shareFat, size: 15, color: SaColors.accentTeal),
            ),
          ),
        ],
      ),
    );
  }

  String _countLabel(_Recap r) {
    final v = r.items.where((e) => e.typeDtCd == 'V').length;
    final p = r.items.length - v;
    final parts = [if (v > 0) '영상 $v', if (p > 0) '사진 $p'];
    return parts.isEmpty ? '${r.items.length}개' : parts.join(' · ');
  }
}

class _Recap {
  _Recap(this.key, this.title, this.items, {this.gradientKey});
  final String key;
  final String title;
  final List<BoardWeatherListData> items;
  final String? gradientKey;
}
