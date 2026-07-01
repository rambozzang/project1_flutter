import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/utils/utils.dart';

/// 앨범 생성. (대표사진 업로드는 이후 확장)
/// Spot 상세("이 장소로 앨범 만들기")에서 arguments로 spotId/장소명/lat/lon을 넘기면 prefill.
class CommunityCreatePage extends StatefulWidget {
  const CommunityCreatePage({super.key});

  @override
  State<CommunityCreatePage> createState() => _CommunityCreatePageState();
}

class _CommunityCreatePageState extends State<CommunityCreatePage> {
  final CommunityRepo _repo = CommunityRepo();
  final KakaoRepo _kakao = KakaoRepo();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _spotSearchCtrl = TextEditingController();

  bool _isPublic = true;
  String _joinType = 'AUTO';
  bool _saving = false;

  // 장소 연결(선택)
  Timer? _debounce;
  List<Map<String, dynamic>> _spotResults = [];
  bool _spotSearching = false;
  int? _spotId; // Spot 상세에서 넘어온 경우만 채워짐(기존 등록 스팟)
  String? _spotName;
  double? _spotLat;
  double? _spotLon;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      final spotId = args['spotId'];
      if (spotId != null) {
        _spotId = spotId is int ? spotId : int.tryParse(spotId.toString());
      }
      _spotName = args['spotName']?.toString();
      final lat = args['lat'];
      final lon = args['lon'];
      _spotLat = lat is double ? lat : double.tryParse(lat?.toString() ?? '');
      _spotLon = lon is double ? lon : double.tryParse(lon?.toString() ?? '');
      if (_spotName != null && _spotName!.isNotEmpty) {
        _spotSearchCtrl.text = _spotName!;
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _spotSearchCtrl.dispose();
    super.dispose();
  }

  void _onSpotSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _spotResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _searchSpot(q.trim()));
  }

  Future<void> _searchSpot(String q) async {
    setState(() => _spotSearching = true);
    try {
      final docs = await _kakao.getCoordinates(q);
      if (mounted) setState(() => _spotResults = docs);
    } catch (_) {
      if (mounted) setState(() => _spotResults = []);
    } finally {
      if (mounted) setState(() => _spotSearching = false);
    }
  }

  void _selectSpot(Map<String, dynamic> doc) {
    final name = doc['place_name']?.toString() ?? '';
    final lon = double.tryParse(doc['x']?.toString() ?? '');
    final lat = double.tryParse(doc['y']?.toString() ?? '');
    setState(() {
      _spotName = name;
      _spotLat = lat;
      _spotLon = lon;
      _spotId = null; // 새로 검색한 장소는 기존 Spot 레코드와 무관 (좌표만 앨범에 저장)
      _spotResults = [];
      _spotSearchCtrl.text = name;
      FocusScope.of(context).unfocus();
    });
  }

  void _clearSpot() {
    setState(() {
      _spotId = null;
      _spotName = null;
      _spotLat = null;
      _spotLon = null;
      _spotSearchCtrl.clear();
      _spotResults = [];
    });
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Utils.alert('앨범 이름을 입력해주세요.');
      return;
    }
    setState(() => _saving = true);
    final (ok, msg, _) = await _repo.create(
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isPublic: _isPublic ? 'Y' : 'N',
      joinType: _joinType,
      spotId: _spotId,
      lat: _spotLat,
      lon: _spotLon,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Utils.alert(msg.isEmpty ? (ok ? '앨범이 생성되었습니다.' : '생성에 실패했습니다.') : msg);
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final spotSelected = _spotLat != null && _spotLon != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('앨범 만들기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _label('앨범 이름'),
          const SizedBox(height: 6),
          _input(_nameCtrl, '예: 노을 사진 앨범', maxLength: 30),
          const SizedBox(height: 20),
          _label('소개'),
          const SizedBox(height: 6),
          _input(_descCtrl, '어떤 앨범인지 소개해주세요.', maxLines: 4, maxLength: 200),
          const SizedBox(height: 20),
          _label('장소 연결 (선택)'),
          const SizedBox(height: 6),
          _input(_spotSearchCtrl, '장소명·주소 검색 (예: 자라섬 캠핑장)', onChanged: _onSpotSearchChanged, searching: _spotSearching),
          if (_spotResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6E8EF)),
              ),
              child: Column(
                children: _spotResults.take(8).map((doc) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, color: Color(0xFF3B6FE0), size: 20),
                    title: Text(doc['place_name']?.toString() ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        (doc['road_address_name']?.toString().isNotEmpty ?? false)
                            ? doc['road_address_name'].toString()
                            : doc['address_name']?.toString() ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0AB))),
                    onTap: () => _selectSpot(doc),
                  );
                }).toList(),
              ),
            ),
          ],
          if (spotSelected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B6FE0).withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3B6FE0).withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF3B6FE0), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_spotName ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF9AA0AB)),
                    onPressed: _clearSpot,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _card(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isPublic,
              activeColor: const Color(0xFF3B6FE0),
              title: Text(_isPublic ? '공개 앨범' : '비공개 앨범', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              subtitle: Text(
                _isPublic ? '누구나 검색·가입하고 게시물을 볼 수 있어요.' : '멤버만 게시물을 볼 수 있어요.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A8291)),
              ),
              onChanged: (v) => setState(() => _isPublic = v),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('가입 방식', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _joinChip('바로 가입', 'AUTO'),
                    const SizedBox(width: 8),
                    _joinChip('승인 후 가입', 'APPROVAL'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6FE0),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('앨범 만들기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14));

  Widget _input(TextEditingController c, String hint,
      {int maxLines = 1, int? maxLength, ValueChanged<String>? onChanged, bool searching = false}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: searching
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E8EF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E8EF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B6FE0), width: 1.5)),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6E8EF))),
      child: child,
    );
  }

  Widget _joinChip(String label, String value) {
    final selected = _joinType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _joinType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3B6FE0) : const Color(0xFFF1F3F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? const Color(0xFF3B6FE0) : const Color(0xFFE6E8EF)),
          ),
          child: Text(label,
              style: TextStyle(color: selected ? Colors.white : const Color(0xFF7A8291), fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}
