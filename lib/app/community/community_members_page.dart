import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_member_data.dart';
import 'package:project1/utils/utils.dart';

/// 모임 멤버 목록 + (방장/매니저) 가입 승인 관리.
class CommunityMembersPage extends StatefulWidget {
  const CommunityMembersPage({super.key});

  @override
  State<CommunityMembersPage> createState() => _CommunityMembersPageState();
}

class _CommunityMembersPageState extends State<CommunityMembersPage> {
  final CommunityRepo _repo = CommunityRepo();

  late final int _communityId;
  late final bool _isOwner;
  late final bool _isApproval;

  List<CommunityMemberData> _members = [];
  List<CommunityMemberData> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments ?? {};
    _communityId = (args['communityId'] as num).toInt();
    _isOwner = args['isOwner'] == true;
    _isApproval = args['isApproval'] == true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final members = await _repo.getMembers(_communityId);
    List<CommunityMemberData> pending = [];
    if (_isOwner && _isApproval) {
      pending = await _repo.getPendingMembers(_communityId);
    }
    if (!mounted) return;
    setState(() {
      _members = members;
      _pending = pending;
      _loading = false;
    });
  }

  Future<void> _approve(CommunityMemberData m) async {
    final (ok, msg) = await _repo.approve(_communityId, m.custId);
    Utils.alert(msg.isEmpty ? (ok ? '승인했습니다.' : '실패했습니다.') : msg);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        forceMaterialTransparency: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('멤버', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                children: [
                  if (_pending.isNotEmpty) ...[
                    _sectionTitle('가입 승인 대기 ${_pending.length}'),
                    const SizedBox(height: 8),
                    ..._pending.map((m) => _memberTile(m, pending: true)),
                    const SizedBox(height: 22),
                  ],
                  _sectionTitle('멤버 ${_members.length}'),
                  const SizedBox(height: 8),
                  if (_members.isEmpty)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('멤버가 없습니다.', style: TextStyle(color: Color(0xFF7A8291)))))
                  else
                    ..._members.map((m) => _memberTile(m)),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _memberTile(CommunityMemberData m, {bool pending = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFECEEF3))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE6E8EF),
            backgroundImage: (m.profilePath != null && m.profilePath!.isNotEmpty) ? CachedNetworkImageProvider(m.profilePath!) : null,
            child: (m.profilePath == null || m.profilePath!.isEmpty)
                ? Text((m.nickNm ?? m.custId).characters.first, style: const TextStyle(color: Color(0xFF7A8291), fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(m.nickNm ?? m.custId, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                    if (m.isOwner) ...[const SizedBox(width: 6), _roleTag('방장', const Color(0xFFEC8B00))],
                    if (m.role == 'MANAGER') ...[const SizedBox(width: 6), _roleTag('매니저', const Color(0xFF3B6FE0))],
                  ],
                ),
                if (m.joinedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('${m.joinedAt} 가입', style: const TextStyle(fontSize: 11.5, color: Color(0xFF9AA3B2))),
                  ),
              ],
            ),
          ),
          if (pending)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6FE0), elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(0, 34),
              ),
              onPressed: () => _approve(m),
              child: const Text('승인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _roleTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
    );
  }
}
