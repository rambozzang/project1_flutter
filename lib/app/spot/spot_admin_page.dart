import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/spot/data/spot_admin_data.dart';
import 'package:project1/repo/spot/spot_repo.dart';
import 'package:project1/utils/utils.dart';

/// 운영자 전용: 사용자가 제보한 스팟 승인/반려 화면.
class SpotAdminPage extends StatefulWidget {
  const SpotAdminPage({super.key});

  @override
  State<SpotAdminPage> createState() => _SpotAdminPageState();
}

class _SpotAdminPageState extends State<SpotAdminPage> {
  static const Color _accent = Color(0xFF8C83DD);
  final SpotRepo _repo = SpotRepo();
  List<SpotAdminData> _list = [];
  bool _loading = true;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.getPendingSpots();
    if (mounted) setState(() {
      _list = list;
      _loading = false;
    });
  }

  Future<void> _approve(SpotAdminData s) async {
    if (s.spotId == null) return;
    setState(() => _busy.add(s.spotId!));
    final ok = await _repo.approveSpot(s.spotId!);
    Utils.alert(ok ? '승인되었습니다.' : '승인에 실패했습니다.');
    if (ok) {
      if (mounted) setState(() => _list.removeWhere((e) => e.spotId == s.spotId));
    }
    if (mounted) setState(() => _busy.remove(s.spotId));
  }

  Future<void> _reject(SpotAdminData s) async {
    if (s.spotId == null) return;
    final reason = await _askReason();
    if (reason == null) return; // 취소
    setState(() => _busy.add(s.spotId!));
    final ok = await _repo.rejectSpot(s.spotId!, reason);
    Utils.alert(ok ? '반려되었습니다.' : '반려에 실패했습니다.');
    if (ok) {
      if (mounted) setState(() => _list.removeWhere((e) => e.spotId == s.spotId));
    }
    if (mounted) setState(() => _busy.remove(s.spotId));
  }

  Future<String?> _askReason() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('반려 사유', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '제보자에게 보여질 반려 사유를 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Color(0xFF9AA0AB)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5484D)),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? '부적합' : ctrl.text.trim()),
            child: const Text('반려', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text('스팟 승인 관리', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            if (!_loading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text('${_list.length}', style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Get.back()),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 56, color: Color(0xFFCBD0D8)),
                      SizedBox(height: 14),
                      Text('승인 대기 중인 제보가 없어요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(_list[i]),
                  ),
                ),
    );
  }

  Widget _card(SpotAdminData s) {
    final busy = _busy.contains(s.spotId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F2F4), borderRadius: BorderRadius.circular(6)),
                child: Text(s.categoryLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(s.crtDtm ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF9AA0AB))),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.name ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(s.addr ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0AB))),
          const SizedBox(height: 2),
          Text('좌표 ${s.lat?.toStringAsFixed(4) ?? '-'}, ${s.lon?.toStringAsFixed(4) ?? '-'}  ·  제보자 ${_shortId(s.crtCustId)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFB6BBC4))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => _reject(s),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5484D)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('반려', style: TextStyle(color: Color(0xFFE5484D), fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : () => _approve(s),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22A06B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('승인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortId(String? id) {
    if (id == null || id.isEmpty) return '-';
    return id.length <= 8 ? id : '${id.substring(0, 8)}…';
  }
}
