import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/spot/data/spot_data.dart';
import 'package:project1/repo/spot/spot_repo.dart';

/// 스팟 상세 — 현재 날씨 헤더 + 그 스팟 커뮤니티 영상 썸네일 그리드.
/// 썸네일 탭 → 기존 단일 영상 뷰어(/VideoMyinfoListPage) 재사용.
class SpotDetailPage extends StatefulWidget {
  final SpotData spot;
  const SpotDetailPage({super.key, required this.spot});

  @override
  State<SpotDetailPage> createState() => _SpotDetailPageState();
}

class _SpotDetailPageState extends State<SpotDetailPage> {
  static const Color _bg = Color(0xFF11141C);
  static const Color _surface = Color(0xFF1B1F2A);
  static const Color _accent = Color(0xFF4A90E2);
  static const Color _textHi = Color(0xFFEDF1F7);
  static const Color _textLo = Color(0xFF98A2B3);

  final SpotRepo _repo = SpotRepo();
  final List<BoardWeatherListData> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.getSpotBoard(widget.spot.spotId ?? 0, 0, 30);
    if (mounted) {
      setState(() {
        _videos
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    }
  }

  String _thumb(BoardWeatherListData d) {
    if (d.imageUrls != null && d.imageUrls!.isNotEmpty) return d.imageUrls!.first;
    if (d.thumbnailPath != null && d.thumbnailPath!.isNotEmpty) return d.thumbnailPath!;
    final v = d.videoPath ?? '';
    if (v.contains('/manifest/video.m3u8')) return v.replaceAll('/manifest/video.m3u8', '/thumbnails/thumbnail.jpg');
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spot;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: _textHi, size: 20), onPressed: () => Get.back()),
        title: Text(s.name ?? '스팟', style: const TextStyle(color: _textHi, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _weatherHeader(s),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : _videos.isEmpty
                    ? const Center(
                        child: Text('아직 이 스팟의 영상이 없어요\n첫 영상을 올려보세요!',
                            textAlign: TextAlign.center, style: TextStyle(color: _textLo, fontSize: 14)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: _videos.length,
                        itemBuilder: (_, i) => _videoThumb(_videos[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _weatherHeader(SpotData s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          SizedBox(width: 50, height: 50, child: WeatherDataProcessor.instance.getWeatherGogoImage(s.sky ?? '1', s.rain ?? '0')),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('지금 ${s.name ?? ''}', style: const TextStyle(color: _textLo, fontSize: 12)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${s.currentTemp ?? '-'}°',
                      style: const TextStyle(color: _textHi, fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(s.weatherInfo ?? '',
                        style: const TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (s.distanceKm != null)
            Text('${s.distanceKm!.toStringAsFixed(1)}km',
                style: const TextStyle(color: _textLo, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _videoThumb(BoardWeatherListData d) {
    final url = _thumb(d);
    return GestureDetector(
      onTap: () => Get.toNamed('/VideoMyinfoListPage',
          arguments: {'datatype': 'ONE', 'custId': d.custId.toString(), 'boardId': d.boardId.toString()}),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            url.isEmpty
                ? Container(color: _surface)
                : CachedNetworkImage(
                    imageUrl: url,
                    cacheKey: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: _surface),
                    errorWidget: (_, __, ___) => Container(color: _surface, child: const Icon(Icons.broken_image, color: _textLo, size: 20)),
                  ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 11, color: Colors.white),
                  const SizedBox(width: 2),
                  Text('${d.likeCnt ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 3, color: Colors.black)])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
