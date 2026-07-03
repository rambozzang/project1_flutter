import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/root/cntr/root_cntr.dart';

/// 지도 상단 검색바 — 경량 커스텀(기존 material_floating_search_bar_plus 대체).
/// 흰 pill + 결과는 바로 아래 리스트로 표시. 카카오 지오코딩(2글자+·디바운스·순서보정).
class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key, required this.onSelectClick});
  final Function(GeocodeData) onSelectClick;

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  final KakaoRepo _kakaoRepo = KakaoRepo();
  Timer? _debounce;
  String _lastQuery = '';
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // 검색 중엔 루트 하단바 숨김(기존 동작 유지)
      RootCntr.to.bottomBarStreamController.sink.add(!_focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    setState(() {}); // clear 아이콘 토글
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q.trim()));
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      if (mounted) setState(() => _results = []);
      return;
    }
    _lastQuery = query;
    try {
      final data = await _kakaoRepo.getCoordinates(query);
      if (!mounted || query != _lastQuery) return; // 더 최신 검색이 시작됨 → 무시
      setState(() => _results = data);
    } catch (_) {
      // KakaoRepo는 결과 0건도 Exception → 빈 리스트로 처리
      if (!mounted || query != _lastQuery) return;
      setState(() => _results = []);
    }
  }

  void _select(Map<String, dynamic> d) {
    final g = GeocodeData(
      name: d['place_name'],
      addr: d['address_name'],
      latLng: LatLng(double.parse(d['y'] ?? '0.0'), double.parse(d['x'] ?? '0.0')),
    );
    _ctrl.text = d['place_name'] ?? '';
    _focus.unfocus();
    setState(() => _results = []);
    widget.onSelectClick(g);
  }

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top + 10;
    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 검색 pill
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(14),
            shadowColor: Colors.black26,
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 2, right: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (q) => _search(q.trim()),
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: '장소·주소 검색',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  _ctrl.text.isEmpty
                      ? const Icon(Icons.search_rounded, color: Colors.black45)
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Colors.black45),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _results = []);
                          },
                        ),
                ],
              ),
            ),
          ),
          // 검색 결과
          if (_results.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F3)),
                itemBuilder: (context, i) {
                  final d = _results[i];
                  final road = (d['road_address_name'] ?? '').toString();
                  return InkWell(
                    onTap: () => _select(d),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: primaryBlue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['place_name'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                                Text(road.isNotEmpty ? road : (d['address_name'] ?? ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
