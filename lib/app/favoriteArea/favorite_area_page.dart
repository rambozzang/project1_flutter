import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_tag_data.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 관심지역 등록 페이지.
/// - 페이지 내 인라인 검색(카카오 키워드, 300ms 디바운스) → 결과에서 바로 [추가]
/// - 검색어가 비면 '나의 관심 지역' 리스트로 복귀
/// - 지역 탭 → 저장된 좌표로 즉시 날씨 조회(과거 데이터처럼 좌표가 없으면 지오코딩 폴백)
class FavoriteAreaPage extends StatefulWidget {
  const FavoriteAreaPage({super.key});

  @override
  State<FavoriteAreaPage> createState() => _FavoriteAreaPageState();
}

/// 등록된 관심지역 한 건. getTagList 응답의 id.tagNm + lat/lon/addr을 담는다.
class _FavoriteAreaItem {
  final String name;
  final String? addr;
  final double? lat;
  final double? lon;
  _FavoriteAreaItem({required this.name, this.addr, this.lat, this.lon});
}

class _FavoriteAreaPageState extends State<FavoriteAreaPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final KakaoRepo _kakaoRepo = KakaoRepo();
  final CustRepo _custRepo = CustRepo();

  // 검색 상태
  Timer? _debounce;
  bool _searching = false;
  List<Map<String, dynamic>> _results = [];

  // 등록된 관심지역
  bool _loadingAreas = true;
  List<_FavoriteAreaItem> _areas = [];
  // 추가/삭제 진행 중인 지역명(중복 탭 방지 + 버튼 스피너)
  final Set<String> _busyNames = {};

  String get _custId => AuthCntr.to.resLoginData.value.custId.toString();

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── 데이터 ──────────────────────────────────────────────

  Future<void> _loadAreas() async {
    try {
      final ResData res = await _custRepo.getTagList(_custId, 'LOCAL');
      if (res.code != '00') {
        if (mounted) setState(() => _loadingAreas = false);
        Utils.alert(res.msg ?? '관심지역을 불러오지 못했습니다.');
        return;
      }
      final list = (res.data as List? ?? [])
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return _FavoriteAreaItem(
              name: m['id']?['tagNm']?.toString() ?? '',
              addr: m['addr']?.toString(),
              lat: double.tryParse(m['lat']?.toString() ?? ''),
              lon: double.tryParse(m['lon']?.toString() ?? ''),
            );
          })
          .where((e) => e.name.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _areas = list;
        _loadingAreas = false;
      });
    } catch (e) {
      lo.g('관심지역 조회 실패: $e');
      if (!mounted) return;
      setState(() => _loadingAreas = false);
      Utils.alert('관심지역을 불러오지 못했습니다.');
    }
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final docs = await _kakaoRepo.getCoordinates(query);
      if (!mounted) return;
      // 디바운스 이후 입력이 또 바뀌었으면 결과 무시
      if (_searchCtrl.text.trim() != query) return;
      setState(() {
        _results = docs;
        _searching = false;
      });
    } catch (e) {
      // KakaoRepo는 결과 0건도 Exception('No results found')으로 던진다 → 빈 결과로 처리
      if (!mounted) return;
      setState(() {
        _results = [];
        _searching = false;
      });
    }
  }

  bool _isRegistered(String name) => _areas.any((a) => a.name == name);

  Future<void> _addArea(Map<String, dynamic> doc) async {
    final String name = (doc['place_name'] ?? doc['address_name'] ?? '').toString();
    if (name.isEmpty || _isRegistered(name) || _busyNames.contains(name)) return;

    setState(() => _busyNames.add(name));
    try {
      final String? road = doc['road_address_name']?.toString();
      final String? addr = (road != null && road.isNotEmpty) ? road : doc['address_name']?.toString();
      final data = CustTagData()
        ..custId = _custId
        ..tagNm = name
        ..tagType = 'LOCAL'
        ..lat = doc['y']?.toString()
        ..lon = doc['x']?.toString()
        ..addr = addr;

      final ResData res = await _custRepo.saveTag(data);
      if (res.code != '00') {
        Utils.alert(res.msg ?? '등록에 실패했습니다.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _areas.insert(
          0,
          _FavoriteAreaItem(
            name: name,
            addr: addr,
            lat: double.tryParse(data.lat ?? ''),
            lon: double.tryParse(data.lon ?? ''),
          ),
        );
      });
      BotToast.showText(text: '[$name] 추가되었습니다.');
    } catch (e) {
      lo.g('관심지역 등록 실패: $e');
      Utils.alert('등록 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _busyNames.remove(name));
    }
  }

  Future<void> _removeArea(_FavoriteAreaItem item) async {
    if (_busyNames.contains(item.name)) return;
    setState(() => _busyNames.add(item.name));
    try {
      final ResData res = await _custRepo.deleteTag(_custId, item.name, 'LOCAL');
      if (res.code != '00') {
        Utils.alert(res.msg ?? '삭제에 실패했습니다.');
        return;
      }
      if (!mounted) return;
      setState(() => _areas.removeWhere((a) => a.name == item.name));
      BotToast.showText(text: '[${item.name}] 삭제되었습니다.');
    } catch (e) {
      lo.g('관심지역 삭제 실패: $e');
      Utils.alert('삭제 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _busyNames.remove(item.name));
    }
  }

  /// 지역 탭 → 날씨 조회. 저장된 좌표를 우선 사용하고, 과거 데이터처럼 좌표가 없으면 지오코딩 폴백.
  Future<void> _openWeather(_FavoriteAreaItem item) async {
    double? lat = item.lat;
    double? lon = item.lon;
    String addr = item.addr ?? '';
    try {
      if (lat == null || lon == null) {
        final docs = await _kakaoRepo.getCoordinates(item.name);
        final doc = docs.isEmpty ? null : docs.first;
        lat = double.tryParse(doc?['y']?.toString() ?? '');
        lon = double.tryParse(doc?['x']?.toString() ?? '');
        addr = doc?['address_name']?.toString() ?? '';
      }
      if (lat == null || lon == null) {
        Utils.alert('[${item.name}] 위치를 찾지 못했습니다.');
        return;
      }
      Get.find<WeatherGogoCntr>().searchWeatherKakao(GeocodeData(name: item.name, latLng: LatLng(lat, lon), addr: addr));
      Get.back();
    } catch (e) {
      lo.g('관심지역 날씨 조회 실패: $e');
      Utils.alert('위치 조회 중 오류가 발생했습니다.');
    }
  }

  // ── UI ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool showSearchResults = _searchCtrl.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '관심지역',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchField(),
            Expanded(
              child: showSearchResults ? _buildSearchResults() : _buildAreaList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        onChanged: (v) {
          _onQueryChanged(v);
          setState(() {}); // 결과/리스트 전환 + clear 버튼 갱신
        },
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: '동네·명소·건물명으로 검색',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600], size: 22),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.cancel, color: Colors.grey[400], size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onQueryChanged('');
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: Colors.grey[100],
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // 검색 결과 리스트: 결과에서 바로 [추가], 이미 등록된 곳은 '등록됨' 표시
  Widget _buildSearchResults() {
    if (_searching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: '검색 결과가 없습니다',
        subtitle: '동/읍/면, 명소, 건물명 등으로\n다시 검색해보세요.',
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final doc = _results[index];
        final String name = (doc['place_name'] ?? doc['address_name'] ?? '').toString();
        final String addr = (doc['road_address_name']?.toString().isNotEmpty == true
                ? doc['road_address_name']
                : doc['address_name'])
            ?.toString() ??
            '';
        final bool registered = _isRegistered(name);
        final bool busy = _busyNames.contains(name);
        return InkWell(
          onTap: registered ? null : () => _addArea(doc),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(Icons.place_outlined, color: Colors.grey[500], size: 20),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black, fontSize: 14.5, fontWeight: FontWeight.w600)),
                      if (addr.isNotEmpty) ...[
                        const Gap(2),
                        Text(addr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const Gap(8),
                _buildAddChip(registered: registered, busy: busy),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddChip({required bool registered, required bool busy}) {
    if (busy) {
      return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (registered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('등록됨', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF4C8DFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text('+ 추가', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  // 나의 관심 지역 리스트: 탭=날씨 조회, 휴지통=삭제
  Widget _buildAreaList() {
    if (_loadingAreas) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_areas.isEmpty) {
      return _buildEmptyState(
        icon: Icons.location_on_outlined,
        title: '아직 등록된 관심지역이 없어요',
        subtitle: '위 검색으로 자주 확인하는 지역을 추가하면\n날씨를 빠르게 볼 수 있어요.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Text('나의 관심 지역',
                  style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700)),
              const Gap(6),
              Text('${_areas.length}', style: const TextStyle(color: Color(0xFF4C8DFF), fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('탭하면 날씨를 볼 수 있어요', style: TextStyle(color: Colors.grey[500], fontSize: 11.5)),
            ],
          ),
        ),
        for (final item in _areas) _buildAreaCard(item),
      ],
    );
  }

  Widget _buildAreaCard(_FavoriteAreaItem item) {
    final bool busy = _busyNames.contains(item.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openWeather(item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C8DFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFF4C8DFF), size: 18),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black, fontSize: 14.5, fontWeight: FontWeight.w600)),
                    if (item.addr != null && item.addr!.isNotEmpty) ...[
                      const Gap(2),
                      Text(item.addr!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ],
                ),
              ),
              busy
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.grey[400], size: 21),
                      onPressed: () {
                        Utils.showConfirmDialog(
                          '삭제 확인',
                          '[${item.name}] 지역을 삭제하시겠습니까?',
                          BackButtonBehavior.none,
                          cancel: () {},
                          confirm: () => _removeArea(item),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Colors.grey[300]),
          const Gap(12),
          Text(title, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
          const Gap(6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12.5, height: 1.4)),
          const Gap(40),
        ],
      ),
    );
  }
}
