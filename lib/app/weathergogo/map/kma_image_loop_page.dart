import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/repo/weather_gogo/sources/weather_map_api.dart';

/// 기상청 레이더·위성 영상을 **그림으로 받아 시간순으로 넘겨 보는** 화면.
///
/// ## 웹뷰를 대신한다
/// 예전에는 RainViewer·Zoom Earth 사이트를 통째로 웹뷰에 띄웠다. 운영에서도 느렸는데
/// (크로미움 기동 + 남의 사이트 스크립트), 여기서는 기상청이 만든 영상 그림만 받는다.
///
/// ## 지도 위에 겹치지 않는 이유
/// 공공데이터포털이 주는 영상은 바탕 지도·범례가 이미 박힌 완성 그림이다. 네이버처럼
/// 투명하게 손질된 그림이 아니라서 우리 지도 위에 얹으면 지도가 두 겹이 된다.
///
/// ## 아직 열리지 않았으면 예전 화면으로
/// 기상청 서비스는 활용 신청이 승인돼야 열린다. 그 전에는 [fallback] (기존 웹뷰)으로
/// 바로 넘긴다 — 사용자는 차이를 모른 채 지금처럼 본다.
class KmaImageLoopPage extends StatefulWidget {
  const KmaImageLoopPage({super.key, required this.radar, required this.fallback});

  /// true 면 레이더, false 면 위성.
  final bool radar;

  /// 기상청 영상을 못 받을 때 대신 띄울 화면.
  final Widget Function() fallback;

  static void open({required bool radar, required Widget Function() fallback}) => Get.to(
        () => KmaImageLoopPage(radar: radar, fallback: fallback),
        transition: Transition.cupertino,
      );

  @override
  State<KmaImageLoopPage> createState() => _KmaImageLoopPageState();
}

class _KmaImageLoopPageState extends State<KmaImageLoopPage> {
  final WeatherMapApi _api = WeatherMapApi();

  /// 하루치를 다 넘기면 너무 길다. 최근 이만큼만 돌린다(레이더 10분·위성 10분 간격 → 약 2시간).
  static const int _recent = 13;

  List<String> _images = const [];
  int _index = 0;
  bool _playing = true;
  bool _loading = true;
  String _band = 'ir105';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = widget.radar ? await _api.radar() : await _api.satellite(band: _band);
    if (!mounted) return;
    final all = (res['images'] is List) ? (res['images'] as List).map((e) => '$e').toList() : <String>[];
    if (all.isEmpty) {
      // 서비스 미승인·오늘 자료 없음 — 예전 화면으로 갈아끼운다.
      Get.off(widget.fallback, transition: Transition.noTransition);
      return;
    }
    // 레이더는 5분, 위성은 2분 간격으로 하루치가 온다. 최근 13장만 잘라 돌리면 30분도
    // 안 돼 움직임이 거의 안 보인다. 10분 간격으로 건너뛰어 약 2시간을 돌린다.
    final step = widget.radar ? 2 : 5;
    final picked = <String>[];
    for (var i = all.length - 1; i >= 0 && picked.length < _recent; i -= step) {
      picked.insert(0, all[i]);
    }
    final recent = picked;
    // 그림을 미리 받아 둬야 재생할 때 깜빡이지 않는다.
    for (final u in recent) {
      unawaited(precacheImage(CachedNetworkImageProvider(u), context).catchError((_) {}));
    }
    setState(() {
      _images = recent;
      _index = recent.length - 1;
      _loading = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_playing || _images.length < 2) return;
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _images.length);
    });
  }

  /// 기상청 영상 파일 이름의 yyyyMMddHHmm 을 한국 시각 "15:30" 으로.
  ///
  /// ⚠️ 레이더 파일은 한국 시각, **위성(gk2a) 파일은 세계 표준시**다. 그대로 적으면 위성이
  /// 9시간 전 그림처럼 보인다(2026-10-13: 20:40 최신 그림이 "11:40" 으로 찍힘).
  String _timeOf(String url) {
    final m = RegExp(r'(\d{12})').allMatches(url).toList();
    if (m.isEmpty) return '';
    final t = m.last.group(1)!;
    var d = DateTime(int.parse(t.substring(0, 4)), int.parse(t.substring(4, 6)), int.parse(t.substring(6, 8)),
        int.parse(t.substring(8, 10)), int.parse(t.substring(10, 12)));
    if (url.contains('gk2a')) d = d.add(const Duration(hours: 9));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.radar ? '실시간 레이더' : '실시간 위성영상';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                if (!widget.radar) _bandChips(),
                Expanded(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: _images[_index],
                        fit: BoxFit.contain,
                        // 다음 그림이 오기 전까지 앞 그림을 그대로 둔다(검은 깜빡임 방지).
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        useOldImageOnUrlChange: true,
                      ),
                    ),
                  ),
                ),
                SafeArea(top: false, child: _controls()),
              ],
            ),
    );
  }

  Widget _bandChips() {
    const bands = [('ir105', '적외(밤낮)'), ('vi006', '가시(낮)'), ('rgbt', '컬러')];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Row(
        children: [
          for (final (code, label) in bands) ...[
            ChoiceChip(
              label: Text(label),
              selected: _band == code,
              onSelected: (_) {
                if (_band == code) return;
                _band = code;
                _timer?.cancel();
                _load();
              },
            ),
            const Gap(6),
          ],
        ],
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() => _playing = !_playing);
              _playing ? _startTimer() : _timer?.cancel();
            },
            icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 30),
          ),
          Expanded(
            child: Slider(
              value: _index.toDouble(),
              min: 0,
              max: (_images.length - 1).toDouble(),
              divisions: _images.length > 1 ? _images.length - 1 : null,
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              onChanged: (v) {
                _timer?.cancel();
                setState(() {
                  _playing = false;
                  _index = v.round();
                });
              },
            ),
          ),
          Text(
            '${_index == _images.length - 1 ? '최신 ' : ''}${_timeOf(_images[_index])}',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
