import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/repo/spot/spot_repo.dart';
import 'package:project1/repo/weather_gogo/adapter/adapter_map.dart';
import 'package:project1/utils/utils.dart';

/// 스팟 제보 화면 (사용자 → 승인대기).
/// 카카오 장소검색으로 위치를 고르고(좌표·주소 자동), 카테고리를 선택해 제보한다.
class SpotSubmitPage extends StatefulWidget {
  const SpotSubmitPage({super.key});

  @override
  State<SpotSubmitPage> createState() => _SpotSubmitPageState();
}

class _SpotSubmitPageState extends State<SpotSubmitPage> {
  static const Color _accent = Color(0xFF8C83DD);
  static const List<(String, String, IconData)> _categories = [
    ('camping', '캠핑', Icons.cabin),
    ('fishing', '낚시', Icons.phishing),
    ('golf', '골프', Icons.golf_course),
  ];

  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final KakaoRepo _kakao = KakaoRepo();
  final SpotRepo _repo = SpotRepo();

  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _submitting = false;

  String _category = 'camping';
  // 선택된 장소
  double? _lat;
  double? _lon;
  String? _addr;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final docs = await _kakao.getCoordinates(q);
      if (mounted) setState(() => _results = docs);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectPlace(Map<String, dynamic> doc) {
    final name = doc['place_name']?.toString() ?? '';
    final addr = (doc['road_address_name']?.toString().isNotEmpty ?? false)
        ? doc['road_address_name'].toString()
        : doc['address_name']?.toString() ?? '';
    final lon = double.tryParse(doc['x']?.toString() ?? '');
    final lat = double.tryParse(doc['y']?.toString() ?? '');
    setState(() {
      _nameCtrl.text = name;
      _addr = addr;
      _lat = lat;
      _lon = lon;
      _results = [];
      _searchCtrl.text = name;
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Utils.alert('스팟 이름을 입력해주세요.');
      return;
    }
    if (_lat == null || _lon == null) {
      Utils.alert('검색해서 위치를 선택해주세요.');
      return;
    }
    setState(() => _submitting = true);
    try {
      // 위경도 → 기상청 격자(nx, ny)
      final grid = MapAdapter.changeMap(_lon!, _lat!);
      final (ok, msg) = await _repo.submitSpot(
        name: name,
        category: _category,
        lat: _lat!,
        lon: _lon!,
        nx: grid.x,
        ny: grid.y,
        addr: _addr,
      );
      Utils.alert(msg.isEmpty ? (ok ? '제보되었습니다.' : '제보에 실패했습니다.') : msg);
      if (ok && mounted) Get.back(result: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _lat != null && _lon != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('스팟 제보', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Get.back()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _label('어떤 종류의 스팟인가요?'),
          const SizedBox(height: 10),
          Row(
            children: _categories.map((c) {
              final on = _category == c.$1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: c == _categories.last ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _category = c.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: on ? _accent : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: on ? _accent : const Color(0xFFE3E5EA)),
                      ),
                      child: Column(
                        children: [
                          Icon(c.$3, color: on ? Colors.white : const Color(0xFF9AA0AB), size: 26),
                          const SizedBox(height: 6),
                          Text(c.$2,
                              style: TextStyle(
                                  color: on ? Colors.white : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
          _label('위치를 검색해주세요'),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '장소명·주소 검색 (예: 자라섬 캠핑장)',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA0AB)),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE3E5EA))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _accent, width: 1.5)),
            ),
          ),
          // 검색 결과
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE3E5EA)),
              ),
              child: Column(
                children: _results.take(8).map((doc) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, color: _accent, size: 20),
                    title: Text(doc['place_name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        (doc['road_address_name']?.toString().isNotEmpty ?? false)
                            ? doc['road_address_name'].toString()
                            : doc['address_name']?.toString() ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0AB))),
                    onTap: () => _selectPlace(doc),
                  );
                }).toList(),
              ),
            ),
          ],
          // 선택 확인 카드
          if (selected) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nameCtrl.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(_addr ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        Text('좌표 ${_lat!.toStringAsFixed(4)}, ${_lon!.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0AB))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _label('스팟 이름 (수정 가능)'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: '스팟 이름',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE3E5EA))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _accent, width: 1.5)),
              ),
            ),
          ],
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_submitting || !selected) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              disabledBackgroundColor: const Color(0xFFCBD0D8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('제보하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF374151)));
}
