import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/spot/spot_submit_page.dart';
import 'package:project1/repo/spot/data/spot_admin_data.dart';
import 'package:project1/repo/spot/spot_repo.dart';

/// 내가 제보한 스팟 목록 (상태: 대기/승인/반려).
class SpotMyPage extends StatefulWidget {
  const SpotMyPage({super.key});

  @override
  State<SpotMyPage> createState() => _SpotMyPageState();
}

class _SpotMyPageState extends State<SpotMyPage> {
  static const Color _accent = Color(0xFF8C83DD);
  final SpotRepo _repo = SpotRepo();
  List<SpotAdminData> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.getMySpots();
    if (mounted) setState(() {
      _list = list;
      _loading = false;
    });
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'APPROVED':
        return const Color(0xFF22A06B);
      case 'REJECTED':
        return const Color(0xFFE5484D);
      default:
        return const Color(0xFFF5A623);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('내 스팟 제보', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Get.back()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        onPressed: () async {
          final r = await Get.to(() => const SpotSubmitPage());
          if (r == true) _load();
        },
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('스팟 제보', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(_list[i]),
                  ),
                ),
    );
  }

  Widget _card(SpotAdminData s) {
    final color = _statusColor(s.status);
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
              Expanded(
                child: Text(s.name ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(s.statusLabel, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F2F4), borderRadius: BorderRadius.circular(6)),
                child: Text(s.categoryLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(s.addr ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0AB)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (s.status == 'REJECTED' && (s.rejectReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE5484D).withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
              child: Text('반려 사유: ${s.rejectReason}', style: const TextStyle(fontSize: 12, color: Color(0xFFE5484D))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_location_alt_outlined, size: 56, color: Color(0xFFCBD0D8)),
          const SizedBox(height: 14),
          const Text('아직 제보한 스팟이 없어요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          const Text('내가 아는 좋은 캠핑·낚시·골프 장소를 제보해보세요', style: TextStyle(fontSize: 13, color: Color(0xFF9AA0AB))),
        ],
      ),
    );
  }
}
