import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/community_repo.dart';

/// 친구(팔로워·팔로잉) 초대 화면.
class CommunityInvitePage extends StatefulWidget {
  const CommunityInvitePage({super.key});

  @override
  State<CommunityInvitePage> createState() => _CommunityInvitePageState();
}

class _CommunityInvitePageState extends State<CommunityInvitePage> {
  final CommunityRepo _repo = CommunityRepo();
  final BoardRepo _boardRepo = BoardRepo();

  late final int _communityId;
  List<BoardWeatherListData> _people = [];
  final Set<String> _invited = {};
  final Set<String> _sending = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _communityId = (Get.arguments?['communityId'] as num).toInt();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final myCustId = Get.find<AuthCntr>().resLoginData.value.custId.toString();
    // 팔로워(1) + 팔로잉(2) 합쳐서 custId 기준 중복 제거
    final results = await Future.wait([
      _boardRepo.getFollowList(1, myCustId),
      _boardRepo.getFollowList(2, myCustId),
    ]);
    final Map<String, BoardWeatherListData> byId = {};
    for (final res in results) {
      if (res.code == '00' && res.data != null) {
        for (final e in (res.data as List)) {
          final item = BoardWeatherListData.fromMap(e);
          final id = item.custId?.toString();
          if (id != null && id.isNotEmpty && id != myCustId) byId[id] = item;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _people = byId.values.toList();
      _loading = false;
    });
  }

  Future<void> _invite(BoardWeatherListData p) async {
    final id = p.custId!.toString();
    setState(() => _sending.add(id));
    final (ok, msg) = await _repo.inviteUser(_communityId, id);
    if (!mounted) return;
    setState(() {
      _sending.remove(id);
      if (ok) _invited.add(id);
    });
    Get.snackbar('모임 초대', msg.isEmpty ? (ok ? '초대를 보냈습니다.' : '초대에 실패했습니다.') : msg,
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        forceMaterialTransparency: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('친구 초대', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _people.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  itemCount: _people.length,
                  itemBuilder: (context, i) => _personTile(_people[i]),
                ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 46, color: Color(0xFF9AA3B2)),
            SizedBox(height: 12),
            Text('초대할 친구가 없어요', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 4),
            Text('팔로우한 사람이 여기에 표시됩니다.\n초대 코드나 공유로도 초대할 수 있어요.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Color(0xFF7A8291), height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _personTile(BoardWeatherListData p) {
    final id = p.custId!.toString();
    final nick = p.nickNm ?? p.custNm ?? id;
    final invited = _invited.contains(id);
    final sending = _sending.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFECEEF3))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE6E8EF),
            backgroundImage: (p.profilePath != null && p.profilePath!.isNotEmpty) ? CachedNetworkImageProvider(p.profilePath!) : null,
            child: (p.profilePath == null || p.profilePath!.isEmpty)
                ? Text(nick.characters.first, style: const TextStyle(color: Color(0xFF7A8291), fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(nick, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          if (invited)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Icon(Icons.check_circle, color: Color(0xFF3B6FE0), size: 18),
                SizedBox(width: 4),
                Text('초대됨', style: TextStyle(color: Color(0xFF3B6FE0), fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6FE0), elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(0, 34),
              ),
              onPressed: sending ? null : () => _invite(p),
              child: sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('초대', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
