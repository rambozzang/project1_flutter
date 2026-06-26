import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';

/// 날씨 페이지 상단 검색 바(경량).
/// 기존 material_floating_search_bar_plus(오버레이/백드롭/애니메이션이 항상 동작 → 렉)
/// 대신, 가벼운 탭 버튼만 두고 실제 검색은 별도 페이지(WeatherSearchPage)에서 처리한다.
/// → 날씨 페이지에는 상시 부하 위젯이 사라져 스크롤/렌더가 가벼워진다.
class WeathergogoKakaoSearchPage extends StatelessWidget {
  const WeathergogoKakaoSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 3, 12, 0),
        child: GestureDetector(
          onTap: () => Get.to(() => const WeatherSearchPage(), transition: Transition.fadeIn, duration: const Duration(milliseconds: 180)),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '국내 지명, 주소를 검색해주세요.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.search, color: primaryBlue, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 전용 검색 페이지 — 가벼운 TextField + ListView 구조.
/// 카카오 지오코딩(디바운스 400ms) → 결과 탭 시 해당 위치 날씨로 갱신 후 닫힘.
class WeatherSearchPage extends StatefulWidget {
  const WeatherSearchPage({super.key});

  @override
  State<WeatherSearchPage> createState() => _WeatherSearchPageState();
}

class _WeatherSearchPageState extends State<WeatherSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final KakaoRepo _kakaoRepo = KakaoRepo();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final data = await _kakaoRepo.getCoordinates(query);
        if (mounted) {
          setState(() {
            _results = data;
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _results = [];
            _loading = false;
          });
        }
      }
    });
  }

  void _select(Map<String, dynamic> data) {
    final geocodeData = GeocodeData(
      name: data['place_name'],
      latLng: LatLng(double.parse(data['y'] ?? '0'), double.parse(data['x'] ?? '0')),
    );
    Get.find<WeatherGogoCntr>().searchWeatherKakao(geocodeData);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          decoration: InputDecoration(
            hintText: '국내 지명, 주소를 검색해주세요.',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.black54),
            onPressed: () {
              _controller.clear();
              _onChanged('');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const SizedBox.shrink()
              : ListView.separated(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(thickness: 1, height: 0),
                  itemBuilder: (context, i) => _buildItem(_results[i]),
                ),
    );
  }

  Widget _buildItem(Map<String, dynamic> data) {
    return InkWell(
      onTap: () => _select(data),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: primaryBlue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['place_name'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  if (data['address_name'] != null)
                    Text(
                      data['address_name'],
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  if (data['road_address_name'] != null)
                    Text(
                      data['road_address_name'],
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
