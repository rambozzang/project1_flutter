import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_tag_data.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

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
          onTap: () => Get.to(() => const WeatherSearchPage(),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 180)),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
              ],
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
  final CustRepo _custRepo = CustRepo();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  final Set<String> _registeredNames = {};
  final Set<String> _sessionAddedNames = {};
  final Set<String> _busyNames = {};
  bool _loading = false;

  String get _custId => AuthCntr.to.resLoginData.value.custId.toString();

  @override
  void initState() {
    super.initState();
    _seedRegisteredAreas();
    unawaited(_loadRegisteredAreas());
  }

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
      final normalizedQuery = query.trim();
      try {
        final data = await _kakaoRepo.getCoordinates(normalizedQuery);
        if (mounted && _controller.text.trim() == normalizedQuery) {
          setState(() {
            _results = data;
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted && _controller.text.trim() == normalizedQuery) {
          setState(() {
            _results = [];
            _loading = false;
          });
        }
      }
    });
  }

  void _select(Map<String, dynamic> data) {
    final name = _placeName(data);
    final geocodeData = GeocodeData(
      name: name,
      latLng: LatLng(
          double.parse(data['y'] ?? '0'), double.parse(data['x'] ?? '0')),
      addr: _address(data),
    );
    Get.find<WeatherGogoCntr>().searchWeatherKakao(geocodeData);
    Get.back();
  }

  void _seedRegisteredAreas() {
    if (!Get.isRegistered<WeatherGogoCntr>()) return;
    _registeredNames.addAll(
      Get.find<WeatherGogoCntr>()
          .areaList
          .map((item) => item.id?.tagNm ?? '')
          .where((name) => name.isNotEmpty),
    );
  }

  Future<void> _loadRegisteredAreas() async {
    try {
      final ResData res = await _custRepo.getTagList(_custId, 'LOCAL');
      if (res.code != '00') {
        lo.g('날씨 검색 관심지역 조회 실패: ${res.msg}');
        return;
      }
      final names = (res.data as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map((item) => item['id']?['tagNm']?.toString() ?? '')
          .where((name) => name.isNotEmpty);
      if (!mounted) {
        return;
      }
      setState(() {
        _registeredNames
          ..clear()
          ..addAll(names)
          // 초기 목록 조회보다 등록 요청이 먼저 끝난 경우에도 완료 상태를 보존한다.
          ..addAll(_sessionAddedNames);
      });
    } catch (e) {
      lo.g('날씨 검색 관심지역 조회 오류: $e');
    }
  }

  Future<void> _addFavorite(Map<String, dynamic> data) async {
    final name = _placeName(data);
    if (name.isEmpty ||
        _registeredNames.contains(name) ||
        _busyNames.contains(name)) {
      return;
    }

    setState(() => _busyNames.add(name));
    try {
      final favorite = CustTagData()
        ..custId = _custId
        ..tagNm = name
        ..tagType = 'LOCAL'
        ..lat = data['y']?.toString()
        ..lon = data['x']?.toString()
        ..addr = _address(data);
      final ResData res = await _custRepo.saveTag(favorite);
      if (res.code != '00') {
        Utils.alert(res.msg ?? '관심지역 등록에 실패했습니다.');
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _sessionAddedNames.add(name);
        _registeredNames.add(name);
      });
      if (Get.isRegistered<WeatherGogoCntr>()) {
        unawaited(Get.find<WeatherGogoCntr>().getLocalTag());
      }
      BotToast.showText(text: '[$name] 관심지역으로 등록했습니다.');
    } catch (e) {
      lo.g('날씨 검색 관심지역 등록 오류: $e');
      Utils.alert('관심지역 등록 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _busyNames.remove(name));
    }
  }

  String _placeName(Map<String, dynamic> data) =>
      (data['place_name'] ?? data['address_name'] ?? '').toString();

  String _address(Map<String, dynamic> data) {
    final roadAddress = data['road_address_name']?.toString() ?? '';
    return roadAddress.isNotEmpty
        ? roadAddress
        : (data['address_name']?.toString() ?? '');
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
          icon:
              const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) =>
                      const Divider(thickness: 1, height: 0),
                  itemBuilder: (context, i) => _buildItem(_results[i]),
                ),
    );
  }

  Widget _buildItem(Map<String, dynamic> data) {
    final name = _placeName(data);
    final registered = _registeredNames.contains(name);
    final busy = _busyNames.contains(name);
    return InkWell(
      onTap: () => _select(data),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: primaryBlue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  if (data['address_name'] != null)
                    Text(
                      data['address_name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  if (data['road_address_name'] != null)
                    Text(
                      data['road_address_name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildFavoriteButton(
              registered: registered,
              busy: busy,
              onPressed: () => _addFavorite(data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton({
    required bool registered,
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: busy
          ? '관심지역 등록 중'
          : registered
              ? '관심지역 등록 완료'
              : '관심지역으로 등록',
      child: SizedBox(
        width: 104,
        height: 44,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: busy
              ? const Row(
                  key: ValueKey('busy'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primaryBlue),
                    ),
                    SizedBox(width: 6),
                    Text('등록 중',
                        style: TextStyle(
                            color: Color(0xFF77718E),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                )
              : registered
                  ? TextButton.icon(
                      key: const ValueKey('registered'),
                      onPressed: null,
                      style: TextButton.styleFrom(
                        disabledForegroundColor: const Color(0xFF77718E),
                        backgroundColor: const Color(0xFFF0EEF8),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('등록 완료',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    )
                  : TextButton(
                      key: const ValueKey('add'),
                      onPressed: onPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('관심지역 등록',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
        ),
      ),
    );
  }
}
